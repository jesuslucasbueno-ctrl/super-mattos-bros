extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $anim
@onready var hitbox: Hitbox = $hitbox
@onready var hitbox_collision: CollisionShape2D = $hitbox/hitbox_collision
@onready var hurtbox: Hurtbox = $hurtbox
@onready var hurtbox_collision: CollisionShape2D = $hurtbox/hurtbox_collision
@onready var detection_area: Area2D = $detection_area 

@export_group("Enemy Properties")
@export var speed: float = 120.0
@export var dive_speed: float = 350.0
@export var patrol_distance: float = 150.0
@export var max_health: int = 1
@export var attack_cooldown: float = 3.0
@export var knockback_force: float = 200.0

var state = 'patrol'

var health: int
var direction: int = -1
var can_attack: bool = true

var start_position: Vector2
var target_position: Vector2

func _ready() -> void:
	health = max_health
	start_position = global_position
	
	hurtbox.damage_received.connect(_on_damage_received)
	detection_area.body_entered.connect(_on_detection_area_body_entered)

func _physics_process(_delta: float) -> void:
	match state:
		'patrol':
			_handle_patrol()
		'dive':
			_handle_dive()
		'return':
			_handle_return()
		_:
			velocity = Vector2.ZERO
	
	if velocity.x > 0:
		anim.flip_h = true
	else:
		anim.flip_h = false
		
	move_and_slide()

func change_state(new_state: String) -> void:
	state = new_state
	
	match state:
		'patrol':
			anim.play("move")
		'dive':
			anim.play("attack")
		'return':
			anim.play("move")
		'hurt':
			velocity = Vector2.ZERO
			anim.play("hurt")
			await get_tree().create_timer(0.5).timeout
			if state == 'hurt':
				change_state('patrol')
		'die':
			hitbox.deactivate()
			hurtbox.deactivate()
			velocity = Vector2.ZERO
			anim.play("death")
			
		_:
			velocity = Vector2.ZERO
	
	
func _handle_patrol() -> void:
	velocity.y = 0
	velocity.x = speed*direction
	
	var current_distance = global_position.x - start_position.x
	if abs(current_distance) >= patrol_distance:
		direction = -1 if current_distance > 0 else 1

func _handle_dive() -> void:
	var direction_to_target = (target_position - global_position).normalized()
	velocity = direction_to_target*dive_speed
	
	if global_position.distance_to(target_position) < 10.0:
		apply_impact_bounce(target_position)
		change_state('return')

func _handle_return() -> void:
	var return_point = Vector2(global_position.x,start_position.y)
	var direction_to_return = (return_point-global_position).normalized()
	velocity = direction_to_return*speed
	
	if global_position.distance_to(return_point) < 10:
		change_state('patrol')
		_start_cooldown()

func _start_cooldown() -> void:
	can_attack = false
	await  get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_damage_received(amount: int, knockback:Vector2) -> void:
	if state == 'die':
		return
	
	health -= amount
	if knockback != Vector2.ZERO:
		velocity = knockback
	
	change_state('hurt')
	if health <= 0:
		die()
	
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.name == 'player' and state == 'patrol' and can_attack:
		target_position = body.global_position
		change_state('dive')
		
func die() -> void:
	if state == 'die':
		return
	change_state('die')
	await  get_tree().create_timer(0.5).timeout
	queue_free()

func apply_impact_bounce(impact_source_position: Vector2 = Vector2.ZERO) -> void:
	if impact_source_position != Vector2.ZERO:
		var knockback_direction = (global_position - impact_source_position).normalized()
		velocity = knockback_direction * knockback_force
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(anim,'scale',Vector2(1.4,0.7),0.05)
	tween.tween_property(anim,'scale',Vector2.ONE,0.15)
