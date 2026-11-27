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
## Câmera: ao ativar, a câmera viaja até este nó (caminho relativo ao botão), espera, faz os
## "Vanish Targets" sumirem NA FRENTE do jogador e volta. Deixe vazio para não ter cutscene.
@export_group("Câmera")
@export var camera_focus: NodePath
@export var camera_travel_time := 1.1
## Pausa com a câmera parada no alvo ANTES de começar a sumir.
@export var camera_hold_before := 0.5
## Pausa depois que o efeito de sumir termina, antes de voltar.
@export var camera_hold_after := 0.8
@export var camera_focus_offset := Vector2.ZERO
## Congela o jogador (e o deixa sem levar dano) durante a cutscene.
@export var freeze_player := true
@export_group("Progressão")
## Mundo liberado ao ativar este botão (0 = Mundo 1, 1 = Mundo 2...). -1 = nenhum.
@export var unlock_world_index := -1
@export_group("Cores")
@export var locked_color := Color(1.0, 0.45, 0.45)
@export var unlocked_color := Color(0.45, 1.0, 0.6)

var player_near := false
var used := false
var transitioning := false
var busy := false

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
	if not player_near or transitioning or busy:
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
	if unlock_world_index >= 0:
		PlayerData.unlock_world(unlock_world_index)
	var focus: Node2D = null
	if not camera_focus.is_empty():
		focus = get_node_or_null(camera_focus) as Node2D
		if focus == null:
			push_warning("Botão: nó não encontrado em Camera Focus: %s" % str(camera_focus))
	if focus != null:
		busy = true
		await _camera_sequence(focus)
		busy = false
	else:
		_vanish_all()
	if action == Action.CHANGE_SCENE:
		_change_scene()


func _vanish_all() -> void:
	for path in vanish_targets:
		var node := get_node_or_null(path)
		if node == null:
			push_warning("Botão: nó não encontrado em Vanish Targets: %s" % str(path))
			continue
		_vanish(node)


## Câmera vai até o alvo, espera, a passagem some na frente do jogador, e a câmera volta.
func _camera_sequence(focus: Node2D) -> void:
	var player_cam := get_viewport().get_camera_2d()
	if player_cam == null:
		_vanish_all()
		return
	var player := get_tree().get_first_node_in_group("player")
	_lock_player(player, true)
	var cam := Camera2D.new()
	cam.zoom = player_cam.zoom
	cam.position_smoothing_enabled = false
	get_tree().current_scene.add_child(cam)
	cam.global_position = player_cam.get_screen_center_position()
	cam.make_current()
	var go := create_tween()
	go.tween_property(cam, "global_position", focus.global_position + camera_focus_offset, camera_travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await go.finished
	await get_tree().create_timer(camera_hold_before).timeout
	_vanish_all()
	await get_tree().create_timer(vanish_time + camera_hold_after).timeout
	if is_instance_valid(player_cam):
		var back := create_tween()
		back.tween_property(cam, "global_position", player_cam.get_screen_center_position(), camera_travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await back.finished
		player_cam.make_current()
	cam.queue_free()
	_lock_player(player, false)


func _lock_player(player: Node, locked: bool) -> void:
	if player == null or not freeze_player:
		return
	player.set("cutscene_lock", locked)
	player.set_physics_process(not locked)
	if locked:
		player.set("velocity", Vector2.ZERO)
		var steps = player.get("footsteps")
		if steps != null:
			steps.stop()
		if player.has_method("play_animation"):
			player.play_animation("idle")


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
	if target_scene.ends_with("node_2d.tscn"):
		PlayerData.returned_from_level = true
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
