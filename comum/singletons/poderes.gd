extends Node
## PODERES DO TOKEN LENDÁRIO
## Por 15 segundos: +40% de velocidade, +35% de força de pulo e proteção total contra dano.
## Mostra cronômetro, faz o jogador brilhar e anima o fim do poder. Nunca acumula.

const MULT_VELOCIDADE := 1.40
const MULT_PULO := 1.35
const AVISO_FINAL := 3.0
const TEXTURA_HALO := "res://comum/items/token_lendario/halo.png"
const TEXTURA_TOKEN := "res://comum/items/token_lendario/token_lendario.png"

var ativo: bool = false
var restante: float = 0.0
## Verdadeiro depois que o token único da tentativa foi coletado (o menu zera isso).
var token_coletado: bool = false

var _duracao: float = 15.0
var _jogador: CharacterBody2D
var _aura: Node2D
var _tempo: float = 0.0
var _segundo_anterior: int = -1

var _camada_hud: CanvasLayer
var _painel: PanelContainer
var _barra: ColorRect
var _tempo_rotulo: Label
var _barra_largura: float = 100.0


func _ready() -> void:
	_construir_hud()
	_camada_hud.visible = false


# ---------------------------------------------------------------- API
## Ativa os poderes. Devolve false se já estiverem ativos (não acumula).
func ativar(duracao: float = 15.0) -> bool:
	if ativo:
		return false
	var jogador := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if jogador == null:
		return false

	_jogador = jogador
	_duracao = duracao
	restante = duracao
	_tempo = 0.0
	_segundo_anterior = -1
	ativo = true

	_jogador.set("speed_mult", MULT_VELOCIDADE)
	_jogador.set("jump_mult", MULT_PULO)
	_jogador.hurtbox.invulneravel = true
	_criar_aura()

	Sons.tocar("token_lendario")
	_mostrar_mensagem_ativacao()
	_painel.modulate = Color.WHITE
	_camada_hud.visible = true
	return true


## Zera tudo (usado ao voltar ao menu ou reiniciar a fase).
func limpar() -> void:
	_encerrar(false)
	token_coletado = false


# ---------------------------------------------------------------- laço
func _process(delta: float) -> void:
	if not ativo:
		return
	if not is_instance_valid(_jogador):   # a fase foi recarregada (morte): poderes se perdem
		_encerrar(false)
		return

	_tempo += delta
	restante -= delta
	_atualizar_hud()
	_atualizar_brilho()

	if restante <= 0.0:
		_terminar()


func _atualizar_hud() -> void:
	var fracao := clampf(restante / _duracao, 0.0, 1.0)
	_barra.size.x = _barra_largura * fracao
	_tempo_rotulo.text = "%.1fs" % maxf(restante, 0.0)

	var no_fim := restante <= AVISO_FINAL
	var cor := Color(1.0, 0.35, 0.3) if no_fim else Color(1.0, 0.9, 0.45)
	_barra.color = cor
	_tempo_rotulo.add_theme_color_override("font_color", cor)
	_painel.modulate.a = 0.65 + 0.35 * absf(sin(_tempo * 9.0)) if no_fim else 1.0

	var segundo := ceili(restante)
	if no_fim and segundo != _segundo_anterior and segundo > 0:
		Sons.tocar("poder_alerta")
	_segundo_anterior = segundo


func _atualizar_brilho() -> void:
	var sprite := _jogador.get("sprite") as Sprite2D
	if sprite == null:
		return
	if restante <= AVISO_FINAL:   # pisca rápido avisando que vai acabar
		sprite.modulate = Color(1, 1, 1, 0.45) if int(_tempo * 10.0) % 2 == 0 else Color(1.7, 1.5, 0.9, 1.0)
	else:
		var onda := (sin(_tempo * 6.0) + 1.0) / 2.0
		sprite.modulate = Color(1.7, 1.45, 0.75).lerp(Color(1.35, 0.95, 1.9), onda)
	if is_instance_valid(_aura):
		var halo := _aura.get_node("halo") as Sprite2D
		halo.scale = Vector2.ONE * (0.85 + 0.12 * sin(_tempo * 7.0))
		(_aura.get_node("luz") as PointLight2D).energy = 1.1 + 0.4 * sin(_tempo * 8.0)


