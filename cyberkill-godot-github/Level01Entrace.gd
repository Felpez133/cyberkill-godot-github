
extends Area2D

@export var target_scene: String = "res://Level01Entrace"

@onready var enter_button: Button = get_node("../CanvasLayer/EnterButton")

var character_inside: CharacterBody2D = null

func _ready() -> void:
	enter_button.hide()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	enter_button.pressed.connect(_on_button_pressed)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		character_inside = body
		enter_button.show()
		print("player inside")


func _on_body_exited(body: Node2D) -> void:
	if body == character_inside:
		character_inside = null
		enter_button.hide()


func _on_button_pressed() -> void:
	if character_inside != null:
		get_tree().change_scene_to_file(target_scene)
