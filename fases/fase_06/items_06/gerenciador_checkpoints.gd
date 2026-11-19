extends Node2D
## Pai dos checkpoints da fase. Ao recarregar a fase depois de uma morte,
## coloca o jogador e a câmera no último checkpoint tocado.


func _ready() -> void:
	_posicionar.call_deferred()


func _posicionar() -> void:
	var fase := get_parent()
	if not Checkpoint.vale_para(fase):
		return

	var jogador := fase.get_node_or_null("player") as Node2D
	var camera := fase.get_node_or_null("camera") as Camera2D
	if jogador == null:
		return

	jogador.global_position = Checkpoint.posicao
	if jogador is CharacterBody2D:
		jogador.velocity = Vector2.ZERO
	if camera:
		camera.global_position = Checkpoint.posicao
		camera.reset_smoothing()
