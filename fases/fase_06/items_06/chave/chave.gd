extends Area2D
## Chave de fim de fase. Ao coletar, registra no Progresso e volta ao menu.

@export var numero_fase: int = 6
@export var tempo_ate_menu: float = 1.4

const MENU := "res://comum/cenas/selecao_fases/selecao_fases.tscn"

@onready var sprite: Sprite2D = $sprite
@onready var som: AudioStreamPlayer = $som
@onready var brilho: CPUParticles2D = $brilho

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

	som.play()
	brilho.emitting = true
	_piscar_tela()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position:y", _y_inicial - 28.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0, 0.0), 0.8)

	await get_tree().create_timer(tempo_ate_menu).timeout
	get_tree().change_scene_to_file(MENU)


func _piscar_tela() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 10
	var flash := ColorRect.new()
	flash.color = Color(1, 0.95, 0.75, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(flash)
	get_tree().current_scene.add_child(camada)

	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.75, 0.08)
	tween.tween_property(flash, "color:a", 0.0, 0.7)
	tween.tween_callback(camada.queue_free)
