extends "res://comum/inimigos/skunk/skunk.gd"
## Esqueleto da fábrica. Reaproveita o comportamento do skunk (patrulha, vira na
## parede/borda, leva pisão e morre), mas aguenta 2 pisões e faz barulho de ossos.

@onready var som_dano: AudioStreamPlayer2D = $som_dano
@onready var som_morte: AudioStreamPlayer2D = $som_morte


func die() -> void:
	if not is_dead:
		som_morte.play()
	super()


func _on_damage_received(amount: int, knockback: Vector2) -> void:
	if not is_dead:
		som_dano.play()
	super(amount, knockback)
