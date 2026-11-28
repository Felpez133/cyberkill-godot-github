extends Node2D
## Interior do prédio (hub de fases).
##
## Chão e paredes (TileMapLayer), jogador, portais, porta de saída, NPCs e rato são NÓS da
## cena BuildingInterior.tscn: edite tudo visualmente. Este script cuida só da interação
## (tecla E nas portas do grupo "interior_doors") e da transição com fade.

var transitioning := false
var fade: ColorRect

func _ready() -> void:
	_build_fade()

func _build_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

func _process(_delta: float) -> void:
	if transitioning or not Input.is_action_just_pressed("interact"):
		return
	for door in get_tree().get_nodes_in_group("interior_doors"):
		if door.player_inside and door.active and door.target_scene != "":
			_change_scene_with_fade(Difficulty.resolve_scene(door.target_scene), door.fade_time)
			return

func _change_scene_with_fade(scene_path: String, duration: float) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Interior: a cena de destino não existe: " + scene_path)
		return
	transitioning = true
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, duration)
	await tween.finished
	get_tree().change_scene_to_file(scene_path)
