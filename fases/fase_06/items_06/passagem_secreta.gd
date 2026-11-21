extends Area2D
## Passagem secreta no começo da fase. A parede da esquerda é falsa: quem encosta nela
## descobre uma sala escondida (com moedas e cura total). Fica atrás da câmera, então
## ninguém vê nada antes de descobrir.

@export var parede_falsa: NodePath
@export var novo_limite_esquerdo: int = -384

var _descoberta: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _descoberta or body.name != "player":
		return
	_descoberta = true

	# A parede "some" e a câmera passa a mostrar o que fica atrás dela.
	var parede := get_node_or_null(parede_falsa) as CanvasItem
	if parede:
		var sumir := create_tween()
		sumir.tween_property(parede, "modulate:a", 0.0, 0.7)

	var camera := get_parent().get_node_or_null("camera") as Camera2D
	if camera:
		var abrir := create_tween()
		abrir.tween_property(camera, "limit_left", novo_limite_esquerdo, 1.0)

	Globals.player_life = Globals.max_life
	Sons.tocar("checkpoint")
