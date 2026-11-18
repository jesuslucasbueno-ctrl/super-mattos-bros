extends AudioStreamPlayer
## Toca a trilha da fase em loop.


func _ready() -> void:
	finished.connect(play)
	play()
