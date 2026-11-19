extends Control


const CARD_FASE = preload("res://comum/cenas/selecao_fases/card_fase/card_fase.tscn")
const CENA_FASE_FINAL := "res://fases/fase_10/fase_10.tscn"


@onready var grade_fases: GridContainer = $Margen/VBoxPrincipal/Conteúdo/GradeFases
@onready var som_hover: AudioStreamPlayer2D = $SomHover

@onready var painel_fase_final: PanelContainer = $Margen/VBoxPrincipal/Conteúdo/PainelFaseFinal
@onready var botao_fase_final: Button = $Margen/VBoxPrincipal/Conteúdo/PainelFaseFinal/BotaoFaseFinal

var estilo_normal: StyleBoxFlat
var posicao_normal: Vector2
var cor_fase: Color

var estilo_final_normal: StyleBoxFlat
var posicao_final_normal: Vector2

@onready var cadeado_final: TextureRect = $Margen/VBoxPrincipal/Conteúdo/PainelFaseFinal/MarginContainer/VBoxFinal/HBoxBloqueio/CadeadoFinal
@onready var texto_bloqueio: Label = $Margen/VBoxPrincipal/Conteúdo/PainelFaseFinal/MarginContainer/VBoxFinal/HBoxBloqueio/TextoBloqueio


var fases = [
	{
		"numero": 2,
		"nome": "Refúgio Florestal",
		"imagem": preload("res://comum/cenas/selecao_fases/imagens/preview_fases/refugio_florestal.png"),
		"cena": "res://fases/fase_02/fase_02.tscn",
		
		"cor": Color("#357A38")
	},
	{
		"numero": 3,
		"nome": "Palácio Centauri",
		"imagem": preload("res://comum/cenas/selecao_fases/imagens/preview_fases/palacio_centauri.png"),
		"cena": "res://fases/fase_03/fase_03.tscn",
		"cor": Color("#3267A8")
	},
	{
		"numero": 4,
		"nome": "Pula Pula e Cai",
		"imagem": preload("res://comum/cenas/selecao_fases/imagens/preview_fases/pula_pula_cai.png"),
		"cena": "res://fases/fase_04/fase_04.tscn",
		"cor": Color("#278A9A")
	},
	{
		"numero": 5,
		"nome": "Extinção",
		"imagem": preload("res://comum/cenas/selecao_fases/imagens/preview_fases/extincao.png"),
		"cena": "res://fases/fase_05/fase_05.tscn",
		"cor": Color("#C05A25")
	},
	{
		"numero": 6,
		"nome": "Fábrica Avulsa",
		"imagem": preload("res://comum/cenas/selecao_fases/imagens/preview_fases/fabrica_avulsa.png"),
		"cena": "res://fases/fase_06/fase_06.tscn",
		"cor": Color("#9A512C")
	},
	{
		"numero": 7,
		"nome": "Caverna de Geodo",
		"imagem": preload("res://comum/cenas/selecao_fases/imagens/preview_fases/caverna_geodo.png"),
		"cena": "res://fases/fase_07/fase_07.tscn",
		"cor": Color("#693A9B")
	},
	{
		"numero": 8,
		"nome": "Calor Demais",
		"imagem": preload("res://comum/cenas/selecao_fases/imagens/preview_fases/calor_demais.png"),
		"cena": "res://fases/fase_08/fase_08.tscn",
		"cor": Color("#B7472A")
	},
	{
		"numero": 9,
		"nome": "Mares Fundas",
		"imagem": preload("res://comum/cenas/selecao_fases/imagens/preview_fases/mares_fundas.png"),
		"cena": "res://fases/fase_09/fase_09.tscn",
		"cor": Color("#167C91")
	}
]


func _ready() -> void:
	Globals.player_life = Globals.max_life
	Globals.cherries = 0
	Globals.gems = 0
	Checkpoint.limpar()
	
	criar_cards()
	
	estilo_final_normal = painel_fase_final.get_theme_stylebox("panel").duplicate()
	call_deferred("guardar_posicao_fase_final")
	_configurar_navegacao.call_deferred()

func guardar_posicao_fase_final() -> void:
	posicao_final_normal = painel_fase_final.position

# --------------------------------------------------
# CRIAÇÃO DOS CARDS
# --------------------------------------------------

func criar_cards() -> void:

	for fase in fases:

		var card = CARD_FASE.instantiate()

		grade_fases.add_child(card)

		card.configurar(
			fase["nome"],
			fase["imagem"],
			fase["cena"],
			fase["numero"],
			fase["cor"]
		)
		
		card.hover.connect(tocar_som_hover)
	
		
