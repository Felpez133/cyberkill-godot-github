extends Control

@onready var status_label: Label = $Status
func _ready() -> void:
	for i in range(5):
		var button: Button = get_node("Worlds/World%d" % (i + 1))
		button.disabled = not PlayerData.world_unlocked[i]
		button.text = "MUNDO %d%s" % [i + 1, "" if PlayerData.world_unlocked[i] else "  🔒"]
		button.pressed.connect(_on_world_pressed.bind(i))
func _on_world_pressed(index: int) -> void:
	if index != 0 or not PlayerData.world_unlocked[index]:
		status_label.text = "Este mundo ainda está bloqueado."
		return
	PlayerData.new_game()
	get_tree().change_scene_to_file("res://node_2d.tscn")
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Menu.tscn")
