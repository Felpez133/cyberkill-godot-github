extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://player.tscn")
const CRATE_SCENE: PackedScene = preload("res://wall_jump_crate.tscn")
const WEAPON_SCENE: PackedScene = preload("res://weapon_pickup.tscn")
const PORTAL_SCENE: PackedScene = preload("res://TutorialPortal.tscn")

var dialogue_layer: CanvasLayer
var dialogue_panel: Panel
var dialogue_title: Label
var dialogue_text: Label
var dialogue_button: Button
var pending_finish := false
var shown_stages: Dictionary = {}
var tutorial_portal_near := false
var tutorial_portal: Area2D
var training_completed := false

func _ready() -> void:
	PlayerData.new_game()
	_build_training_room()
	_spawn_player()
	_spawn_items()
	_build_triggers()
	_build_tutorial_portal()
	_build_dialogue_ui()
	_show_dialogue(
		"TREINAMENTO // BIKER",
		"Bem-vindo ao treinamento, Biker.\n\nUse A e D ou as setas para andar.\nUse ESPAÇO ou W para pular.\nAperte E para interagir com objetos.\n\nAvance pelo cenário para aprender as habilidades.",
		"COMEÇAR"
	)

func _build_training_room() -> void:
	_add_rect(Vector2(-100, 570), Vector2(2600, 100), Color(0.07, 0.055, 0.13, 1.0), -5)
	_add_rect(Vector2(-100, 570), Vector2(2600, 12), Color(0.0, 0.85, 1.0, 1.0), -4)
	_add_static(Vector2(1200, 635), Vector2(2600, 40))
	_add_rect(Vector2(0, 80), Vector2(2400, 5), Color(0.25, 0.08, 0.55, 0.8), -2)

	# Duas paredes baixas formam um trecho para praticar o Wall Jump após obter o pendrive.
	_add_static(Vector2(1030, 500), Vector2(36, 180))
	_add_rect(Vector2(1012, 410), Vector2(36, 180), Color(0.12, 0.12, 0.25, 1.0), 0)
	_add_static(Vector2(1190, 500), Vector2(36, 180))
	_add_rect(Vector2(1172, 410), Vector2(36, 180), Color(0.12, 0.12, 0.25, 1.0), 0)

	var heading := Label.new()
	heading.text = "CYBERKILL  //  ÁREA DE TREINAMENTO"
	heading.position = Vector2(35, 20)
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
	add_child(heading)

func _add_rect(pos: Vector2, size: Vector2, color: Color, z: int) -> void:
	var poly := Polygon2D.new()
	poly.position = pos
	poly.polygon = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	poly.color = color
	poly.z_index = z
	add_child(poly)

func _add_static(pos: Vector2, size: Vector2) -> void:
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
	player.position = Vector2(110, 545)
	add_child(player)

func _spawn_items() -> void:
	var crate := CRATE_SCENE.instantiate()
	crate.position = Vector2(850, 545)
	add_child(crate)

	var weapon := WEAPON_SCENE.instantiate()
	weapon.position = Vector2(1690, 545)
	add_child(weapon)

func _build_triggers() -> void:
	_add_trigger(450, 0)
	_add_trigger(760, 1)
	_add_trigger(1320, 2)
	_add_trigger(1570, 3)
	_add_trigger(2020, 4)

func _add_trigger(x: float, stage: int) -> void:
	var area := Area2D.new()
	area.position = Vector2(x, 535)
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 150)
	shape_node.shape = shape
	area.add_child(shape_node)
	add_child(area)
	area.body_entered.connect(_on_trigger_entered.bind(stage))

func _on_trigger_entered(body: Node2D, stage: int) -> void:
	if not body.is_in_group("player") or shown_stages.has(stage):
		return
	shown_stages[stage] = true
	match stage:
		0:
			_show_dialogue("MOVIMENTAÇÃO", "Você pode andar para a esquerda e para a direita com A/D ou as setas.\n\nPule com ESPAÇO ou W para alcançar plataformas e evitar obstáculos.", "ENTENDI")
		1:
			_show_dialogue("A CAIXA", "Encontrou uma caixa? Chegue perto e aperte E.\n\nEla vai explodir e revelar um pendrive. Pegue o pendrive para desbloquear o Wall Jump.", "VOU TENTAR")
		2:
			if PlayerData.has_wall_jump:
				_show_dialogue("WALL JUMP DESBLOQUEADO", "Agora encoste em uma parede e aperte ESPAÇO/W.\n\nO Biker será impulsionado para longe da parede. O salto pode ser repetido respeitando o pequeno intervalo.", "PRATICAR")
			else:
				_show_dialogue("DICA", "A habilidade Wall Jump ainda está bloqueada. Abra a caixa com E e colete o pendrive antes de tentar saltar nas paredes.", "CONTINUAR")
		3:
			_show_dialogue("PEGUE UMA ARMA", "A arma está logo adiante. Chegue perto e aperte E para pegá-la.\n\nSem arma, o Biker não tem ataque.", "CONTINUAR")
		4:
			_show_dialogue("ATAQUE", "Agora que você tem uma arma, clique com o botão esquerdo do mouse para disparar.\n\nBoa! O treinamento terminou. Vá até o portal no final da fase e aperte E para entrar no Mundo 1.", "CONTINUAR", true)

func _build_tutorial_portal() -> void:
	if tutorial_portal != null:
		return
	tutorial_portal = PORTAL_SCENE.instantiate()
	tutorial_portal.name = "TutorialPortal"
	tutorial_portal.position = Vector2(2260, 535)
	tutorial_portal.set_unlocked(false)
	add_child(tutorial_portal)

func _build_dialogue_ui() -> void:
	dialogue_layer = CanvasLayer.new()
	dialogue_layer.layer = 50
	dialogue_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialogue_layer)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.008, 0.025, 0.58)
	dialogue_layer.add_child(shade)

	dialogue_panel = Panel.new()
	dialogue_panel.position = Vector2(65, 420)
	dialogue_panel.size = Vector2(1030, 245)
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style())
	dialogue_layer.add_child(dialogue_panel)

	dialogue_title = Label.new()
	dialogue_title.position = Vector2(28, 20)
	dialogue_title.size = Vector2(970, 38)
	dialogue_title.add_theme_font_size_override("font_size", 26)
	dialogue_title.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
	dialogue_panel.add_child(dialogue_title)

	dialogue_text = Label.new()
	dialogue_text.position = Vector2(28, 68)
	dialogue_text.size = Vector2(970, 112)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size", 18)
	dialogue_text.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	dialogue_panel.add_child(dialogue_text)

	dialogue_button = Button.new()
	dialogue_button.position = Vector2(790, 185)
	dialogue_button.size = Vector2(205, 42)
	dialogue_button.pressed.connect(_close_dialogue)
	dialogue_panel.add_child(dialogue_button)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.02, 0.07, 0.97)
	style.border_color = Color(0.05, 0.8, 1.0, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

func _show_dialogue(title: String, message: String, button_text: String, finish: bool = false) -> void:
	pending_finish = finish
	dialogue_title.text = title
	dialogue_text.text = message
	dialogue_button.text = button_text
	dialogue_layer.show()
	get_tree().paused = true

func _close_dialogue() -> void:
	get_tree().paused = false
	dialogue_layer.hide()
	if pending_finish:
		pending_finish = false
		training_completed = true
		if tutorial_portal:
			tutorial_portal.set_unlocked(true)
