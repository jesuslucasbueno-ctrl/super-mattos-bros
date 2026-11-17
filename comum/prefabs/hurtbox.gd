class_name Hurtbox
extends Area2D

signal damage_received(amount: int, knockback: Vector2)
var enabled: bool = true

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if enabled:
		damage_received.emit(amount, knockback)


func deactivate() -> void:
	enabled = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
