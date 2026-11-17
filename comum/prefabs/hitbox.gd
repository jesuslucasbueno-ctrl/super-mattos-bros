class_name Hitbox
extends Area2D

signal hit_registered(hurtbox: Hurtbox)
var enabled: bool = true
@export var damage: int = 1
@export var knockback_force: float = 200.0
@export var knockback_upward: float = -200.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not enabled:
		return
	if area is Hurtbox:
		if not area.enabled:
			return
		if area.get_parent() == get_parent():
			return
		
		# Se for um projétil, só pode acertar inimigos
		if get_collision_layer_value(7):
			if area.get_parent().is_in_group("player"):
				return
		
		# Impede que inimigos causem dano uns aos outros
		if get_parent().is_in_group("inimigos"):
			if area.get_parent().is_in_group("inimigos"):
				return
		
		var direction: float = sign(area.global_position.x-global_position.x)
		
		if direction == 0:
			direction = 1.0
		
		var final_knockback: Vector2 = Vector2(direction*knockback_force, knockback_upward)
		area.take_damage(damage, final_knockback)
		hit_registered.emit(area)


func deactivate() -> void:
	# Block queued callbacks immediately; physics changes must be deferred.
	enabled = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
