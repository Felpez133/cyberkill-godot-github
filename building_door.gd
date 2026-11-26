
extends Area2D

@export_file("*.tscn") var interior_scene = "res://BuildingInterior.tscn"

@onready var prompt: Label = $Prompt

var player_near_door = false
var transitioning = false


func _ready():
	prompt.hide()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	print("PORTA INICIADA CORRETAMENTE")


func _on_body_entered(body):
	print("ALGO ENTROU NA PORTA: ", body.name)
	print("GRUPO PLAYER: ", body.is_in_group("player"))

	if body.is_in_group("player"):
		player_near_door = true
		prompt.show()


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_near_door = false
		prompt.hide()


func _process(_delta):
	if player_near_door and Input.is_action_just_pressed("interact"):
		print("TECLA E DETECTADA!")
		_enter_building()


func _enter_building():
	if transitioning:
		return

	transitioning = true
	prompt.hide()

	print("TENTANDO CARREGAR: ", interior_scene)

	var result = get_tree().change_scene_to_file(interior_scene)

	if result != OK:
		print("ERRO AO TROCAR DE CENA: ", result)
		transitioning = false
	else:
		print("TROCA DE CENA SOLICITADA!")
