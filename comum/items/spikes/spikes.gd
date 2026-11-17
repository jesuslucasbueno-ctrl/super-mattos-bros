extends Area2D

@export var damage: int = 1
@export var knockback_force: Vector2 = Vector2(50,-250)

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		# Apenas o player recebe dano dos espinhos
		if not area.get_parent().is_in_group("player"):
			return

		area.take_damage(damage, knockback_force)
		print("Player atingiu os espinhos")
