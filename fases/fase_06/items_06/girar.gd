extends Sprite2D
## Gira o sprite continuamente (engrenagens, ventiladores).

@export var velocidade_graus: float = 20.0


func _process(delta: float) -> void:
	rotation_degrees += velocidade_graus * delta
