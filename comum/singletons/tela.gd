extends Node
## Tela cheia. F11 ou Alt+Enter alternam entre janela e tela cheia.
## O jogo mantém a proporção 16:9 (barras pretas nas sobras, sem mostrar mais mundo).

var _cor_fundo_original: Color = Color(0.3, 0.3, 0.3)


const LARGURA_BASE := 800.0
const ALTURA_BASE := 450.0
const OCUPACAO_DA_TELA := 0.88   # a janela inicial ocupa até 88% da área útil da tela


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cor_fundo_original = ProjectSettings.get_setting(
		"rendering/environment/defaults/default_clear_color", Color(0.3, 0.3, 0.3))
	_ajustar_janela_inicial()


func _ajustar_janela_inicial() -> void:
	# O jogo desenha em 800x450 e escala para qualquer janela (proporção 16:9 travada).
	# Aqui só escolhemos um tamanho inicial confortável para o monitor do jogador.
	var janela := get_window()
	if esta_em_tela_cheia() or janela.mode == Window.MODE_MAXIMIZED:
		return

	var area := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	if area.size.x <= 0 or area.size.y <= 0:
		return

	var escala := minf(area.size.x * OCUPACAO_DA_TELA / LARGURA_BASE, area.size.y * OCUPACAO_DA_TELA / ALTURA_BASE)
	escala = maxf(floorf(escala * 4.0) / 4.0, 1.0)   # passos de 0,25x, nunca menor que o original

	var tamanho := Vector2i(roundi(LARGURA_BASE * escala), roundi(ALTURA_BASE * escala))
	janela.size = tamanho
	janela.position = area.position + (area.size - tamanho) / 2


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
