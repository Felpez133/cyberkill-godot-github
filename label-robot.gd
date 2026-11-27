extends Label

@export var enemy: Node2D

func _ready() -> void:
	add_to_group("enemy_labels")

func on_enemy_died(dead_enemy: Node2D) -> void:
	if dead_enemy == enemy:
		queue_free()
