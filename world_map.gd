extends Node2D

@export_file("*.tscn") var interior_scene: String = "res://BuildingInterior.tscn"

var player_near_door := false
var transitioning := false
var door_area: Area2D
var prompt: Label
var fade: ColorRect

func _ready() -> void:
	# Os portais antigos da rua ficam escondidos: agora o acesso é pela porta do prédio.
	for node_name in ["Level1Entrance", "Level2Entrance", "Level3Entrance"]:
		var old_portal := get_node_or_null(node_name)
		if old_portal is Area2D:
			old_portal.monitoring = false
			old_portal.monitorable = false
			old_portal.hide()

	_create_door()
	_create_transition()

func _create_door() -> void:
	door_area = Area2D.new()
	door_area.name = "BuildingDoor"
	door_area.position = Vector2(833, 105)
	add_child(door_area)

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(76, 112)
	shape_node.shape = shape
	door_area.add_child(shape_node)

	# Moldura e folha da porta em estilo neon, posicionadas sobre a fachada.
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([
		Vector2(-34, -54), Vector2(34, -54), Vector2(34, 54),
		Vector2(-34, 54)
	])
	frame.color = Color(0.05, 0.85, 1.0, 0.95)
	door_area.add_child(frame)

	var leaf := Polygon2D.new()
	leaf.polygon = PackedVector2Array([
		Vector2(-27, -47), Vector2(27, -47), Vector2(27, 50),
		Vector2(-27, 50)
	])
	leaf.color = Color(0.035, 0.025, 0.12, 1.0)
	door_area.add_child(leaf)

	var window := Polygon2D.new()
	window.polygon = PackedVector2Array([
		Vector2(-17, -36), Vector2(17, -36), Vector2(17, -8),
		Vector2(-17, -8)
	])
	window.color = Color(0.1, 0.85, 1.0, 0.8)
	door_area.add_child(window)

	var handle := Polygon2D.new()
	handle.polygon = PackedVector2Array([
		Vector2(17, 7), Vector2(21, 7), Vector2(21, 13), Vector2(17, 13)
	])
	handle.color = Color(1.0, 0.75, 0.2, 1.0)
	door_area.add_child(handle)

	prompt = Label.new()
	prompt.text = "E  —  ENTRAR NO PRÉDIO"
	prompt.position = Vector2(-110, -92)
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	prompt.hide()
	door_area.add_child(prompt)

	door_area.body_entered.connect(_on_door_body_entered)
	door_area.body_exited.connect(_on_door_body_exited)

func _create_transition() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

func _process(_delta: float) -> void:
	if player_near_door and not transitioning and Input.is_action_just_pressed("interact"):
		_enter_building()

func _on_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near_door = true
		prompt.show()
		if body.has_method("set_near_portal"):
			body.set_near_portal(true)

func _on_door_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near_door = false
		prompt.hide()
		if body.has_method("set_near_portal"):
			body.set_near_portal(false)

func _enter_building() -> void:
	transitioning = true
	prompt.hide()
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.55)
	await tween.finished
	get_tree().change_scene_to_file(interior_scene)
