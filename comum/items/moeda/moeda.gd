extends Area2D
## Moeda. Ao pegar, soma 1 no contador de gemas da HUD.

var _coletada: bool = false

@onready var sprite: AnimatedSprite2D = $sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Cada moeda começa num quadro diferente para não girarem todas sincronizadas.
	sprite.frame = randi() % 9
	sprite.play("girar")


func _on_body_entered(body: Node2D) -> void:
	if _coletada or body.name != "player":
		return

	_coletada = true
	Globals.gems += 1
	Sons.tocar("gema", -3.0, randf_range(0.95, 1.2))

	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "position:y", sprite.position.y - 14.0, 0.25)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
