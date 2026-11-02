extends Node2D

var player_near_entrance: bool = false

@onready var entrance_label: Label = $CanvasLayer/Label


func _ready() -> void:
	entrance_label.visible = false


func _process(_delta: float) -> void:
	if player_near_entrance and Input.is_action_just_pressed("attack"):
		enter_level()


func _on_level_01_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near_entrance = true
		entrance_label.visible = true


func _on_level_01_entrance_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near_entrance = false
		entrance_label.visible = false


func enter_level() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/Level01.tscn")

func _on_level_1_entrance_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
