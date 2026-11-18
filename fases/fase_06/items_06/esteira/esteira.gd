@tool
extends StaticBody2D
## Esteira rolante. A origem fica no canto superior esquerdo da esteira
## e a superfície alinha com o topo de um tile de chão (16 px de altura).

const ALTURA := 16.0

@export var largura: float = 64.0:
	set(valor):
		largura = maxf(valor, 16.0)
		_atualizar()

## Positivo empurra para a direita, negativo para a esquerda.
@export var velocidade: float = 60.0:
	set(valor):
		velocidade = valor
		_atualizar()

var _deslocamento: float = 0.0


func _ready() -> void:
	_atualizar()
	if not Engine.is_editor_hint():
		var som := $som as AudioStreamPlayer2D
		som.finished.connect(som.play)   # repete o som enquanto a cena existir
		som.play()


func _atualizar() -> void:
	if not is_node_ready():
		return

	var colisao := $colisao as CollisionShape2D
	var forma := RectangleShape2D.new()
	forma.size = Vector2(largura, ALTURA)
	colisao.shape = forma
	colisao.position = Vector2(largura / 2.0, ALTURA / 2.0)

	constant_linear_velocity = Vector2(velocidade, 0.0)
	($som as AudioStreamPlayer2D).position = Vector2(largura / 2.0, ALTURA / 2.0)
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_deslocamento = fposmod(_deslocamento + velocidade * delta, 16.0)
	queue_redraw()


func _draw() -> void:
	# Corpo da esteira
	draw_rect(Rect2(0, 0, largura, ALTURA), Color("#2b2f38"))
	draw_rect(Rect2(0, 0, largura, 3), Color("#c9772e"))
	draw_rect(Rect2(0, ALTURA - 3, largura, 3), Color("#14171c"))

	# Setas que mostram o sentido do movimento
	var sentido := 1.0 if velocidade >= 0.0 else -1.0
	var cor := Color("#e8a548")
	var x := -16.0 + _deslocamento

	while x < largura:
		if x > 8.0 and x < largura - 8.0:
			var pontos := PackedVector2Array([
				Vector2(x - 3.0 * sentido, 6.0),
				Vector2(x + 1.0 * sentido, 9.5),
				Vector2(x - 3.0 * sentido, 13.0)
			])
			draw_polyline(pontos, cor, 2.0)
		x += 16.0

	# Roletes das pontas
	for ponta_x in [6.0, largura - 6.0]:
		draw_circle(Vector2(ponta_x, 8.0), 6.5, Color("#14171c"))
		draw_circle(Vector2(ponta_x, 8.0), 4.5, Color("#59616f"))
		draw_circle(Vector2(ponta_x, 8.0), 1.5, Color("#c9772e"))
