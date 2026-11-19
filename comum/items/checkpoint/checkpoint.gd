extends Area2D
## Checkpoint (bandeira). A origem fica no chão. Ao tocar, salva o ponto de reaparecimento.

@export var indice: int = 0

var _ativo: bool = false

@onready var bandeira: Polygon2D = $bandeira
@onready var lampada: Polygon2D = $lampada
@onready var luz: PointLight2D = $luz
@onready var brilho: CPUParticles2D = $brilho


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Se o jogador já passou por este (ou por um mais à frente), ele nasce aceso.
	if Checkpoint.vale_para(get_tree().current_scene) and indice <= Checkpoint.indice:
		_ativar(false)


func _on_body_entered(body: Node2D) -> void:
	if _ativo or body.name != "player":
		return
	if Checkpoint.vale_para(get_tree().current_scene) and indice < Checkpoint.indice:
		return

	# Cura um pouco na primeira vez que acende.
	Globals.player_life = mini(Globals.player_life + 4, Globals.max_life)
	Checkpoint.registrar(get_tree().current_scene, global_position + Vector2(0, -3), indice)
	_ativar(true)


func _ativar(com_efeitos: bool) -> void:
	_ativo = true
	bandeira.color = Color(0.35, 0.9, 0.4)
	lampada.color = Color(0.6, 1.0, 0.6)
	luz.color = Color(0.5, 1.0, 0.55)
	if com_efeitos:
		var tween := create_tween()
		tween.tween_property(luz, "energy", 1.4, 0.15)
		tween.tween_property(luz, "energy", 0.8, 0.5)
		brilho.restart()
		brilho.emitting = true
		Sons.tocar("checkpoint")
	else:
		luz.energy = 0.8