# --------------------------------------------------
# SOM DOS BOTÕES
# --------------------------------------------------
func tocar_som_hover() -> void:
	som_hover.play()

func _on_botão_voltar_mouse_entered() -> void:
	tocar_som_hover()


func _on_button_ranking_mouse_entered() -> void:
	tocar_som_hover()


func _on_botao_fase_final_mouse_entered() -> void:
	botao_fase_final.grab_focus()


func _destacar_fase_final() -> void:
	var estilo_hover: StyleBoxFlat = estilo_final_normal.duplicate()

	estilo_hover.border_width_left = 3
	estilo_hover.border_width_top = 3
	estilo_hover.border_width_right = 3
	estilo_hover.border_width_bottom = 3

	if Progresso.fase_final_desbloqueada():
		estilo_hover.border_color = Color("#4CAF50")
	else:
		estilo_hover.border_color = Color("#8A8A8A")

	estilo_hover.shadow_color = Color(0, 0, 0, 0.35)
	estilo_hover.shadow_size = 4
	estilo_hover.shadow_offset = Vector2(0, 3)

	painel_fase_final.add_theme_stylebox_override("panel",estilo_hover)

	painel_fase_final.position = posicao_final_normal + Vector2(0, -3)
	
	tocar_som_hover()


func _on_botao_fase_final_mouse_exited() -> void:
	if botao_fase_final.has_focus():
		return
	_restaurar_fase_final()


func _restaurar_fase_final() -> void:
	painel_fase_final.add_theme_stylebox_override("panel",estilo_final_normal)

	painel_fase_final.position = posicao_final_normal


func _on_botao_fase_final_pressed() -> void:
	if not Progresso.fase_final_desbloqueada():
		return
	
	get_tree().change_scene_to_file(CENA_FASE_FINAL)


func _configurar_navegacao() -> void:
	var botoes: Array[Button] = []
	for card in grade_fases.get_children():
		botoes.append(card.get_node("Botao"))
	if botoes.is_empty():
		return

	var voltar: Button = $Margen/VBoxPrincipal/Rodape/BotãoVoltar
	var ranking: Button = $Margen/VBoxPrincipal/Rodape/ButtonRanking
	var colunas := grade_fases.columns
	for i in range(botoes.size()):
		var botao := botoes[i]
		var coluna := i % colunas
		var esquerda: Button = botoes[i - 1] if coluna > 0 else botao
		var direita: Button = botoes[i + 1] if coluna < colunas - 1 and i + 1 < botoes.size() else botao_fase_final
		var acima: Button = botoes[i - colunas] if i >= colunas else botao
		var abaixo: Button = botoes[i + colunas] if i + colunas < botoes.size() else (voltar if coluna < colunas / 2 else ranking)
		_definir_vizinhos(botao, esquerda, direita, acima, abaixo)

	_definir_vizinhos(botao_fase_final, botoes[mini(colunas - 1, botoes.size() - 1)], botao_fase_final, botao_fase_final, ranking)
	var inicio_ultima_linha := int((botoes.size() - 1) / colunas) * colunas
	_definir_vizinhos(voltar, voltar, ranking, botoes[inicio_ultima_linha], voltar)
	_definir_vizinhos(ranking, voltar, ranking, botao_fase_final, ranking)

	botao_fase_final.focus_entered.connect(_destacar_fase_final)
	botao_fase_final.focus_exited.connect(_restaurar_fase_final)
	voltar.focus_entered.connect(tocar_som_hover)
	ranking.focus_entered.connect(tocar_som_hover)

	# Keep Tab traversal consistent with the visual order as well.
	var ordem: Array[Button] = botoes.duplicate()
	ordem.append_array([botao_fase_final, voltar, ranking])
	for i in range(ordem.size()):
		ordem[i].focus_next = ordem[i].get_path_to(ordem[(i + 1) % ordem.size()])
		ordem[i].focus_previous = ordem[i].get_path_to(ordem[posmod(i - 1, ordem.size())])
	botoes[0].grab_focus()


func _definir_vizinhos(botao: Button, esquerda: Button, direita: Button, acima: Button, abaixo: Button) -> void:
	botao.focus_mode = Control.FOCUS_ALL
	botao.focus_neighbor_left = botao.get_path_to(esquerda)
	botao.focus_neighbor_right = botao.get_path_to(direita)
	botao.focus_neighbor_top = botao.get_path_to(acima)
	botao.focus_neighbor_bottom = botao.get_path_to(abaixo)
