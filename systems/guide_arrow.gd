extends Node2D
## SETA DE ORIENTAÇÃO (systems/guide_arrow.tscn).
## Desenhada por código (sem imagem) e balança suavemente. Aparece conforme a dificuldade:
##   Tier 0 = essencial   -> aparece no FÁCIL e no MÉDIO
##   Tier 1 = extra       -> aparece só no FÁCIL
## Nos outros casos a seta se apaga sozinha ao carregar a fase.
## Para trocar por imagem: adicione um Sprite2D filho e desmarque "Draw Arrow".

@export_range(0, 1) var tier: int = 0
## 0 = aponta para a direita, 90 = para baixo, 180 = esquerda, -90 = para cima.
@export_range(-180.0, 180.0) var angle_degrees: float = 0.0
@export var draw_arrow: bool = true
@export var size: float = 30.0
@export var bob_distance: float = 8.0
@export var bob_speed: float = 4.0
@export var color: Color = Color(0.35, 0.9, 1.0, 0.95)

var _time := 0.0


func _ready() -> void:
	z_index = 20
	if not Difficulty.shows_arrow(tier):
		queue_free()


func _process(delta: float) -> void:
	_time += delta * bob_speed
	queue_redraw()


func _draw() -> void:
	if not draw_arrow:
		return
	var points := PackedVector2Array([
		Vector2(size, 0.0), Vector2(0.0, -size * 0.6), Vector2(0.0, -size * 0.25),
		Vector2(-size * 0.8, -size * 0.25), Vector2(-size * 0.8, size * 0.25),
		Vector2(0.0, size * 0.25), Vector2(0.0, size * 0.6)])
	var offset := Vector2.RIGHT.rotated(deg_to_rad(angle_degrees)) * sin(_time) * bob_distance
	points = Transform2D(deg_to_rad(angle_degrees), offset) * points
	draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(0.0, 0.1, 0.2, 0.9), 2.0)
