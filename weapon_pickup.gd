
extends Area2D

@export var prompt_text := "PRESSIONE E PARA PEGAR A ARMA"
## Animação de flutuar (sobe e desce em loop até a arma ser pega).
@export var bob_height := 5.0
@export var bob_time := 0.9

var player: Node2D
var label: Label
var collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	label = Label.new()
	label.text = prompt_text
	label.position = Vector2(-100, -55)
	label.visible = false
	add_child(label)
	_start_bobbing()


func _start_bobbing() -> void:
	var visual := get_node_or_null("Sprite2D") as Node2D
	if visual == null:
		return
	var base_y := visual.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(visual, "position:y", base_y - bob_height, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "position:y", base_y + bob_height, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _process(_delta: float) -> void:
	if collected:
		return

	if is_instance_valid(player) and Input.is_action_just_pressed("interact"):
		collected = true

		# Desbloqueia os disparos do jogador
		PlayerData.has_weapon = true

		print("ARMA COLETADA! DISPARO DESBLOQUEADO!")

		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		label.visible = false
