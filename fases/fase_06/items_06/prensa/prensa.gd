extends Node2D
## Prensa hidráulica presa ao teto. A origem é a face de baixo do teto.
## Ciclo: espera -> aviso (treme e fica vermelha) -> esmaga -> sobe.

@export var altura_curso: float = 96.0
@export var atraso_inicial: float = 0.0
@export var tempo_espera: float = 1.4
@export var tempo_aviso: float = 0.5
@export var tempo_embaixo: float = 0.35
@export var tempo_subida: float = 0.9
## Quanto da haste aparece acima da cabeça parada (curto, para não atravessar o teto).
@export var comprimento_haste: float = 8.0

@onready var cabeca: Node2D = $cabeca
@onready var haste: ColorRect = $haste
@onready var dano: Area2D = $cabeca/dano
@onready var faiscas: CPUParticles2D = $cabeca/faiscas
@onready var poeira: CPUParticles2D = $cabeca/poeira
@onready var alerta: PointLight2D = $alerta
@onready var som_aviso: AudioStreamPlayer2D = $som_aviso
@onready var som_batida: AudioStreamPlayer2D = $som_batida


func _ready() -> void:
	dano.monitoring = false
	dano.area_entered.connect(_on_dano_acertou)
	haste.position.y = -comprimento_haste
	_ciclo()


func _process(_delta: float) -> void:
	# A haste acompanha a cabeça para parecer um pistão contínuo.
	haste.size.y = comprimento_haste + cabeca.position.y + 2.0


func _ciclo() -> void:
	if atraso_inicial > 0.0:
		await get_tree().create_timer(atraso_inicial).timeout

	while is_inside_tree():
		await get_tree().create_timer(tempo_espera).timeout
		await _avisar()
		await _esmagar()
		await get_tree().create_timer(tempo_embaixo).timeout
		await _subir()


func _avisar() -> void:
	som_aviso.play()
	var pisca := create_tween()
	for i in int(tempo_aviso / 0.16):
		pisca.tween_property(alerta, "energy", 1.8, 0.06)
		pisca.tween_property(alerta, "energy", 0.0, 0.1)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(cabeca, "modulate", Color(1.6, 0.55, 0.45), tempo_aviso)

	var tremor := create_tween()
	for i in int(tempo_aviso / 0.05):
		var lado := 1.0 if i % 2 == 0 else -1.0
		tremor.tween_property(cabeca, "position:x", 1.5 * lado, 0.05)
	tremor.tween_property(cabeca, "position:x", 0.0, 0.02)

	await tween.finished


func _esmagar() -> void:
	dano.monitoring = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(cabeca, "position:y", altura_curso, 0.14)
	await tween.finished
	faiscas.restart()
	faiscas.emitting = true
	poeira.restart()
	poeira.emitting = true
	som_batida.play()
	_tremer_camera()


func _subir() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(cabeca, "modulate", Color.WHITE, 0.3)
	tween.tween_property(cabeca, "position:y", 0.0, tempo_subida).set_trans(Tween.TRANS_SINE)
	# O dano só termina quando a cabeça já subiu um pouco, para não parecer injusto.
	tween.tween_callback(func() -> void: dano.monitoring = false).set_delay(tempo_subida * 0.35)
	await tween.finished


func _on_dano_acertou(area: Area2D) -> void:
	# Um golpe causa dano uma única vez (o knockback jogaria o player de volta na zona).
	if area is Hurtbox and area.get_parent().is_in_group("player"):
		dano.set_deferred("monitoring", false)


func _tremer_camera() -> void:
	# Treme a câmera quando a prensa bate perto do jogador (mais forte quanto mais perto).
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	var alcance := 320.0
	var distancia := camera.get_screen_center_position().distance_to(cabeca.global_position)
	if distancia > alcance:
		return

	var forca := lerpf(4.0, 0.8, distancia / alcance)
	var tween := create_tween()
	for i in 6:
		var direcao := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		tween.tween_property(camera, "offset", direcao * forca * (1.0 - i / 6.0), 0.035)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)
