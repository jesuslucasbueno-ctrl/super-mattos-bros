extends Area2D

@export var fall_acceleration: float = 400.0
@export var bounce_y: float = 330.0
@export var bounce_speed: float = 240.0
var velocity := Vector2.ZERO

func _physics_process(delta: float) -> void:
	velocity.y += fall_acceleration * delta
	position += velocity * delta
	if position.y > bounce_y and velocity.y > 0.0:
		position.y = bounce_y
		velocity.y = -bounce_speed

func _on_hit(_hurt: Hurtbox) -> void:
	queue_free()
