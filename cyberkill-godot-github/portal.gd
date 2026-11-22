extends Area2D

@export_file("*.tscn") var target_scene: String = "res://Level01Entrance.tscn"

@onready var prompt_layer: CanvasLayer = get_node("../CanvasLayer")

var player_inside: CharacterBody2D = null


func _ready() -> void:
	prompt_layer.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside != null and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file(target_scene)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = body as CharacterBody2D
		if body.has_method("set_near_portal"):
			body.set_near_portal(true)
		prompt_layer.show()


func _on_body_exited(body: Node2D) -> void:
	if body == player_inside:
		if body.has_method("set_near_portal"):
			body.set_near_portal(false)
		player_inside = null
		prompt_layer.hide()
