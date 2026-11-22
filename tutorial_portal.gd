extends Area2D

signal activated

@export var destination_scene: String = "res://node_2d.tscn"
@onready var prompt: Label = $Prompt

var unlocked := false
var player_near := false
var transitioning := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func set_unlocked(value: bool) -> void:
	unlocked = value
	if not unlocked:
		prompt.hide()
	else:
		_update_prompt()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		if body.has_method("set_near_portal"):
			body.set_near_portal(true)
		_update_prompt()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		prompt.hide()
		if body.has_method("set_near_portal"):
			body.set_near_portal(false)

func _update_prompt() -> void:
	if unlocked and player_near:
		prompt.show()
	else:
		prompt.hide()

func _process(_delta: float) -> void:
	if unlocked and player_near and not transitioning and Input.is_action_just_pressed("interact"):
		transitioning = true
		activated.emit()
		get_tree().change_scene_to_file(destination_scene)
