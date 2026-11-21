extends Area2D
## TOKEN LENDÁRIO - item único e raríssimo (só existe na sala secreta).
## Ao coletar dá 15s de supervelocidade, superpulo e proteção (veja Poderes).

@export var duracao_poder: float = 15.0

var _coletado: bool = false
var _tempo: float = 0.0
var _y_inicial: float = 0.0

@onready var sprite: AnimatedSprite2D = $sprite
@onready var halo: Sprite2D = $halo
@onready var luz: PointLight2D = $luz
@onready var brilhos: CPUParticles2D = $brilhos
@onready var explosao: CPUParticles2D = $explosao


func _ready() -> void:
	# Só existe uma vez por tentativa: se já foi coletado, não aparece de novo.
	if Poderes.token_coletado:
		queue_free()
		return
	_y_inicial = sprite.position.y
	body_entered.connect(_on_body_entered)
	sprite.play("brilhar")


func _process(delta: float) -> void:
	if _coletado:
		return
	_tempo += delta
	var flutuar := sin(_tempo * 2.2) * 3.5          # sobe e desce suavemente
	sprite.position.y = _y_inicial + flutuar
	halo.position.y = sprite.position.y
	halo.scale = Vector2.ONE * (0.95 + 0.12 * sin(_tempo * 3.0))
	halo.modulate.a = 0.75 + 0.25 * sin(_tempo * 3.0 + 1.0)
	luz.energy = 1.2 + sin(_tempo * 3.4) * 0.4


func _on_body_entered(body: Node2D) -> void:
	if _coletado or body.name != "player":
		return
	if not Poderes.ativar(duracao_poder):   # nunca acumula poderes
		return

	_coletado = true
	Poderes.token_coletado = true
	set_deferred("monitoring", false)
	brilhos.emitting = false
	explosao.restart()
	explosao.emitting = true

	# Animação especial de coleta: o token sobe girando, cresce e some numa explosão de luz.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position:y", _y_inicial - 36.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2(2.2, 2.2), 0.7).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(sprite, "rotation", TAU, 0.7)
	tween.tween_property(sprite, "modulate", Color(2.5, 2.2, 3.0, 0.0), 0.8).set_delay(0.1)
	tween.tween_property(halo, "scale", Vector2(3.2, 3.2), 0.8)
	tween.tween_property(halo, "modulate:a", 0.0, 0.8)
	tween.tween_property(luz, "energy", 0.0, 0.9)
	await get_tree().create_timer(1.4).timeout
	queue_free()
