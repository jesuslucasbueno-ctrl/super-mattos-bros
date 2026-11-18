extends CPUParticles2D
## Lâmpada com defeito: solta faíscas de tempos em tempos (com som).

@export var intervalo_min: float = 2.0
@export var intervalo_max: float = 6.0

var _som: AudioStreamPlayer2D


func _ready() -> void:
	emitting = false
	one_shot = true
	amount = 8
	lifetime = 0.45
	explosiveness = 1.0
	direction = Vector2(0, 1)
	spread = 60.0
	gravity = Vector2(0, 220)
	initial_velocity_min = 25.0
	initial_velocity_max = 70.0
	scale_amount_min = 1.5
	scale_amount_max = 2.2
	color = Color(1.0, 0.85, 0.45)

	_som = AudioStreamPlayer2D.new()
	_som.stream = load("res://fases/fase_06/sfx_06/faisca.ogg")
	_som.volume_db = -8.0
	_som.max_distance = 240.0
	add_child(_som)
	_ciclo()


func _ciclo() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(intervalo_min, intervalo_max)).timeout
		restart()
		emitting = true
		_som.play()
