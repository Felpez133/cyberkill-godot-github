
extends Control

@export_file("*.tscn") var game_scene: String = "res://Main.tscn"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var click_button: Button = $Button

var starting_game := false

func _ready() -> void:
	anim.play("idle")

	click_button.mouse_entered.connect(_on_mouse_entered)
	click_button.mouse_exited.connect(_on_mouse_exited)
	click_button.pressed.connect(_on_pressed)


func _on_mouse_entered() -> void:
	if not starting_game:
		anim.play("hover")


func _on_mouse_exited() -> void:
	if not starting_game:
		anim.play("idle")


func _on_pressed() -> void:
	if starting_game:
		return

	starting_game = true
	anim.play("pressed")

	await anim.animation_finished

	get_tree().change_scene_to_file(game_scene)
