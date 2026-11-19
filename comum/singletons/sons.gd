extends Node
## Efeitos sonoros curtos compartilhados (pulo, cereja, dano...).
## Uso: Sons.tocar("pulo")  ->  toca res://comum/sfx/pulo.ogg no canal "Efeitos".

const PASTA := "res://comum/sfx/"
const VOZES := 8

var _cache: Dictionary = {}
var _vozes: Array[AudioStreamPlayer] = []
var _proxima: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	garantir_bus("Musica")
	garantir_bus("Efeitos")
	for i in VOZES:
		var voz := AudioStreamPlayer.new()
		voz.bus = &"Efeitos"
		add_child(voz)
		_vozes.append(voz)


## Cria o canal de áudio se ele ainda não existir (os volumes são salvos nas opções).
static func garantir_bus(nome: String) -> void:
	if AudioServer.get_bus_index(nome) == -1:
		AudioServer.add_bus()
		var indice := AudioServer.bus_count - 1
		AudioServer.set_bus_name(indice, nome)
		AudioServer.set_bus_send(indice, &"Master")


func tocar(nome: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var som: AudioStream = _cache.get(nome)
	if som == null:
		var caminho := PASTA + nome + ".ogg"
		if not ResourceLoader.exists(caminho):
			return
		som = load(caminho)
		_cache[nome] = som

	var voz := _vozes[_proxima]
	_proxima = (_proxima + 1) % VOZES
	voz.stream = som
	voz.volume_db = volume_db
	voz.pitch_scale = pitch
	voz.play()
