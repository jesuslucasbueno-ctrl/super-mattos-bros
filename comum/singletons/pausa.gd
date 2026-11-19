extends CanvasLayer
## Menu de pausa (Esc ou botão B do controle) com ajuste de volume.
## Só abre dentro das fases (res://fases/...). Os volumes ficam salvos em user://opcoes.cfg.

const MENU := "res://comum/cenas/selecao_fases/selecao_fases.tscn"
const ARQUIVO := "user://opcoes.cfg"
const CANAIS := [["Geral", "Master"], ["Música", "Musica"], ["Efeitos", "Efeitos"]]

var _aberto: bool = false
var _raiz: Control
var _botao_continuar: Button
var _botao_checkpoint: Button
var _sliders: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	Sons.garantir_bus("Musica")
	Sons.garantir_bus("Efeitos")
	_construir()
	_carregar_volumes()
	_raiz.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _aberto:
		fechar()
		get_viewport().set_input_as_handled()
	elif _em_fase():
		abrir()
		get_viewport().set_input_as_handled()


func _em_fase() -> bool:
	var cena := get_tree().current_scene
	return cena != null and cena.scene_file_path.begins_with("res://fases/")


func abrir() -> void:
	_aberto = true
	_botao_checkpoint.visible = Checkpoint.vale_para(get_tree().current_scene)
	_raiz.visible = true
	get_tree().paused = true
	Sons.tocar("clique")
	_botao_continuar.grab_focus()


func fechar() -> void:
	_aberto = false
	_raiz.visible = false
	get_tree().paused = false
	Sons.tocar("clique")
	_salvar_volumes()


func _reiniciar_fase() -> void:
	_salvar_volumes()
	Checkpoint.limpar()
	Globals.player_life = Globals.max_life
	Globals.cherries = 0
	Globals.gems = 0
	_aberto = false
	_raiz.visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()


func _voltar_checkpoint() -> void:
	_salvar_volumes()
	_aberto = false
	_raiz.visible = false
	Checkpoint.recarregar_no_checkpoint(get_tree())


func _ir_para_menu() -> void:
	_salvar_volumes()
	_aberto = false
	_raiz.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU)


# ---------------------------------------------------------------- interface
func _botao(texto: String, acao: Callable) -> Button:
	var botao := Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(260, 34)
	botao.add_theme_font_size_override("font_size", 18)
	botao.pressed.connect(acao)
	botao.pressed.connect(func() -> void: Sons.tocar("clique"))
	return botao


func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_raiz)

	var escuro := ColorRect.new()
	escuro.color = Color(0, 0, 0, 0.62)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(escuro)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(centro)

	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.08, 0.09, 0.11, 0.97)
	estilo.border_color = Color(0.79, 0.47, 0.18)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(6)
	estilo.content_margin_left = 28
	estilo.content_margin_right = 28
	estilo.content_margin_top = 20
	estilo.content_margin_bottom = 20
	painel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(painel)

	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 8)
	painel.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "PAUSA"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", Color(0.91, 0.65, 0.28))
	caixa.add_child(titulo)

	_botao_continuar = _botao("Continuar", fechar)
	caixa.add_child(_botao_continuar)
	_botao_checkpoint = _botao("Voltar ao checkpoint", _voltar_checkpoint)
	caixa.add_child(_botao_checkpoint)
	caixa.add_child(_botao("Reiniciar a fase", _reiniciar_fase))
	caixa.add_child(_botao("Voltar ao menu", _ir_para_menu))

	var separador := HSeparator.new()
	separador.add_theme_constant_override("separation", 10)
	caixa.add_child(separador)

	for item in CANAIS:
		var linha := HBoxContainer.new()
		linha.add_theme_constant_override("separation", 10)
		var rotulo := Label.new()
		rotulo.text = item[0]
		rotulo.custom_minimum_size = Vector2(80, 0)
		rotulo.add_theme_font_size_override("font_size", 16)
		linha.add_child(rotulo)

		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 5
		slider.value = 100
		slider.custom_minimum_size = Vector2(170, 22)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value_changed.connect(_ao_mudar_volume.bind(item[1]))
		linha.add_child(slider)
		caixa.add_child(linha)
		_sliders[item[1]] = slider

	var dica := Label.new()
	dica.text = "Esc: continuar     F11: tela cheia"
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.add_theme_font_size_override("font_size", 13)
	dica.modulate = Color(1, 1, 1, 0.6)
	caixa.add_child(dica)


# ---------------------------------------------------------------- volume
func _ao_mudar_volume(valor: float, canal: String) -> void:
	var indice := AudioServer.get_bus_index(canal)
	if indice == -1:
		return
	AudioServer.set_bus_mute(indice, valor <= 0.0)
	AudioServer.set_bus_volume_db(indice, linear_to_db(maxf(valor / 100.0, 0.0001)))


func _salvar_volumes() -> void:
	var config := ConfigFile.new()
	for canal in _sliders:
		config.set_value("volume", canal, _sliders[canal].value)
	config.save(ARQUIVO)


func _carregar_volumes() -> void:
	var config := ConfigFile.new()
	var existe := config.load(ARQUIVO) == OK
	for canal in _sliders:
		var valor: float = config.get_value("volume", canal, 100.0) if existe else 100.0
		_sliders[canal].set_value_no_signal(valor)
		_ao_mudar_volume(valor, canal)
