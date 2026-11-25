extends StaticBody2D
## Porta de mão única.
##
## Ela só pode ser ABERTA por um dos lados ("Open Side"). Do lado errado ela fica trancada
## e mostra um aviso. Depois de aberta (por E), por padrão continua aberta nos dois sentidos
## ("Stay Open"); desmarque para ela fechar sozinha quando o jogador se afastar.
## A origem do nó fica no CHÃO, no centro da porta.

signal opened
signal closed

enum DoorSide { LEFT, RIGHT }

## Lado de onde a porta pode ser aberta (o jogador precisa estar desse lado).
@export var open_side: DoorSide = DoorSide.LEFT
@export var open_prompt := "E  —  ABRIR"
@export var locked_prompt := "TRANCADA DESTE LADO"
@export var stay_open := true
@export var close_delay := 1.5
@export var slide_height := 128.0
@export var slide_time := 0.45

var is_open := false
var player: Node2D = null
var close_timer := 0.0

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var leaf: Node2D = $Leaf
@onready var sense: Area2D = $Sense
@onready var prompt: Label = $Prompt


func _ready() -> void:
	prompt.hide()
	sense.collision_layer = 0
	sense.collision_mask = 1
	sense.body_entered.connect(_on_sense_body_entered)
	sense.body_exited.connect(_on_sense_body_exited)


func _on_sense_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		close_timer = 0.0
		_update_prompt()


func _on_sense_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		prompt.hide()


func _player_on_open_side() -> bool:
	if player == null:
		return false
	var left_of_door := player.global_position.x < global_position.x
	return left_of_door if open_side == DoorSide.LEFT else not left_of_door


func _update_prompt() -> void:
	if player == null or is_open:
		prompt.hide()
		return
	if _player_on_open_side():
		prompt.text = open_prompt
		prompt.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	else:
		prompt.text = locked_prompt
		prompt.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	prompt.show()


func _process(delta: float) -> void:
	if player != null and not is_open:
		_update_prompt()
	if is_open and not stay_open and player == null:
		close_timer += delta
		if close_timer >= close_delay:
			close()


func _unhandled_input(event: InputEvent) -> void:
	if is_open or player == null:
		return
	if event.is_action_pressed("interact") and _player_on_open_side():
		get_viewport().set_input_as_handled()
		open()


func open() -> void:
	if is_open:
		return
	is_open = true
	prompt.hide()
	shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(leaf, "position:y", -slide_height, slide_time)
	tween.parallel().tween_property(leaf, "modulate:a", 0.0, slide_time)
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	close_timer = 0.0
	shape.set_deferred("disabled", false)
	var tween := create_tween()
	tween.tween_property(leaf, "position:y", 0.0, slide_time)
	tween.parallel().tween_property(leaf, "modulate:a", 1.0, slide_time)
	closed.emit()
