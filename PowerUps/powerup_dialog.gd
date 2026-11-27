extends CanvasLayer
## Janela de aviso dos power-ups. Pausa o jogo enquanto está aberta.
##
## Uso:
##   var dialog = preload("res://PowerUps/powerup_dialog.gd").new()
##   get_tree().current_scene.add_child(dialog)
##   dialog.open("TÍTULO", "texto", "ACEITAR", "RECUSAR")
##   var accepted: bool = await dialog.answered
##   dialog.close()
##
## Dá para chamar open() de novo (com a janela já aberta) para trocar o conteúdo, e passar ""
## nos textos dos botões para escondê-los (usado na roleta do power-up aleatório).

signal answered(accepted: bool)

var title_label: Label
var body_label: Label
var accept_button: Button
var decline_button: Button


func _init() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.008, 0.025, 0.7)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)

	body_label = Label.new()
	body_label.add_theme_font_size_override("font_size", 18)
	body_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(640, 110)
	box.add_child(body_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 14)
	box.add_child(buttons)

	decline_button = Button.new()
	decline_button.custom_minimum_size = Vector2(170, 42)
	decline_button.pressed.connect(_answer.bind(false))
	buttons.add_child(decline_button)

	accept_button = Button.new()
	accept_button.custom_minimum_size = Vector2(220, 42)
	accept_button.pressed.connect(_answer.bind(true))
	buttons.add_child(accept_button)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.02, 0.07, 0.98)
	style.border_color = Color(0.05, 0.8, 1.0, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style


func open(title: String, body: String, accept_text: String, decline_text: String = "") -> void:
	title_label.text = title
	body_label.text = body
	accept_button.text = accept_text
	accept_button.visible = accept_text != ""
	decline_button.text = decline_text
	decline_button.visible = decline_text != ""
	get_tree().paused = true
	if accept_button.visible:
		accept_button.grab_focus()


func set_body(body: String) -> void:
	body_label.text = body


func close() -> void:
	get_tree().paused = false
	queue_free()


func _input(event: InputEvent) -> void:
	# ESC = recusar (só quando existe o botão de recusar).
	if event.is_action_pressed("ui_cancel") and decline_button.visible:
		get_viewport().set_input_as_handled()
		_answer(false)


func _answer(accepted: bool) -> void:
	answered.emit(accepted)
