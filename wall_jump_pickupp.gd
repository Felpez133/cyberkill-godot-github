extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("unlock_wall_jump"):
		body.unlock_wall_jump()
		queue_free()
