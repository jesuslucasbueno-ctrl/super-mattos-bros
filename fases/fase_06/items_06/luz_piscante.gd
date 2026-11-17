
@tool
extends PointLight2D

@export_group("Cintilação")
@export var energia_minima: float = 0.3
@export var energia_maxima: float = 1.2
@export var velocidade: float = 3.0
@export_range(0.0, 1.0) var suavidade: float = 0.7

@export_group("Editor")
@export var preview_no_editor: bool = true

var tempo: float = 0.0
var ruido: FastNoiseLite
var energia_atual: float = 0.0


func inicializar_ruido() -> void:
	if ruido != null:
		return

	ruido = FastNoiseLite.new()
	ruido.seed = randi()
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ruido.frequency = 0.5

	tempo = randf_range(0.0, 1000.0)
	energia_atual = energy


func _ready() -> void:
	inicializar_ruido()
	set_process(true)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not preview_no_editor:
		return

	# Garante a inicialização no editor.
	inicializar_ruido()

	tempo += delta * velocidade

	var valor_ruido := ruido.get_noise_1d(tempo)

	var brilho := clampf(
		(valor_ruido + 1.0) / 2.0,
		0.0,
		1.0
	)

	var energia_alvo := lerpf(
		energia_minima,
		energia_maxima,
		brilho
	)

	var fator := 1.0 - exp(
		-delta * 10.0 * suavidade
	)

	energia_atual = lerpf(
		energia_atual,
		energia_alvo,
		fator
	)

	energy = energia_atual
