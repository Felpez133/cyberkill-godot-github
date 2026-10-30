
extends Control

func _ready() -> void:
	$BotaoIniciar.pressed.connect(_on_iniciar_pressed)
	$BotaoSair.pressed.connect(_on_sair_pressed)

func _on_iniciar_pressed() -> void:
	get_tree().change_scene_to_file("res://node_2d.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
