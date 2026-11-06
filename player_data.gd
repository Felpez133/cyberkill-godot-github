extends Node
var has_weapon: bool = false
var current_checkpoint: Vector2 = Vector2.ZERO
var checkpoint_scene: String = ""
var world_unlocked: Array[bool] = [true, false, false, false, false]

func new_game() -> void:
	has_weapon = false
	current_checkpoint = Vector2.ZERO
	checkpoint_scene = ""
	world_unlocked = [true, false, false, false, false]
