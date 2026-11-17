@tool
extends Area2D

@export_range(1.0, 2000.0, 1.0, "or_greater", "suffix:px") var raio_proximidade: float = 100.0:
	set(valor):
		raio_proximidade = maxf(valor, 1.0)
		if is_node_ready():
			_aplicar_raio_proximidade.call_deferred()

@onready var anim: AnimatedSprite2D = $anim
@onready var contorno_neon: AnimatedSprite2D = $anim/ContornoNeon
@onready var collision: CollisionShape2D = $collision
@onready var proximidade: Area2D = $Proximidade

var coletada := false


func _ready() -> void:
	_aplicar_raio_proximidade()
	_atualizar_frame_shader()


func _aplicar_raio_proximidade() -> void:
	# Each cherry owns its shape, so changing one radius cannot affect another.
	var forma := CircleShape2D.new()
	forma.radius = raio_proximidade
	$Proximidade/CollisionShape2D.shape = forma


func _atualizar_frame_shader() -> void:
	if not is_node_ready():
		return
	contorno_neon.animation = anim.animation
	contorno_neon.frame = anim.frame
	var textura := anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	var limites := Vector4(0.0, 0.0, 1.0, 1.0)
	if textura is AtlasTexture:
		var atlas := textura as AtlasTexture
		var tamanho := atlas.atlas.get_size()
		limites = Vector4(
			atlas.region.position.x / tamanho.x,
			atlas.region.position.y / tamanho.y,
			atlas.region.size.x / tamanho.x,
			atlas.region.size.y / tamanho.y
		)
	contorno_neon.material.set_shader_parameter("frame_uv", limites)


func _on_proximidade_body_changed(body: Node2D) -> void:
	if Engine.is_editor_hint() or not body.is_in_group("player") or coletada:
		return
	# Query after the physics overlap list has been updated for either signal.
	_atualizar_proximidade.call_deferred()


func _atualizar_proximidade() -> void:
	if Engine.is_editor_hint():
		return
	var ativo := false
	if not coletada:
		for body in proximidade.get_overlapping_bodies():
			if body.is_in_group("player"):
				ativo = true
				break
	contorno_neon.material.set_shader_parameter("ativo", ativo)


func _on_body_entered(_body: Node2D) -> void:
	if Engine.is_editor_hint() or coletada:
		return
	coletada = true
	contorno_neon.material.set_shader_parameter("ativo", false)
	Globals.cherries += 1
	collision.set_deferred("disabled", true)
	anim.play("collect")


func _on_anim_animation_finished() -> void:
	if not Engine.is_editor_hint():
		queue_free()
