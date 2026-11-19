extends CharacterBody2D
## Esqueleto da fábrica. Patrulha, percebe o jogador (reação), persegue e ataca com a lança.
## Os sprites olham para a DIREITA (direction = 1).

enum Estado { PATRULHA, ALERTA, PERSEGUIR, ATACAR, RECUPERAR, DANO, MORTO }

@export_category("Esqueleto")
@export var speed: float = 42.0
@export var multiplicador_perseguicao: float = 1.5
@export var alcance_visao: float = 150.0
@export var alcance_ataque: float = 40.0
@export var cooldown_ataque: float = 1.6
@export var turn_time: float = 3.5
@export var max_health: int = 2
@export var dano_ataque: int = 2

const FRAME_INICIO_GOLPE := 8
const FRAME_FIM_GOLPE := 13

var health: int
var direction: int = 1
var estado: Estado = Estado.PATRULHA
var is_dead: bool = false
var _jogador: Node2D
var _espera_ataque: float = 0.0

@onready var anim: AnimatedSprite2D = $anim
@onready var timer: Timer = $timer
@onready var hitbox: Hitbox = $hitbox
@onready var ataque: Hitbox = $ataque
@onready var hurtbox: Hurtbox = $hurtbox
@onready var wall_detector: RayCast2D = $wall_detector
@onready var floor_detector: RayCast2D = $floor_detector
@onready var som_dano: AudioStreamPlayer2D = $som_dano
@onready var som_morte: AudioStreamPlayer2D = $som_morte
@onready var som_ataque: AudioStreamPlayer2D = $som_ataque
@onready var wall_reach: float = absf(wall_detector.target_position.x)
@onready var floor_offset: float = absf(floor_detector.position.x)


func _ready() -> void:
	health = max_health
	direction = 1 if randf() < 0.5 else -1
	hurtbox.damage_received.connect(_on_damage_received)
	anim.animation_finished.connect(_on_anim_animation_finished)
	anim.frame_changed.connect(_on_frame_changed)
	timer.wait_time = turn_time
	ataque.enabled = true
	ataque.monitoring = false
	_atualizar_detectores()
	_tocar("move")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_jogador):
		_jogador = get_tree().get_first_node_in_group("player")

	if not is_on_floor():
		velocity += get_gravity() * delta
	_espera_ataque = maxf(_espera_ataque - delta, 0.0)

	match estado:
		Estado.PATRULHA:
			_patrulhar()
		Estado.ALERTA, Estado.ATACAR, Estado.DANO:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		Estado.PERSEGUIR:
			_perseguir()
		Estado.RECUPERAR:
			velocity.x = 0.0
			if _espera_ataque <= 0.0:
				_depois_de_atacar()
		Estado.MORTO:
			velocity.x = 0.0

	anim.flip_h = direction < 0
	move_and_slide()


# ---------------------------------------------------------------- comportamentos
func _patrulhar() -> void:
	_atualizar_detectores()
	if _borda_ou_parede():
		_inverter_direcao()
		timer.start()
	velocity.x = speed * direction
	_tocar("move")

	if _ve_jogador(alcance_visao):
		_mudar_para_alerta()


func _perseguir() -> void:
	if not _ve_jogador(alcance_visao * 1.4, 70.0):
		estado = Estado.PATRULHA
		timer.start()
		return

	var dx := _jogador.global_position.x - global_position.x
	direction = 1 if dx >= 0.0 else -1
	_atualizar_detectores()

	if absf(dx) <= alcance_ataque and absf(_jogador.global_position.y - global_position.y) <= 34.0 and _espera_ataque <= 0.0:
		_atacar()
		return

	if _borda_ou_parede() or absf(dx) <= alcance_ataque * 0.7:
		velocity.x = 0.0
		_tocar("idle")
	else:
		velocity.x = speed * multiplicador_perseguicao * direction
		_tocar("move")


func _mudar_para_alerta() -> void:
	estado = Estado.ALERTA
	_virar_para_jogador()
	timer.stop()
	anim.play("react")


func _atacar() -> void:
	estado = Estado.ATACAR
	_virar_para_jogador()
	velocity.x = 0.0
	som_ataque.play()
	anim.play("attack")


func _depois_de_atacar() -> void:
	estado = Estado.PERSEGUIR if _ve_jogador(alcance_visao * 1.4, 70.0) else Estado.PATRULHA
	if estado == Estado.PATRULHA:
		timer.start()


# ---------------------------------------------------------------- utilidades
func _ve_jogador(alcance: float, altura: float = 40.0) -> bool:
	if not is_instance_valid(_jogador):
		return false
	var d := _jogador.global_position - global_position
	return absf(d.x) <= alcance and absf(d.y) <= altura


func _virar_para_jogador() -> void:
	if is_instance_valid(_jogador):
		direction = 1 if _jogador.global_position.x >= global_position.x else -1
	_atualizar_detectores()


func _borda_ou_parede() -> bool:
	return wall_detector.is_colliding() or (is_on_floor() and not floor_detector.is_colliding())


func _tocar(nome: String) -> void:
	if anim.animation != nome or not anim.is_playing():
		anim.play(nome)


func _atualizar_detectores() -> void:
	wall_detector.target_position.x = wall_reach * direction
	floor_detector.position.x = floor_offset * direction
	ataque.get_node("CollisionShape2D").position.x = 22.0 * direction
	wall_detector.force_raycast_update()
	floor_detector.force_raycast_update()


func _inverter_direcao() -> void:
	direction *= -1
	_atualizar_detectores()


func _on_timer_timeout() -> void:
	if estado == Estado.PATRULHA:
		_inverter_direcao()


# ---------------------------------------------------------------- animação
func _on_frame_changed() -> void:
	# A lança só machuca nos quadros em que a estocada está estendida.
	var golpeando := anim.animation == &"attack" and anim.frame >= FRAME_INICIO_GOLPE and anim.frame <= FRAME_FIM_GOLPE
	ataque.damage = dano_ataque
	ataque.set_deferred("monitoring", golpeando and not is_dead)


func _on_anim_animation_finished() -> void:
	match anim.animation:
		&"react":
			estado = Estado.PERSEGUIR
		&"attack":
			ataque.set_deferred("monitoring", false)
			estado = Estado.RECUPERAR
			_espera_ataque = cooldown_ataque
			anim.play("idle")
		&"hurt":
			estado = Estado.PERSEGUIR
		&"death":
			queue_free()


# ---------------------------------------------------------------- dano e morte
func die() -> void:
	if is_dead:
		return
	is_dead = true
	estado = Estado.MORTO
	som_morte.play()
	hitbox.deactivate()
	ataque.deactivate()
	hurtbox.deactivate()
	timer.stop()
	velocity = Vector2.ZERO
	anim.play("death")


func _on_damage_received(amount: int, knockback: Vector2) -> void:
	if is_dead:
		return

	health -= amount
	if knockback != Vector2.ZERO:
		velocity.x = knockback.x * 0.5
	velocity.y = 0.0

	if health <= 0:
		die()
	else:
		som_dano.play()
		estado = Estado.DANO
		ataque.set_deferred("monitoring", false)
		anim.play("hurt")
