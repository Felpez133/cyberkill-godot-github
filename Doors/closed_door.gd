@tool
extends StaticBody2D
## PORTA FECHADA com botão (Doors/closed_door.tscn).
## Fica trancada (colisão ligada) até um botão (button.tscn) mandá-la "sumir" — o botão usa:
##   Vanish Targets = esta porta   (ela pisca como holograma, some e perde a colisão)
##   Camera Focus   = esta porta   (a câmera viaja até ela e volta — a mesma animação do Level 1)
## Mude o "Size" no Inspector para encaixar a porta exatamente na passagem.

@export var size: Vector2 = Vector2(32, 128):
	set(value):
		size = value
		_apply_size()
@export var door_color: Color = Color(0.32, 0.42, 0.62, 1.0)


func _ready() -> void:
	_apply_size()


func _apply_size() -> void:
	if not is_inside_tree():
		return
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null:
		var rect := RectangleShape2D.new()
		rect.size = size
		shape_node.shape = rect
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		var half := size * 0.5
		visual.polygon = PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
		visual.color = door_color
	var stripe := get_node_or_null("Stripe") as Polygon2D
	if stripe != null:
		stripe.polygon = PackedVector2Array([Vector2(-4, -size.y * 0.5 + 6), Vector2(4, -size.y * 0.5 + 6), Vector2(4, size.y * 0.5 - 6), Vector2(-4, size.y * 0.5 - 6)])
