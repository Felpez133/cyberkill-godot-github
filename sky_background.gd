extends CanvasLayer
## Fundo (céu + sol) PRESO À CÂMERA: fica atrás de tudo e acompanha a tela, sem rolar com o mapa.
## É uma CanvasLayer com layer negativo, então a câmera do jogador não o move.
##
## Hide Underground: quando a câmera desce para as cavernas o céu some aos poucos
## (senão o sol apareceria dentro dos túneis). Desmarque para o sol ficar sempre visível.

@export var hide_underground := true
## Altura (y do mundo, em pixels) onde o céu começa a sumir...
@export var fade_start_y := 760.0
## ...e onde já sumiu por completo.
@export var fade_end_y := 1100.0

@onready var picture: CanvasItem = $Fundo


func _process(_delta: float) -> void:
	if not hide_underground:
		picture.modulate.a = 1.0
		return
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var y := camera.get_screen_center_position().y
	picture.modulate.a = clampf(inverse_lerp(fade_end_y, fade_start_y, y), 0.0, 1.0)