# ---------------------------------------------------------------- fim do poder
func _terminar() -> void:
	var posicao := _jogador.global_position if is_instance_valid(_jogador) else Vector2.ZERO
	_encerrar(true)
	Sons.tocar("poder_fim")
	_animar_fim(posicao)


func _encerrar(com_animacao: bool) -> void:
	if not ativo:
		return
	ativo = false
	if is_instance_valid(_jogador):
		_jogador.set("speed_mult", 1.0)
		_jogador.set("jump_mult", 1.0)
		_jogador.hurtbox.invulneravel = false
		var sprite := _jogador.get("sprite") as Sprite2D
		if sprite:
			sprite.modulate = Color.WHITE
	if is_instance_valid(_aura):
		_aura.queue_free()
	_camada_hud.visible = false
	if not com_animacao:
		_segundo_anterior = -1


func _animar_fim(posicao: Vector2) -> void:
	var cena := get_tree().current_scene
	if cena == null:
		return

	# Explosão de partículas arroxeadas onde o jogador estava.
	var explosao := CPUParticles2D.new()
	explosao.global_position = posicao + Vector2(0, -12)
	explosao.amount = 48
	explosao.lifetime = 0.9
	explosao.one_shot = true
	explosao.explosiveness = 1.0
	explosao.spread = 180.0
	explosao.gravity = Vector2(0, 60)
	explosao.initial_velocity_min = 40.0
	explosao.initial_velocity_max = 130.0
	explosao.scale_amount_min = 1.5
	explosao.scale_amount_max = 3.0
	var gradiente := Gradient.new()
	gradiente.colors = PackedColorArray([Color(1.0, 0.85, 0.4, 1.0), Color(0.55, 0.3, 0.9, 0.0)])
	explosao.color_ramp = gradiente
	explosao.z_index = 40
	cena.add_child(explosao)
	explosao.emitting = true
	get_tree().create_timer(1.6).timeout.connect(explosao.queue_free)

	# Clarão fraco + mensagem de fim.
	var camada := CanvasLayer.new()
	camada.layer = 10
	var flash := ColorRect.new()
	flash.color = Color(0.7, 0.55, 1.0, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(flash)
	var rotulo := _criar_rotulo("O PODER ACABOU...", 22, Color(0.8, 0.7, 1.0), Color(0.12, 0.05, 0.25))
	rotulo.offset_top = 96.0
	rotulo.offset_bottom = 132.0
	camada.add_child(rotulo)
	cena.add_child(camada)

	var tween := camada.create_tween()
	tween.tween_property(flash, "color:a", 0.35, 0.06)
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.parallel().tween_property(rotulo, "modulate:a", 1.0, 0.1)
	tween.tween_interval(1.1)
	tween.tween_property(rotulo, "modulate:a", 0.0, 0.5)
	tween.tween_callback(camada.queue_free)


# ---------------------------------------------------------------- aura do jogador
func _criar_aura() -> void:
	_aura = Node2D.new()
	_aura.name = "AuraPoder"

	var halo := Sprite2D.new()
	halo.name = "halo"
	halo.texture = load(TEXTURA_HALO)
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = material
	halo.position = Vector2(0, -12)
	halo.scale = Vector2(0.9, 0.9)
	halo.z_index = -1
	_aura.add_child(halo)

	var luz := PointLight2D.new()
	luz.name = "luz"
	luz.position = Vector2(0, -12)
	luz.color = Color(0.95, 0.8, 1.0)
	luz.energy = 1.2
	luz.texture_scale = 3.2
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color.BLACK])
	var textura := GradientTexture2D.new()
	textura.gradient = grad
	textura.width = 64
	textura.height = 64
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	luz.texture = textura
	_aura.add_child(luz)

	var fagulhas := CPUParticles2D.new()
	fagulhas.name = "fagulhas"
	fagulhas.position = Vector2(0, -2)
	fagulhas.amount = 26
	fagulhas.lifetime = 0.8
	fagulhas.local_coords = false
	fagulhas.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fagulhas.emission_rect_extents = Vector2(7, 10)
	fagulhas.direction = Vector2(0, -1)
	fagulhas.spread = 40.0
	fagulhas.gravity = Vector2(0, -20)
	fagulhas.initial_velocity_min = 14.0
	fagulhas.initial_velocity_max = 40.0
	fagulhas.scale_amount_min = 1.0
	fagulhas.scale_amount_max = 2.2
	var g2 := Gradient.new()
	g2.colors = PackedColorArray([Color(1.0, 0.92, 0.5, 1.0), Color(0.6, 0.35, 1.0, 0.0)])
	fagulhas.color_ramp = g2
	_aura.add_child(fagulhas)

	_jogador.add_child(_aura)


