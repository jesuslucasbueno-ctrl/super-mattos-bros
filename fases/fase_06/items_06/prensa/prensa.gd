extends Node2D
## Prensa hidráulica presa ao teto. A origem é a face de baixo do teto.
## Ciclo: espera -> aviso (treme e fica vermelha) -> esmaga -> sobe.

@export var altura_curso: float = 96.0
@export var atraso_inicial: float = 0.0
@export var tempo_espera: float = 1.4
@export var tempo_aviso: float = 0.5
@export var tempo_embaixo: float = 0.35
@export var tempo_subida: float = 0.9

@onready var cabeca: Node2D = $cabeca
@onready var haste: ColorRect = $haste
@onready var dano: Area2D = $cabeca/dano
@onready var faiscas: CPUParticles2D = $cabeca/faiscas


func _ready() -> void:
	dano.monitoring = false
	dano.area_entered.connect(_on_dano_acertou)
	_ciclo()


func _process(_delta: float) -> void:
	# A haste acompanha a cabeça para parecer um pistão contínuo.
	haste.size.y = 200.0 + cabeca.position.y + 2.0


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
