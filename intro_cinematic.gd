extends Node2D

@export var chapter_title: String = "CYBERKILL — PRÓLOGO"
## Página 1 do prólogo (edite pelo Inspector).
@export_multiline var lore_text: String = "Neste mundo, existem 7 grandes IAs...\n\n[ESCREVA AQUI O RESTANTE DA PÁGINA 1 DA HISTÓRIA]"
## Página 2 do prólogo: reservada para a lore (edite pelo Inspector).
@export var chapter_title_page_2: String = "CYBERKILL — PRÓLOGO (PARTE 2)"
@export_multiline var lore_text_page_2: String = "[ESCREVA AQUI A LORE — PÁGINA 2]\n\nEste espaço está reservado para a continuação da história."
@export var camera_pan_duration: float = 12.0
@export var camera_end_x: float = 1320.0
@export_file("*.tscn") var next_scene: String = "res://Tutorial.tscn"

@onready var camera: Camera2D = $Camera2D
@onready var music: AudioStreamPlayer = $Music

var transition_started := false
var current_page := 0
var titles: Array[String] = []
var pages: Array[String] = []
var bg_width := 0.0
@export var background_scroll_speed: float = 22.0
@onready var city_backgrounds: Array[Sprite2D] = [
	$CityBackgroundLeft,
	$CityBackgroundMiddle,
	$CityBackgroundRight
]

func _ready() -> void:
	titles = [chapter_title, chapter_title_page_2]
	pages = [lore_text, lore_text_page_2]
	_build_overlay()
	_show_page(0)
	if music.stream != null:
		music.play()

	camera.position = Vector2(314.0, 565.0)
	_setup_infinite_background()

# Fundo infinito: os painéis ficam colados lado a lado e, quando um sai pela esquerda da
# tela, volta para o fim da fila (sempre há pelo menos 2 painéis cobrindo a câmera).
func _setup_infinite_background() -> void:
	var first := city_backgrounds[0]
	bg_width = first.texture.get_width() * absf(first.scale.x)
	var start_x := camera.position.x - bg_width
	for i in range(city_backgrounds.size()):
		city_backgrounds[i].position.x = start_x + bg_width * (i + 0.5)

func _process(delta: float) -> void:
	if bg_width <= 0.0:
		return
	var visible_half := get_viewport_rect().size.x / camera.zoom.x * 0.5 + 16.0
	var left_edge := camera.position.x - visible_half
	var cycle := bg_width * city_backgrounds.size()
	for background in city_backgrounds:
		background.position.x -= background_scroll_speed * delta
		if background.position.x + bg_width * 0.5 < left_edge:
			background.position.x += cycle

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CinematicUI"
	layer.layer = 10
	add_child(layer)

	var root := Control.new()
	root.name = "Overlay"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var shade := ColorRect.new()
	shade.name = "TextBackdrop"
	shade.color = Color(0.015, 0.02, 0.045, 0.86)
	shade.anchor_left = 0.0
	shade.anchor_top = 0.68
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.offset_left = 0.0
	shade.offset_top = 0.0
	shade.offset_right = 0.0
	shade.offset_bottom = 0.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var title := Label.new()
	title.name = "ChapterTitle"
	title.text = ""
	title.position = Vector2(48, 452)
	title.size = Vector2(820, 42)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
	root.add_child(title)

	var story := Label.new()
	story.name = "StoryText"
	story.text = ""
	story.position = Vector2(50, 498)
	story.size = Vector2(820, 128)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_font_size_override("font_size", 18)
	story.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	root.add_child(story)

	var music_hint := Label.new()
	music_hint.name = "MusicSlotHint"
	music_hint.text = "TRILHA SONORA: atribua seu áudio ao nó Music no Inspector"
	music_hint.position = Vector2(50, 626)
	music_hint.size = Vector2(700, 18)
	music_hint.add_theme_font_size_override("font_size", 11)
	music_hint.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	root.add_child(music_hint)

	var page_label := Label.new()
	page_label.name = "PageIndicator"
	page_label.position = Vector2(900, 480)
	page_label.size = Vector2(190, 22)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.add_theme_font_size_override("font_size", 14)
	page_label.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	root.add_child(page_label)

	var skip_button := Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "PULAR"
	skip_button.position = Vector2(900, 510)
	skip_button.size = Vector2(190, 36)
	skip_button.pressed.connect(_go_to_next_scene)
	root.add_child(skip_button)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "VOLTAR"
	back_button.position = Vector2(900, 552)
	back_button.size = Vector2(190, 32)
	back_button.pressed.connect(_previous_page)
	root.add_child(back_button)

	var continue_button := Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "CONTINUAR"
	continue_button.position = Vector2(900, 590)
	continue_button.size = Vector2(190, 44)
	continue_button.pressed.connect(_next_page)
	root.add_child(continue_button)

func _show_page(index: int) -> void:
	current_page = clampi(index, 0, pages.size() - 1)
	var overlay := get_node_or_null("CinematicUI/Overlay")
	if overlay == null:
		return
	overlay.get_node("ChapterTitle").text = titles[current_page]
	overlay.get_node("StoryText").text = pages[current_page]
	overlay.get_node("PageIndicator").text = "%d / %d" % [current_page + 1, pages.size()]
	overlay.get_node("BackButton").visible = current_page > 0
	var is_last := current_page == pages.size() - 1
	overlay.get_node("ContinueButton").text = "COMEÇAR" if is_last else "CONTINUAR"

func _next_page() -> void:
	if current_page >= pages.size() - 1:
		_go_to_next_scene()
	else:
		_show_page(current_page + 1)

func _previous_page() -> void:
	_show_page(current_page - 1)

func _go_to_next_scene() -> void:
	if transition_started:
		return
	transition_started = true
	var fade := create_tween()
	var overlay := get_node_or_null("CinematicUI/Overlay")
	if overlay:
		fade.tween_property(overlay, "modulate:a", 0.0, 0.45)
	fade.tween_callback(_finish_transition)

func _finish_transition() -> void:
	get_tree().change_scene_to_file(next_scene)
