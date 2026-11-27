extends Control

func _ready() -> void:
	$BotaoIniciar.pressed.connect(_on_iniciar_pressed)
	$BotaoConfiguracoes.pressed.connect(_on_config_pressed)
	$BotaoSair.pressed.connect(_on_sair_pressed)

func _on_iniciar_pressed() -> void:
	PlayerData.new_game()
	get_tree().change_scene_to_file("res://IntroCinematic.tscn")

func _on_config_pressed() -> void:
	# Abre a tela de Configurações (volume, música e cheats) por cima do menu.
	add_child(preload("res://Settings/settings_menu.tscn").instantiate())

func _on_sair_pressed() -> void:
	get_tree().quit()
