extends Node
## Guarda o último checkpoint da fase. Ao morrer, o jogo recarrega a fase e o jogador
## volta ao checkpoint (com a vida e as cerejas que tinha). Sem checkpoint, volta ao menu.

const MENU := "res://comum/cenas/selecao_fases/selecao_fases.tscn"
const VIDA_MINIMA := 6

var ativo: bool = false
var cena: String = ""
var posicao: Vector2 = Vector2.ZERO
var indice: int = -1
var vida: int = 0
var cerejas: int = 0
var gemas: int = 0

var _ocupado: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func registrar(cena_atual: Node, ponto: Vector2, indice_novo: int) -> void:
	ativo = true
	cena = cena_atual.scene_file_path
	posicao = ponto
	indice = indice_novo
	vida = maxi(Globals.player_life, VIDA_MINIMA)
	cerejas = Globals.cherries
	gemas = Globals.gems


func limpar() -> void:
	ativo = false
	cena = ""
	indice = -1


func vale_para(cena_atual: Node) -> bool:
	return ativo and cena_atual != null and cena_atual.scene_file_path == cena


## Chamado quando o jogador morre.
func reaparecer(arvore: SceneTree) -> void:
	if _ocupado:
		return
	_ocupado = true

	if vale_para(arvore.current_scene):
		recarregar_no_checkpoint(arvore)
	else:
		arvore.paused = false
		arvore.call_deferred("change_scene_to_file", MENU)

	await arvore.create_timer(0.6, true).timeout
	_ocupado = false


func recarregar_no_checkpoint(arvore: SceneTree) -> void:
	Globals.player_life = vida
	Globals.cherries = cerejas
	Globals.gems = gemas
	arvore.paused = false
	arvore.call_deferred("reload_current_scene")
