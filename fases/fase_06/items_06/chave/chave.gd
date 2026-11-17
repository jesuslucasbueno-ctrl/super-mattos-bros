extends Area2D
## Chave de fim de fase. Ao coletar, registra no Progresso e volta ao menu.

@export var numero_fase: int = 6
@export var tempo_ate_menu: float = 1.4

const MENU := "res://comum/cenas/selecao_fases/selecao_fases.tscn"

@onready var sprite: Sprite2D = $sprite

var _coletada: bool = false
var _tempo: float = 0.0
var _y_inicial: float = 0.0


func _ready() -> void:
	_y_inicial = sprite.position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _coletada:
		return
	_tempo += delta
	sprite.position.y = _y_inicial + sin(_tempo * 3.0) * 2.5


func _on_body_entered(body: Node2D) -> void:
	if _coletada or body.name != "player":
		return

	_coletada = true
	Progresso.coletar_chave(numero_fase)
	Progresso.concluir_fase(numero_fase)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position:y", _y_inicial - 28.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0, 0.0), 0.8)

	await get_tree().create_timer(tempo_ate_menu).timeout
	get_tree().change_scene_to_file(MENU)
