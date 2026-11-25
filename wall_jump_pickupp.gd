extends Area2D
## Pendrive do Wall Jump: agora é coletado por INTERAÇÃO (tecla E perto dele),
## não mais por simples colisão.

@onready var prompt: Label = get_node_or_null("Prompt") as Label

var player: Node2D = null


func _ready() -> void:
	if prompt != null:
		prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		if prompt != null:
			prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		if prompt != null:
			prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if player == null or not event.is_action_pressed("interact"):
		return
	if player.has_method("unlock_wall_jump"):
		get_viewport().set_input_as_handled()
		player.unlock_wall_jump()
		queue_free()
