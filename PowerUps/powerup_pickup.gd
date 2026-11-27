extends Area2D
## Base de todos os power-ups. Cada power-up tem a sua própria cena (PowerUps/powerup_*.tscn)
## com um script que estende este e implementa _run().
##
## Fluxo: chegar perto -> aparece "E — PEGAR" -> E abre a tela de aviso -> o jogador ACEITA
## (o efeito começa) ou RECUSA (o power-up continua no lugar). Enquanto não for pego, o ícone
## fica subindo e descendo em loop.

const DIALOG_SCRIPT := preload("res://PowerUps/powerup_dialog.gd")

@export var prompt_text := "E  —  PEGAR POWER-UP"
## Duração do efeito, em segundos.
@export var duration := 20.0
## Animação de flutuar: altura (px) e tempo de cada subida/descida (s).
@export var bob_height := 5.0
@export var bob_time := 0.9

var player: Node2D = null
var busy := false

@onready var prompt: Label = get_node_or_null("Prompt") as Label
@onready var visual: Node2D = get_node_or_null("Sprite2D") as Node2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	if prompt != null:
		prompt.text = prompt_text
		prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_start_bobbing()


func _start_bobbing() -> void:
	if visual == null:
		return
	var base_y := visual.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(visual, "position:y", base_y - bob_height, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visual, "position:y", base_y + bob_height, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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
	if busy or player == null or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	busy = true
	await _run()
	busy = false


## Implementado por cada power-up.
func _run() -> void:
	pass


func _new_dialog() -> Node:
	var dialog := DIALOG_SCRIPT.new()
	get_tree().current_scene.add_child(dialog)
	return dialog


## Entrega o efeito ao jogador e remove o power-up da fase.
func _give(effect: Dictionary) -> void:
	if is_instance_valid(player) and player.has_method("apply_powerup"):
		player.apply_powerup(effect)
	queue_free()
