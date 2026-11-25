extends CanvasLayer
## Narradora participativa (autoload "Narrator").
##
## Uso em qualquer script:
##     Narrator.say(["Primeira fala.", "Segunda fala."], "id_unico")
## Com um id, a fala só toca UMA vez por jogo (PlayerData.narration_seen, zerado em new_game()).
## Sem id, toca sempre. Para forçar de novo: Narrator.say(linhas, id, true).
## Cada fala pode ser um texto ou um dicionário {"text": "...", "speaker": "OUTRO NOME"}.
## Também dá para usar a cena Narrator/narrator_trigger.tscn: arraste para a fase,
## escreva as falas no Inspector e pronto.
##
## Retrato: coloque uma imagem em res://Narrator/narradora.png (ela é carregada sozinha).
## Avançar: E, Enter/Espaço ou clique esquerdo.

signal dialogue_finished(id: String)

const PORTRAIT_PATH := "res://Narrator/narradora.png"

@export var speaker_name := "NARRADORA"
@export var chars_per_second := 45.0
@export var pause_game := true

var active := false
var queue: Array = []
var current_id := ""
var typed_chars := 0.0
var typing := false
var paused_before := false

var root: Control
var name_label: Label
var text_label: Label
var hint_label: Label
var portrait_rect: TextureRect
var portrait_fallback: ColorRect


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	root.hide()


func say(lines: Array, id: String = "", force: bool = false) -> bool:
	if lines.is_empty():
		return false
	if id != "" and not force and PlayerData.narration_seen.get(id, false):
		return false
	if id != "":
		PlayerData.narration_seen[id] = true
	for line in lines:
		queue.append(line)
	if active:
		return true
	current_id = id
	active = true
	paused_before = get_tree().paused
	if pause_game:
		get_tree().paused = true
	root.show()
	_next_line()
	return true


func _next_line() -> void:
	if queue.is_empty():
		_finish()
		return
	var line = queue.pop_front()
	var speaker := speaker_name
	var text := ""
	if line is Dictionary:
		text = str(line.get("text", ""))
		speaker = str(line.get("speaker", speaker_name))
	else:
		text = str(line)
	name_label.text = speaker
	text_label.text = text
	text_label.visible_characters = 0
	typed_chars = 0.0
	typing = true
	hint_label.text = "E / ENTER / CLIQUE  ▶"


func _finish() -> void:
	active = false
	typing = false
	root.hide()
	if pause_game:
		get_tree().paused = paused_before
	var finished_id := current_id
	current_id = ""
	dialogue_finished.emit(finished_id)


func _process(delta: float) -> void:
	if not active or not typing:
		return
	typed_chars += chars_per_second * delta
	var total := text_label.get_total_character_count()
	text_label.visible_characters = int(typed_chars)
	if int(typed_chars) >= total:
		text_label.visible_characters = -1
		typing = false


func _input(event: InputEvent) -> void:
	if not active:
		return
	var advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
			advance = true
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if typing:
		text_label.visible_characters = -1
		typing = false
	else:
		_next_line()


func _build_ui() -> void:
	root = Control.new()
	root.name = "NarratorRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := Panel.new()
	panel.name = "Panel"
	panel.anchor_left = 0.05
	panel.anchor_right = 0.95
	panel.anchor_top = 0.68
	panel.anchor_bottom = 0.96
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.02, 0.07, 0.95)
	style.border_color = Color(0.05, 0.8, 1.0, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	portrait_fallback = ColorRect.new()
	portrait_fallback.name = "PortraitFallback"
	portrait_fallback.color = Color(0.05, 0.25, 0.35, 1.0)
	portrait_fallback.position = Vector2(16, 16)
	portrait_fallback.size = Vector2(110, 110)
	panel.add_child(portrait_fallback)
	var initial := Label.new()
	initial.text = "N"
	initial.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.add_theme_font_size_override("font_size", 56)
	initial.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	portrait_fallback.add_child(initial)

	portrait_rect = TextureRect.new()
	portrait_rect.name = "Portrait"
	portrait_rect.position = Vector2(16, 16)
	portrait_rect.size = Vector2(110, 110)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(portrait_rect)
	if ResourceLoader.exists(PORTRAIT_PATH):
		portrait_rect.texture = load(PORTRAIT_PATH)
		portrait_fallback.hide()

	name_label = Label.new()
	name_label.name = "Name"
	name_label.position = Vector2(150, 12)
	name_label.size = Vector2(600, 32)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
	panel.add_child(name_label)

	text_label = Label.new()
	text_label.name = "Text"
	text_label.position = Vector2(150, 48)
	text_label.size = Vector2(800, 90)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 18)
	text_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	panel.add_child(text_label)
	# O texto acompanha a largura do painel em qualquer resolução.
	text_label.anchor_right = 1.0
	text_label.offset_right = -20.0

	hint_label = Label.new()
	hint_label.name = "Hint"
	hint_label.anchor_left = 1.0
	hint_label.anchor_right = 1.0
	hint_label.anchor_top = 1.0
	hint_label.anchor_bottom = 1.0
	hint_label.offset_left = -240.0
	hint_label.offset_right = -16.0
	hint_label.offset_top = -30.0
	hint_label.offset_bottom = -6.0
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	panel.add_child(hint_label)
