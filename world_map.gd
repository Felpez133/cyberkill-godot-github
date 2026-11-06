extends Node2D

var player_near_portal: bool = false

@onready var portal: Area2D = $Level1Entrance
@onready var enter_button: Button = $CanvasLayer/EnterButton
@onready var fade: ColorRect = $CanvasLayer/Fade

func _ready() -> void:
	enter_button.hide()

	portal.body_entered.connect(_on_portal_body_entered)
	portal.body_exited.connect(_on_portal_body_exited)
	enter_button.pressed.connect(enter_level)

	# Começa com a tela preta e revela o mundo.
	fade.color = Color(0, 0, 0, 1)
	var opening_tween = create_tween()
	opening_tween.tween_property(fade, "color", Color(0, 0, 0, 0), 0.8)

func _on_portal_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near_portal = true
		body.set_near_portal(true)
		enter_button.show()

func _on_portal_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near_portal = false
		body.set_near_portal(false)
		enter_button.hide()

func enter_level() -> void:
	if not player_near_portal:
		return

	enter_button.disabled = true

	# Transição: a tela escurece antes de trocar de cena.
	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), 0.7)
	await tween.finished

	get_tree().change_scene_to_file("res://Level01Entrace.tscn")