# ---------------------------------------------------------------- interface
func _criar_rotulo(texto: String, tamanho: int, cor: Color, contorno: Color) -> Label:
	var rotulo := Label.new()
	rotulo.text = texto
	rotulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_color_override("font_outline_color", contorno)
	rotulo.add_theme_constant_override("outline_size", 8)
	return rotulo


func _mostrar_mensagem_ativacao() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 11
	var rotulo := _criar_rotulo("TOKEN LENDÁRIO ATIVADO!", 32, Color(1.0, 0.87, 0.35), Color(0.25, 0.08, 0.5))
	rotulo.offset_top = 150.0
	rotulo.offset_bottom = 200.0
	rotulo.pivot_offset = Vector2(get_viewport().get_visible_rect().size.x / 2.0, 25.0)
	rotulo.scale = Vector2(0.4, 0.4)
	rotulo.modulate.a = 0.0
	camada.add_child(rotulo)

	var sub := _criar_rotulo("+40% VELOCIDADE   +35% PULO   PROTEÇÃO", 14, Color(0.85, 0.75, 1.0), Color(0.12, 0.05, 0.25))
	sub.offset_top = 196.0
	sub.offset_bottom = 220.0
	sub.modulate.a = 0.0
	camada.add_child(sub)
	get_tree().root.add_child(camada)

	var tween := camada.create_tween()
	tween.set_parallel(true)
	tween.tween_property(rotulo, "scale", Vector2(1.15, 1.15), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(rotulo, "modulate:a", 1.0, 0.2)
	tween.tween_property(sub, "modulate:a", 1.0, 0.4).set_delay(0.2)
	tween.chain().tween_property(rotulo, "scale", Vector2.ONE, 0.15)
	tween.chain().tween_interval(2.0)
	tween.chain().tween_property(rotulo, "modulate:a", 0.0, 0.6)
	tween.parallel().tween_property(sub, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(camada.queue_free)


func _construir_hud() -> void:
	_camada_hud = CanvasLayer.new()
	_camada_hud.layer = 4
	add_child(_camada_hud)

	_painel = PanelContainer.new()
	_painel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_painel.offset_left = -214.0
	_painel.offset_right = -12.0
	_painel.offset_top = 12.0
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.1, 0.05, 0.2, 0.88)
	estilo.border_color = Color(0.97, 0.75, 0.24)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.content_margin_left = 8
	estilo.content_margin_right = 10
	estilo.content_margin_top = 5
	estilo.content_margin_bottom = 5
	_painel.add_theme_stylebox_override("panel", estilo)
	_camada_hud.add_child(_painel)

	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 8)
	_painel.add_child(linha)

	var icone := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(TEXTURA_TOKEN)
	atlas.region = Rect2(0, 0, 32, 32)
	icone.texture = atlas
	icone.custom_minimum_size = Vector2(30, 30)
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(icone)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 3)
	linha.add_child(coluna)

	var titulo := Label.new()
	titulo.text = "TOKEN LENDÁRIO"
	titulo.add_theme_font_size_override("font_size", 11)
	titulo.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	coluna.add_child(titulo)

	var fundo_barra := Control.new()
	fundo_barra.custom_minimum_size = Vector2(_barra_largura, 8)
	coluna.add_child(fundo_barra)
	var trilho := ColorRect.new()
	trilho.color = Color(0.2, 0.12, 0.35)
	trilho.size = Vector2(_barra_largura, 8)
	fundo_barra.add_child(trilho)
	_barra = ColorRect.new()
	_barra.color = Color(1.0, 0.9, 0.45)
	_barra.size = Vector2(_barra_largura, 8)
	fundo_barra.add_child(_barra)

	_tempo_rotulo = Label.new()
	_tempo_rotulo.text = "15.0s"
	_tempo_rotulo.custom_minimum_size = Vector2(50, 0)
	_tempo_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tempo_rotulo.add_theme_font_size_override("font_size", 16)
	_tempo_rotulo.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	linha.add_child(_tempo_rotulo)
