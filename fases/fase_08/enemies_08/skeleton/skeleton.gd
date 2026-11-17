extends CharacterBody2D

@onready var timer: Timer = $timer
@onready var animation: AnimatedSprite2D = $animation

@export_group("Enemy Properties")
@export var speed : float = 100.0
@export var health : int = 1
@export var turn_time : float = 1.0

var direction : int = -1

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer.wait_time = turn_time

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	velocity.x = speed * direction

	if direction > 0: 
		animation.flip_h = true 
	else:
		animation.flip_h = false 

	move_and_slide()

func _on_timer_timeout():
	direction *= -1
