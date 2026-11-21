extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const WALL_SLIDE_SPEED = 60.0
const WALL_JUMP_SPEED = 100.0
const WALL_JUMP_DURATION = 0.18

## Multiplicadores controlados pelos poderes (Token Lendário). 1.0 = normal.
var speed_mult: float = 1.0
var jump_mult: float = 1.0

var wall_jump_time: float = 0.0
var wall_sliding: bool = false

@onready var anim: AnimationPlayer = $anim
@onready var sprite: Sprite2D = $sprite
@onready var hurtbox: Hurtbox = $hurtbox
@onready var ponto_tiro: Marker2D = $ponto_tiro
@onready var knockback_timer: Timer = $knockback_timer
@onready var ray_left: RayCast2D = $ray_left
@onready var ray_right: RayCast2D = $ray_right


var projetil_scene = preload("res://comum/player/projetil.tscn")

var knockback_vector = Vector2.ZERO

@export var hurt_duration: float = 0.3

func _ready() -> void:
	hurtbox.damage_received.connect(_on_damage_received)
	$RemoteTransform2D.remote_path = NodePath("../../camera")
	
	
func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	var taking_damage := not knockback_timer.is_stopped()
	wall_jump_time = maxf(wall_jump_time - delta, 0.0)

	# Direção do impulso para longe da parede.
	var wall_direction := 0
	if ray_left.is_colliding():
		wall_direction = 1
	elif ray_right.is_colliding():
		wall_direction = -1

	if not is_on_floor():
		velocity += get_gravity() * delta

	# Preserva o impulso horizontal durante o wall jump.
	if wall_jump_time <= 0.0:
		if direction:
			velocity.x = direction * SPEED * speed_mult
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * speed_mult)

	wall_sliding = (
		wall_direction != 0
		and not is_on_floor()
		and velocity.y > 0.0
		and wall_jump_time <= 0.0
		and not taking_damage
	)
	if wall_sliding:
		velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)

	if Input.is_action_just_pressed("ui_accept") and not taking_damage:
		if is_on_floor():
			velocity.y = JUMP_VELOCITY * jump_mult
			Sons.tocar("pulo")
		elif wall_direction != 0 and wall_jump_time <= 0.0:
			velocity.y = JUMP_VELOCITY * jump_mult
			velocity.x = wall_direction * WALL_JUMP_SPEED
			wall_jump_time = WALL_JUMP_DURATION
			wall_sliding = false
			Sons.tocar("pulo", -2.0, 1.25)

	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y = velocity.y/5
	if Input.is_action_just_pressed("atirar"):
		if Globals.cherries > 0:
			atirar()
			Globals.cherries -=1


	if taking_damage:
		velocity = knockback_vector
		wall_jump_time = 0.0
		wall_sliding = false
	var estava_no_ar := not is_on_floor()
	var velocidade_queda := velocity.y
	move_and_slide()
	if estava_no_ar and is_on_floor() and velocidade_queda > 140.0:
		Sons.tocar("aterrissar", -4.0)
	if is_on_floor():
		wall_sliding = false
	update_state(direction)

func update_state(direction) -> void:
	var state = 'idle'
	if direction:
		state = "run"
	if !is_on_floor():
		if velocity.y < 0:
			state = "jump"
		else:
			state = "fall"
	if wall_sliding:
		state = "wall_grab"
	if not knockback_timer.is_stopped():
		state = "hurt"
			
	if wall_sliding:
		sprite.flip_h = ray_left.is_colliding()
	elif wall_jump_time > 0.0:
		sprite.flip_h = velocity.x < 0.0
	elif direction != 0:
		sprite.flip_h = direction < 0.0
		
	if anim.assigned_animation != state:
		anim.play(state)
		anim.advance(0)
	
func atirar() -> void:
	Sons.tocar("tiro")
	var projetil = projetil_scene.instantiate()

	if sprite.flip_h:
		projetil.direcao = -1
		ponto_tiro.position.x = -10
	else:
		projetil.direcao = 1
		ponto_tiro.position.x = 10

	projetil.global_position = ponto_tiro.global_position
	get_tree().current_scene.add_child(projetil)
	
func _on_damage_received(amount:int, knockback: Vector2) -> void:
	Sons.tocar("dano_jogador")
	knockback_vector = knockback
	if knockback != Vector2.ZERO and hurt_duration > 0.0:
		knockback_timer.start(hurt_duration)
	else:
		knockback_timer.stop()
		_on_knockback_timer_timeout()
	if Globals.player_life <=1:
		Checkpoint.reaparecer(get_tree())
	else:
		Globals.player_life -= amount
	if knockback != Vector2.ZERO:
		velocity = knockback
	
func _on_knockback_timer_timeout() -> void:
	knockback_vector = Vector2.ZERO


func _on_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"die":
		Checkpoint.reaparecer(get_tree())
		

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	var camera = get_viewport().get_camera_2d()

	if camera == null:
		return

	var limite_inferior = camera.get_screen_center_position().y + get_viewport_rect().size.y / (2.0 * camera.zoom.y)

	if global_position.y > limite_inferior:
		Checkpoint.reaparecer(get_tree())
