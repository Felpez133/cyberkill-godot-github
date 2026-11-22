extends Node2D

@export var chapter_title: String = "CYBERKILL — PRÓLOGO"
@export_multiline var lore_text: String = "[ESCREVA AQUI O TEXTO DA HISTÓRIA]\n\nEste espaço está reservado para a lore. Você poderá editar este texto pelo Inspector."
@export var camera_pan_duration: float = 12.0
@export var camera_end_x: float = 1320.0
@export_file("*.tscn") var next_scene: String = "res://Tutorial.tscn"

@onready var camera: Camera2D = $Camera2D
@onready var music: AudioStreamPlayer = $Music

var transition_started := false
@export var background_scroll_speed: float = 22.0
@onready var city_backgrounds: Array[Sprite2D] = [
	$CityBackgroundLeft,
	$CityBackgroundMiddle,
	$CityBackgroundRight
]

func _ready() -> void:
	_build_overlay()
	if music.stream != null:
		music.play()

	camera.position = Vector2(314.0, 565.0)
	# O cenário desliza continuamente; cada painel reaparece depois do último.
	# Assim o prólogo não termina com uma faixa vazia no horizonte.

func _process(delta: float) -> void:
	if transition_started:
		return
	var widths: Array[float] = []
	for background in city_backgrounds:
		widths.append(background.texture.get_width() * absf(background.scale.x))
	for i in range(city_backgrounds.size()):
		var background := city_backgrounds[i]
		background.position.x -= background_scroll_speed * delta
		var half_width: float = widths[i] * 0.5
		if background.position.x + half_width < camera.position.x - 640.0:
			var rightmost := city_backgrounds[0].position.x
			for other in city_backgrounds:
				rightmost = maxf(rightmost, other.position.x)
			background.position.x = rightmost + half_width + widths[i] * 0.5

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
	title.text = chapter_title
	title.position = Vector2(48, 452)
	title.size = Vector2(820, 42)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
	root.add_child(title)

	var story := Label.new()
	story.name = "Neste mundo, existem 7 grandes IAs "
	story.text = lore_text
	story.position = Vector2(50, 498)
	story.size = Vector2(820, 125)
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

	var skip_button := Button.new()
	skip_button.name = "SkipButton"
	skip_button.text = "PULAR"
	skip_button.position = Vector2(900, 510)
	skip_button.size = Vector2(190, 42)
	skip_button.pressed.connect(_go_to_next_scene)
	root.add_child(skip_button)

	var continue_button := Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "CONTINUAR"
	continue_button.position = Vector2(900, 562)
	continue_button.size = Vector2(190, 48)
	continue_button.pressed.connect(_go_to_next_scene)
	root.add_child(continue_button)

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
