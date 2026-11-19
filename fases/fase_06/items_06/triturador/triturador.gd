extends Node2D
## TRITURADOR - boss que "come o mapa" quando o jogador fica parado.
##
## 1) Se o jogador ficar parado (dentro de um raio pequeno) por `tempo_parado_para_surgir`,
##    toca o alarme e a tela avisa "SE MEXA!". Se ele se mexer nesse aviso, nada acontece.
## 2) Se continuar parado, o Triturador surge atrás da câmera e avança comendo o terreno
##    (tiles), objetos e inimigos que estiverem na frente. Encostar nele causa muito dano.
## 3) Se o jogador fugir (ficar bem à frente), o Triturador recua e some. O ciclo recomeça.

@export var tempo_parado_para_surgir: float = 5.0
@export var tempo_aviso: float = 2.2
@export var velocidade: float = 78.0
@export var distancia_spawn: float = 340.0
@export var distancia_desistir: float = 640.0
@export var raio_parado: float = 28.0
@export var altura_boca: float = 280.0
@export var carencia_inicial: float = 3.0   # segundos extras no começo da fase

enum Estado { OCULTO, AVISO, ATACANDO, RECUANDO }

var estado: Estado = Estado.OCULTO
var _jogador: Node2D
var _terreno: TileMapLayer
var _ref_pos: Vector2
var _tempo_parado: float = 0.0
var _tempo_comer: float = 0.0
var _camada_aviso: CanvasLayer
var _rotulo: Label
var _flash: ColorRect

@onready var hitbox: Hitbox = $hitbox
@onready var rugido: AudioStreamPlayer2D = $rugido
@onready var alarme: AudioStreamPlayer = $alarme
@onready var mastigar: AudioStreamPlayer2D = $mastigar
@onready var poeira: CPUParticles2D = $poeira
@onready var faiscas: CPUParticles2D = $faiscas


func _ready() -> void:
	visible = false
	hitbox.enabled = false
	hitbox.monitoring = false
	_tempo_parado = -carencia_inicial
	rugido.finished.connect(rugido.play)
	_criar_aviso()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_jogador):
		_jogador = get_tree().get_first_node_in_group("player")
		_terreno = get_parent().get_node_or_null("ground")
		if _jogador:
			_ref_pos = _jogador.global_position
		return

	match estado:
		Estado.OCULTO:
			_contar_parado(delta)
		Estado.ATACANDO:
			_avancar(delta)
		Estado.RECUANDO:
			global_position.x -= velocidade * 2.5 * delta


# ---------------------------------------------------------------- detecção
func _jogador_parado() -> bool:
	return _jogador.global_position.distance_to(_ref_pos) <= raio_parado


func _contar_parado(delta: float) -> void:
	if not _jogador_parado():
		_ref_pos = _jogador.global_position
		_tempo_parado = minf(_tempo_parado, 0.0)
		return

	_tempo_parado += delta
	if _tempo_parado >= tempo_parado_para_surgir:
		_avisar()


# ---------------------------------------------------------------- aviso
func _avisar() -> void:
	estado = Estado.AVISO
	_ref_pos = _jogador.global_position
	alarme.play()
	_camada_aviso.visible = true

	var decorrido := 0.0
	while decorrido < tempo_aviso and is_inside_tree():
		await get_tree().process_frame
		var dt := get_process_delta_time()
		decorrido += dt

		var intensidade := decorrido / tempo_aviso
		_flash.color.a = (0.12 + 0.2 * intensidade) * (0.5 + 0.5 * sin(decorrido * 14.0))
		_rotulo.modulate.a = 0.55 + 0.45 * sin(decorrido * 16.0)
		_tremer_camera(0.5 + 2.0 * intensidade)

		if not is_instance_valid(_jogador) or not _jogador_parado():
			_cancelar_aviso()    # o jogador se mexeu a tempo
			return

	_camada_aviso.visible = false
	_surgir()


func _cancelar_aviso() -> void:
	alarme.stop()
	_camada_aviso.visible = false
	_zerar_camera()
	estado = Estado.OCULTO
	_tempo_parado = -1.0


