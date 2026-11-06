extends Area2D
@export var checkpoint_id := "checkpoint_1"
var activated := false
func _ready() -> void:
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node2D) -> void:
	if activated or not body.is_in_group("player"): return
	activated = true
	PlayerData.current_checkpoint = body.global_position
	PlayerData.checkpoint_scene = get_tree().current_scene.scene_file_path
