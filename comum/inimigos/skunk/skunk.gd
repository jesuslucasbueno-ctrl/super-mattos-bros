extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $anim
@onready var timer: Timer = $timer
@onready var hitbox: Hitbox = $hitbox
@onready var hurtbox: Hurtbox = $hurtbox
@onready var wall_detector: RayCast2D = $wall_detector
@onready var floor_detector: RayCast2D = $floor_detector
@onready var wall_reach: float = absf(wall_detector.target_position.x)
@onready var floor_offset: float = absf(floor_detector.position.x)


@export_category("Enemy Properties")
@export var speed: float = 50.0
@export var turn_time: float = 1.0
@export var max_health: int = 1

var health
var direction: int = -1
var is_dead: bool = false

func _ready() -> void:
	health = max_health
	hurtbox.damage_received.connect(_on_damage_received)
	#hitbox.hit_registered.connect(_on_feet_hitbox_hit)
	timer.wait_time = turn_time
	_atualizar_detectores()

func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity.x = 0
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity += get_gravity()
	
	_atualizar_detectores()
	if wall_detector.is_colliding() or (is_on_floor() and not floor_detector.is_colliding()):
		_inverter_direcao()
		# Give the new direction a full patrol interval before the next timed turn.
		timer.start()

	velocity.x = speed*direction
	
	if direction > 0:
		anim.flip_h = true
	else:
		anim.flip_h = false
	
	move_and_slide()
	
func _atualizar_detectores() -> void:
	wall_detector.target_position.x = wall_reach * direction
	floor_detector.position.x = floor_offset * direction
	# Refresh after moving the rays so these results match the current direction.
	wall_detector.force_raycast_update()
	floor_detector.force_raycast_update()


func _inverter_direcao() -> void:
	direction *= -1
	_atualizar_detectores()


func _on_timer_timeout() -> void:
	if not is_dead:
		_inverter_direcao()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	hitbox.deactivate()
	hurtbox.deactivate()
	timer.stop()
	velocity = Vector2.ZERO
	anim.play("death")
	
func _on_damage_received(amount:int, knockback: Vector2) -> void:
	if is_dead:
		return
		
	health -= amount
	if knockback != Vector2.ZERO:
		velocity = knockback
	
	velocity.y = 0
	
	if health <= 0:
		die()
	else:
		anim.play("hurt")

func _on_anim_animation_finished() -> void:
	if anim.animation == "hurt":
		anim.play("move")
	if anim.animation == "death":
		queue_free()
		
