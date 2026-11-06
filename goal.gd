extends Node2D



func _on_body_entered(body):
	if body.is_in_group("player"):
		get_tree().chenge_scene_to_file("res//Level01Entrance")
