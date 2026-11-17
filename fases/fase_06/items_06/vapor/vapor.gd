extends Node2D
## Cano de vapor. O jato sai para cima (gire o nó para mudar a direção).
## Ciclo: desligado -> aviso (chiado fraco) -> jato (causa dano).

@export var atraso_inicial: float = 0.0
@export var tempo_desligado: float = 1.8
@export var tempo_aviso: float = 0.6
@export var tempo_ligado: float = 1.2
@export var comprimento: float = 48.0

@onready var dano: Area2D = $dano
@onready var colisao: CollisionShape2D = $dano/colisao
@onready var jato: CPUParticles2D = $jato
@onready var chiado: CPUParticles2D = $chiado


func _ready() -> void:
	var forma := RectangleShape2D.new()
	forma.size = Vector2(12.0, comprimento)
	colisao.shape = forma
	colisao.position = Vector2(0.0, -comprimento / 2.0 - 2.0)

	jato.lifetime = 0.45
	jato.initial_velocity_min = comprimento * 1.8
	jato.initial_velocity_max = comprimento * 2.2

	dano.monitoring = false
	dano.area_entered.connect(_on_dano_acertou)
	jato.emitting = false
	chiado.emitting = false
	_ciclo()


func _ciclo() -> void:
	if atraso_inicial > 0.0:
		await get_tree().create_timer(atraso_inicial).timeout

	while is_inside_tree():
		await get_tree().create_timer(tempo_desligado).timeout

		chiado.emitting = true
		await get_tree().create_timer(tempo_aviso).timeout

		chiado.emitting = false
		jato.emitting = true
		dano.monitoring = true
		await get_tree().create_timer(tempo_ligado).timeout

		jato.emitting = false
		dano.monitoring = false


func _on_dano_acertou(area: Area2D) -> void:
	# Um jato causa dano uma única vez por ciclo.
	if area is Hurtbox and area.get_parent().is_in_group("player"):
		dano.set_deferred("monitoring", false)
