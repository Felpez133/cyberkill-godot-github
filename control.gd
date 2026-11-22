extends Control

func _ready() -> void:
	$BotaoIniciar.pressed.connect(_on_iniciar_pressed)
	$BotaoTutorial.pressed.connect(_on_tutorial_pressed)
	$BotaoSair.pressed.connect(_on_sair_pressed)

func _on_iniciar_pressed() -> void:
	get_tree().change_scene_to_file("res://WorldSelect.tscn")

func _on_tutorial_pressed() -> void:
	# Permite rever o tutorial pelo menu, mesmo depois de concluir a campanha.
	PlayerData.new_game()
	get_tree().change_scene_to_file("res://Tutorial.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
