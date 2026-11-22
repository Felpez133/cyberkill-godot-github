extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://player.tscn")
const LEVEL_ONE_SCENE := "res://Level01Entrace.tscn"
var player_inside_portal: Area2D = null
var transitioning := false
var player_near_exit := false
var fade: ColorRect

func _ready() -> void:
	_build_room()
	_spawn_player()
	_build_portals()
	_build_exit_door()
	_build_fade()

func _build_room() -> void:
	_add_panel(Vector2(-200, -100), Vector2(2200, 720), Color(0.025, 0.025, 0.09, 1.0), -10)
	_add_panel(Vector2(-200, -100), Vector2(2200, 24), Color(0.02, 0.8, 1.0, 1.0), -5)
	_add_panel(Vector2(-200, 560), Vector2(2200, 80), Color(0.045, 0.035, 0.12, 1.0), -5)
	_add_panel(Vector2(-200, 620), Vector2(2200, 35), Color(0.02, 0.85, 1.0, 1.0), -4)
	_add_panel(Vector2(-200, -100), Vector2(30, 720), Color(0.07, 0.06, 0.18, 1.0), -4)
	_add_panel(Vector2(1970, -100), Vector2(30, 720), Color(0.07, 0.06, 0.18, 1.0), -4)
	_add_static_rect(Vector2(900, 637), Vector2(2200, 35))
	# Paredes laterais sólidas do interior, alinhadas aos painéis visuais.
	_add_static_rect(Vector2(-185, 260), Vector2(30, 720))
	_add_static_rect(Vector2(900, -88), Vector2(2200, 24))
	_add_static_rect(Vector2(1985, 260), Vector2(30, 720))

	for x in [120, 430, 740, 1050, 1360, 1670]:
		_add_panel(Vector2(x, 40), Vector2(150, 8), Color(0.08, 0.45, 0.75, 0.8), 0)
		_add_panel(Vector2(x + 18, 80), Vector2(114, 4), Color(0.6, 0.08, 0.7, 0.8), 0)

	var title := Label.new()
	title.text = "CYBERKILL  //  TERMINAL DE ACESSO"
	title.position = Vector2(50, 5)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	add_child(title)

func _add_panel(pos: Vector2, size: Vector2, color: Color, z: int) -> void:
	var panel := Polygon2D.new()
	panel.position = pos
	panel.polygon = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	panel.color = color
	panel.z_index = z
	add_child(panel)

func _add_static_rect(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = pos
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _spawn_player() -> void:
	var player := PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = Vector2(110, 555)
	add_child(player)

func _build_portals() -> void:
	var portal_texture: Texture2D = load("res://sprites/portal/portals.png")
	_create_portal(Vector2(610, 525), "FASE 1  —  CIDADE", true, portal_texture)
	_create_portal(Vector2(1080, 525), "FASE 2  —  BLOQUEADA", false, portal_texture)
	_create_portal(Vector2(1550, 525), "FASE 3  —  BLOQUEADA", false, portal_texture)

func _create_portal(pos: Vector2, title: String, active: bool, texture: Texture2D) -> void:
	var area := Area2D.new()
	area.position = pos
	area.monitoring = active
	add_child(area)

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(100, 150)
	shape_node.shape = shape
	area.add_child(shape_node)

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, 128, 128)
	sprite.scale = Vector2(1.15, 1.15)
	area.add_child(sprite)

	var label := Label.new()
	label.text = title if active else title
	label.position = Vector2(-115, -112)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0) if active else Color(0.65, 0.65, 0.72))
	area.add_child(label)

	if active:
		var prompt := Label.new()
		prompt.text = "E  —  ENTRAR"
		prompt.position = Vector2(-65, 82)
		prompt.add_theme_font_size_override("font_size", 14)
		prompt.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
		prompt.hide()
		area.add_child(prompt)
		area.body_entered.connect(_on_portal_entered.bind(prompt, area))
		area.body_exited.connect(_on_portal_exited.bind(prompt, area))

func _on_portal_entered(body: Node2D, prompt: Label, area: Area2D) -> void:
	if body.is_in_group("player"):
		player_inside_portal = area
		prompt.show()
		if body.has_method("set_near_portal"):
			body.set_near_portal(true)

func _on_portal_exited(body: Node2D, prompt: Label, area: Area2D) -> void:
	if body.is_in_group("player"):
		if player_inside_portal == area:
			player_inside_portal = null
		prompt.hide()
		if body.has_method("set_near_portal"):
			body.set_near_portal(false)

func _build_exit_door() -> void:
	var exit_area := Area2D.new()
	exit_area.position = Vector2(245, 525)
	add_child(exit_area)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 150)
	collision.shape = shape
	exit_area.add_child(collision)
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2(-30, -55), Vector2(30, -55), Vector2(30, 55), Vector2(-30, 55)])
	frame.color = Color(0.0, 0.75, 0.95, 0.9)
	exit_area.add_child(frame)
	var label := Label.new()
	label.text = "E — VOLTAR À CIDADE"
	label.position = Vector2(-105, -95)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	label.hide()
	exit_area.add_child(label)
	exit_area.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			player_near_exit = true
			label.show()
			if body.has_method("set_near_portal"):
				body.set_near_portal(true)
	)
	exit_area.body_exited.connect(func(body: Node2D):
		if body.is_in_group("player"):
			player_near_exit = false
			label.hide()
			if body.has_method("set_near_portal"):
				body.set_near_portal(false)
	)

func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

func _process(_delta: float) -> void:
	if transitioning or not Input.is_action_just_pressed("interact"):
		return
	if player_near_exit:
		_return_to_city()
	elif player_inside_portal != null:
		_enter_level()

func _return_to_city() -> void:
	transitioning = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.55)
	await tween.finished
	get_tree().change_scene_to_file("res://node_2d.tscn")

func _enter_level() -> void:
	transitioning = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.6)
	await tween.finished
	get_tree().change_scene_to_file(LEVEL_ONE_SCENE)