# ---------------------------------------------------------------- ataque
func _surgir() -> void:
	global_position = Vector2(_jogador.global_position.x - distancia_spawn, _jogador.global_position.y - 20.0)
	modulate = Color(1.35, 1.3, 1.3, 1.0)
	visible = true
	hitbox.enabled = true
	hitbox.monitoring = true
	rugido.play()
	estado = Estado.ATACANDO


func _avancar(delta: float) -> void:
	# O golpe nunca tira mais vida do que o jogador tem (a HUD não aceita vida negativa).
	hitbox.damage = clampi(Globals.player_life, 1, 4)
	global_position.x += velocidade * delta
	global_position.y = lerpf(global_position.y, _jogador.global_position.y - 20.0, 1.6 * delta)

	_tempo_comer -= delta
	_comer(_tempo_comer <= 0.0)
	if _tempo_comer <= 0.0:
		_tempo_comer = 0.18

	var camada := get_viewport().get_camera_2d()
	if camada and camada.get_screen_center_position().distance_to(global_position) < 500.0:
		_tremer_camera(1.1)

	var adiante := _jogador.global_position.x - global_position.x
	if adiante > distancia_desistir or adiante < -160.0:
		_recuar()


func _recuar() -> void:
	estado = Estado.RECUANDO
	hitbox.enabled = false
	hitbox.set_deferred("monitoring", false)
	_zerar_camera()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.9)
	await tween.finished

	visible = false
	rugido.stop()
	estado = Estado.OCULTO
	_ref_pos = _jogador.global_position if is_instance_valid(_jogador) else _ref_pos
	_tempo_parado = -2.0


# ---------------------------------------------------------------- comer o mapa
func _comer(tocar_som: bool) -> void:
	var boca := Rect2(global_position.x - 60.0, global_position.y - altura_boca / 2.0, 150.0, altura_boca)
	var comeu := false

	if _terreno:
		var celula_a := _terreno.local_to_map(_terreno.to_local(boca.position))
		var celula_b := _terreno.local_to_map(_terreno.to_local(boca.end))
		for cx in range(celula_a.x, celula_b.x + 1):
			for cy in range(maxi(celula_a.y, 0), mini(celula_b.y, 23) + 1):
				var celula := Vector2i(cx, cy)
				if _terreno.get_cell_source_id(celula) != -1:
					_terreno.erase_cell(celula)
					comeu = true

	for grupo in ["esteiras", "espinhos", "decoracao", "crates", "cherries", "vapores", "prensas", "plataformas", "enemies"]:
		var pai := get_parent().get_node_or_null(grupo)
		if pai == null:
			continue
		var folga := 140.0 if grupo == "esteiras" else 20.0
		var area := boca.grow(folga)
		for filho in pai.get_children():
			if filho is Node2D and area.has_point(filho.global_position):
				filho.queue_free()
				comeu = true

	if comeu:
		poeira.restart()
		poeira.emitting = true
		if tocar_som and not mastigar.playing:
			mastigar.play()


# ---------------------------------------------------------------- câmera e UI
func _tremer_camera(forca: float) -> void:
	var camada := get_viewport().get_camera_2d()
	if camada:
		camada.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * forca


func _zerar_camera() -> void:
	var camada := get_viewport().get_camera_2d()
	if camada:
		camada.offset = Vector2.ZERO


func _criar_aviso() -> void:
	_camada_aviso = CanvasLayer.new()
	_camada_aviso.layer = 6
	_camada_aviso.visible = false

	_flash = ColorRect.new()
	_flash.color = Color(1, 0.1, 0.05, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada_aviso.add_child(_flash)

	_rotulo = Label.new()
	_rotulo.text = "!! SE MEXA !!"
	_rotulo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_rotulo.offset_top = 90.0
	_rotulo.offset_left = -200.0
	_rotulo.offset_right = 200.0
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotulo.add_theme_font_size_override("font_size", 34)
	_rotulo.add_theme_color_override("font_color", Color(1, 0.25, 0.15))
	_rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_rotulo.add_theme_constant_override("outline_size", 8)
	_camada_aviso.add_child(_rotulo)

	add_child(_camada_aviso)
