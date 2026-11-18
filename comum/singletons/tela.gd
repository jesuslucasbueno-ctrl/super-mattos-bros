extends Node
## Tela cheia. F11 ou Alt+Enter alternam entre janela e tela cheia.
## O jogo mantém a proporção 16:9 (barras pretas nas sobras, sem mostrar mais mundo).

var _cor_fundo_original: Color = Color(0.3, 0.3, 0.3)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cor_fundo_original = ProjectSettings.get_setting(
		"rendering/environment/defaults/default_clear_color", Color(0.3, 0.3, 0.3))


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var alt_enter: bool = event.alt_pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER)
	if event.keycode == KEY_F11 or alt_enter:
		alternar()
		get_viewport().set_input_as_handled()


func esta_em_tela_cheia() -> bool:
	var modo := get_window().mode
	return modo == Window.MODE_FULLSCREEN or modo == Window.MODE_EXCLUSIVE_FULLSCREEN


func alternar() -> void:
	var janela := get_window()
	if esta_em_tela_cheia():
		janela.mode = Window.MODE_WINDOWED
		RenderingServer.set_default_clear_color(_cor_fundo_original)
	else:
		janela.mode = Window.MODE_FULLSCREEN
		RenderingServer.set_default_clear_color(Color.BLACK)   # barras pretas
