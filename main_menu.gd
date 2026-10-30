
extends Control

# Troque pelo caminho da sua cena de gameplay
@export_file("*.tscn") var game_scene: String = "res://Main.tscn"

@onready var play_button: Button = $PlayButton
@onready var options_button: Button = $OptionsButton
@onready var quit_button: Button = $QuitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	play_button.grab_focus()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(game_scene)


func _on_options_pressed() -> void:
	print("Menu de opções ainda será implementado!")


func _on_quit_pressed() -> void:
	get_tree().quit()
