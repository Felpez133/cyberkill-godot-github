extends Control

@onready var status_label: Label = $Status
@onready var worlds: HBoxContainer = $Worlds

func _ready() -> void:
	# Botões: Tutorial (sempre disponível), Mundo 1 e mundos futuros.
	var buttons: Array[Button] = []
	for child in worlds.get_children():
		if child is Button:
			buttons.append(child)
	for i in range(buttons.size()):
		var button := buttons[i]
		if i == 0:
			button.disabled = false
			button.text = "TUTORIAL"
		else:
			var world_index := i - 1
			var unlocked := world_index < PlayerData.world_unlocked.size() and PlayerData.world_unlocked[world_index]
			button.disabled = not unlocked
			button.text = "MUNDO %d%s" % [i, "" if unlocked else "  🔒"]
		button.pressed.connect(_on_world_pressed.bind(i))

func _on_world_pressed(index: int) -> void:
	if index == 0:
		PlayerData.new_game()
		get_tree().change_scene_to_file("res://Tutorial.tscn")
		return
	var world_index := index - 1
	if world_index != 0 or world_index >= PlayerData.world_unlocked.size() or not PlayerData.world_unlocked[world_index]:
		status_label.text = "Este mundo ainda está bloqueado."
		return
	PlayerData.new_game()
	get_tree().change_scene_to_file("res://node_2d.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu.tscn")
