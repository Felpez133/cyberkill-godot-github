extends Area2D
## Botão interativo (cena button.tscn).
##
## Chegue perto e aperte E. Ao ativar ele pode:
##  - fazer sumirem nós (ex.: um TileMapLayer "passagem secreta"): preencha "Vanish Targets";
##  - trocar de cena (ex.: voltar para a cidade, node_2d.tscn): Action = Change Scene.
## Tudo é configurado no Inspector; o sinal "activated" também pode ser ligado a outros nós.

signal activated

enum Action { NONE, CHANGE_SCENE }

@export var prompt_text := "E  —  DESTRAVAR"
@export var activated_text := "DESTRAVADO!"
@export var action: Action = Action.NONE
@export_file("*.tscn") var target_scene := "res://node_2d.tscn"
## Missão (UI/mission_hud.tscn) concluída quando este botão é ativado. Deixe vazio para nenhuma.
## Ex.: "nucleo_ia" = "Desligar um núcleo da IA".
@export var mission_id := ""
## Nós que somem quando o botão é ativado (caminho relativo a este botão).
@export var vanish_targets: Array[NodePath] = []
@export var vanish_time := 1.2
@export var one_shot := true
@export var locked_color := Color(1.0, 0.45, 0.45)
@export var unlocked_color := Color(0.45, 1.0, 0.6)

var player_near := false
var used := false
var transitioning := false

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var prompt: Label = get_node_or_null("Prompt") as Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	if sprite != null:
		sprite.modulate = locked_color
	if prompt != null:
		prompt.text = prompt_text
		prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = true
		_update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near = false
		_update_prompt()


func _update_prompt() -> void:
	if prompt == null:
		return
	prompt.text = activated_text if used else prompt_text
	prompt.visible = player_near


func _unhandled_input(event: InputEvent) -> void:
	if not player_near or transitioning:
		return
	if used and one_shot:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_activate()


func _activate() -> void:
	used = true
	if sprite != null:
		sprite.modulate = unlocked_color
	if prompt != null:
		prompt.text = activated_text
		prompt.show()
	activated.emit()
	if mission_id != "":
		PlayerData.complete_mission(mission_id)
	for path in vanish_targets:
		var node := get_node_or_null(path)
		if node == null:
			push_warning("Botão: nó não encontrado em Vanish Targets: %s" % str(path))
			continue
		_vanish(node)
	if action == Action.CHANGE_SCENE:
		_change_scene()


func _vanish(node: Node) -> void:
	if not node is CanvasItem:
		node.queue_free()
		return
	var item := node as CanvasItem
	var tween := create_tween()
	# Pisca como um holograma falhando e depois desaparece.
	var step := vanish_time / 8.0
	for i in range(3):
		tween.tween_property(item, "modulate:a", 0.25, step * 0.5)
		tween.tween_property(item, "modulate:a", 1.0, step * 0.5)
	tween.tween_property(item, "modulate:a", 0.0, vanish_time * 0.5)
	tween.tween_callback(_finish_vanish.bind(node))


func _finish_vanish(node: Node) -> void:
	if not is_instance_valid(node):
		return
	# A colisão só é removida no fim do efeito (TileMapLayer, StaticBody2D, etc.).
	if "collision_enabled" in node:
		node.set("collision_enabled", false)
	if node is CollisionObject2D:
		node.set_deferred("collision_layer", 0)
		node.set_deferred("collision_mask", 0)
	(node as CanvasItem).hide()


func _change_scene() -> void:
	if not ResourceLoader.exists(target_scene):
		push_error("Botão: a cena de destino não existe: " + target_scene)
		return
	transitioning = true
	var layer := CanvasLayer.new()
	layer.layer = 40
	get_tree().current_scene.add_child(layer)
	var fade := ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(fade, "color:a", 1.0, 0.6)
	tween.tween_callback(get_tree().change_scene_to_file.bind(target_scene))
