extends Area2D

const EXPLOSION_SCENE: PackedScene = preload("res://explosion.tscn")
const WALL_JUMP_PICKUP_SCENE: PackedScene = preload("res://wall_jump_pickup.tscn")

@onready var crate_sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $Prompt

var player_near := false
var opened := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.hide()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if opened or not player_near:
		return
	if event.is_action_pressed("interact"):
		_open_crate()

func _open_crate() -> void:
	if opened:
		return
	opened = true
	prompt.hide()
	crate_sprite.hide()
	set_deferred("monitoring", false)

	var effect: Area2D = EXPLOSION_SCENE.instantiate()
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)
	var effect_animation: AnimatedSprite2D = effect.get_node("AnimatedSprite2D")
	await effect_animation.animation_finished

	var pickup := WALL_JUMP_PICKUP_SCENE.instantiate()
	pickup.global_position = global_position + Vector2(0, -8)
	get_tree().current_scene.add_child(pickup)
	queue_free()
