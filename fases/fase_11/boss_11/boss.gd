extends CharacterBody2D

signal defeated

@export var max_health: int = 4
@export var movement_offset := Vector2.ZERO
var health: int
var origin: Vector2
var elapsed := 0.0
var active := false
var finished := false
var immune := 0.0
var volley := 0
@onready var weak: Hurtbox = $hurtbox
@onready var contact: Hitbox = $hitbox
@onready var status: Label = $HUD/Status
var player: Node2D

func _ready() -> void:
	add_to_group("inimigos")
	health = max_health
	origin = position
	$AnimationPlayer.play("idle")
	weak.enabled = false

func _physics_process(delta: float) -> void:
	if finished:
		return
	player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	if not active:
		if player.global_position.distance_to(global_position) > 330:
			return
		active = true
		$Movement.play("arena")
		status.show()
		Globals.cherries = maxi(Globals.cherries, 8)
	elapsed += delta
	immune = maxf(0.0, immune - delta)
	var cycle := fmod(elapsed, 6.0)
	# The editable Movement timeline controls jumps, lateral sweeps and pauses.
	position = origin + movement_offset
	var vulnerable := cycle >= 4.3 and immune <= 0.0
	weak.enabled = vulnerable
	$head.modulate = Color(1.0, 0.6, 0.4) if vulnerable else Color.WHITE
	modulate.a = 0.5 if immune > 0.0 and int(immune * 12.0) % 2 == 0 else 1.0
	var current_volley := int(elapsed / 6.0)
	if cycle >= 3.6 and volley == current_volley:
		volley += 1
		_spit()
		Globals.cherries = maxi(Globals.cherries, 4)
	status.text = "ARICH  %d / %d — %s" % [health, max_health, "Atire na cabeça!" if vulnerable else "Desvie do veneno"]
	if immune <= 0.0 and $AnimationPlayer.current_animation != &"idle":
		$AnimationPlayer.play("idle")

func _spit() -> void:
	for i in range(3 + (max_health - health)):
		var shot = preload("res://fases/fase_11/boss_11/venom.tscn").instantiate()
		shot.position = global_position + Vector2(-48, 22)
		shot.velocity = Vector2(-150.0 + i * 55.0, -160.0)
		get_tree().current_scene.add_child(shot)

func _damage(_amount: int, _knockback: Vector2) -> void:
	if not weak.enabled or immune > 0.0 or finished:
		return
	health -= 1
	immune = 1.5
	weak.enabled = false
	$AnimationPlayer.play("hurt")
	if health <= 0:
		finished = true
		$Movement.pause()
		weak.deactivate()
		contact.deactivate()
		for shot in get_tree().get_nodes_in_group("boss_venom"):
			shot.queue_free()
		status.text = "ARICH DERROTADO!"
		defeated.emit()
		$AnimationPlayer.play("die")
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://comum/cenas/selecao_fases/selecao_fases.tscn")
