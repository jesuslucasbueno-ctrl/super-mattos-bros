extends AnimatableBody2D

@onready var sprite: Sprite2D = $sprite
@onready var player_detector: Area2D = $player_detector
@onready var anim: AnimationPlayer = $anim
@onready var respawn_timer: Timer = $respawn_timer

@export var respawn_time: float = 2.0
@export var fall_speed: float = 600.0

var respawn_position: Vector2
var is_triggered: bool = false
var max_fall_distance: float = 1000.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_detector.body_entered.connect(_on_body_entered)
	anim.animation_finished.connect(_on_animation_finished)
	respawn_timer.timeout.connect(_on_timer_timeout)
	
	respawn_position = global_position
	respawn_timer.wait_time = respawn_time
	set_physics_process(false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var movement = Vector2.DOWN * fall_speed * delta
	move_and_collide(movement)
	
	if global_position.y > respawn_position.y + max_fall_distance:
		set_physics_process(false)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player" and not is_triggered:
		if body.velocity.y >=0:
			anim.play("shake")
	

func _on_animation_finished(_anim_name: String) -> void:
	is_triggered = true
	set_physics_process(true)
	respawn_timer.start()
	
func _on_timer_timeout() -> void:
	is_triggered = false
	set_physics_process(false)	
	global_position = respawn_position
	
	var tween: Tween = create_tween()

	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_BOUNCE)

	tween.tween_property(sprite, "scale", Vector2(1.3, 0.8), 0.1).from(Vector2.ZERO)

	tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)
