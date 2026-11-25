extends Node
var has_weapon: bool = false
var has_wall_jump: bool = false
var current_checkpoint: Vector2 = Vector2.ZERO
var checkpoint_scene: String = ""
var world_unlocked: Array[bool] = [true, false, false, false, false]
# Falas da narradora já exibidas (id -> true). Zerado em new_game().
var narration_seen: Dictionary = {}

func new_game() -> void:
	has_weapon = false
	has_wall_jump = false
	current_checkpoint = Vector2.ZERO
	checkpoint_scene = ""
	world_unlocked = [true, false, false, false, false]
	narration_seen = {}
