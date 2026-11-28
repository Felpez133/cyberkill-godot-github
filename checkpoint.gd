extends Area2D
## CHECKPOINT — placa estilo "Star Post" do Sonic (cena: checkpoint.tscn).
##
## Ao passar na frente da placa:
##  - o checkpoint é registrado em PlayerData (posição, cena e id);
##  - a placa gira e muda de cor, e soltam-se fogos (nó "Fireworks");
##  - aparece "CHECKPOINT!" sobre a placa e um aviso no alto da tela.
## Ao morrer, o botão "ÚLTIMO CHECKPOINT" da tela de morte recarrega a fase e o jogador
## nasce aqui (personagem.gd _ready). Sem checkpoint, ele volta ao ponto inicial da fase.
##
## TROCAR O VISUAL POR UM AnimatedSprite2D (sem mexer em código):
##  1) Adicione um AnimatedSprite2D filho do Checkpoint com o nome exato "AnimatedSprite2D".
##  2) No SpriteFrames crie as animações "inactive" (loop), "activate" (sem loop) e "active" (loop).
##  3) Pronto: o script esconde o nó "Visual" (a placa desenhada por código) e toca
##     "inactive" ao carregar, "activate" quando o jogador ativa e depois "active".
##     Se "activate" não existir, ele vai direto para "active". O nó "Visual" pode ser apagado.
##  O sinal "checkpoint_reached" também pode ser ligado a outros nós (sons, luzes...).
## O pé do sprite deve ficar na origem (0,0) do nó Checkpoint: é aí que fica o chão.

signal checkpoint_reached(player: Node2D)

## Nome livre para você se orientar no editor (a identificação real usa o caminho do nó).
@export var checkpoint_id := "checkpoint_1"
## Ajuste fino de onde o jogador nasce, relativo à placa. (0,0) = de pé ao lado da placa.
@export var respawn_offset := Vector2.ZERO
@export var inactive_color := Color(0.95, 0.25, 0.3)
@export var active_color := Color(0.3, 0.95, 0.9)
@export var notice_text := "CHECKPOINT REGISTRADO"

var is_active := false

@onready var visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var board: Polygon2D = get_node_or_null("Visual/Board") as Polygon2D
@onready var fireworks: Node = get_node_or_null("Fireworks")
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var tag: Label = get_node_or_null("Tag") as Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	if board != null:
		board.color = inactive_color
	if tag != null:
		tag.hide()
	if sprite != null:
		if visual != null:
			visual.hide()
		_play_sprite(&"inactive")
	# Fase recarregada depois de morrer: este era o último checkpoint, então já nasce ativo.
	if PlayerData.current_checkpoint != Vector2.ZERO \
			and PlayerData.checkpoint_scene == get_tree().current_scene.scene_file_path \
			and PlayerData.checkpoint_id == _key():
		_set_active(false)


func _key() -> String:
	return "%s|%s" % [checkpoint_id, str(get_path())]


func _on_body_entered(body: Node2D) -> void:
	if is_active or not body.is_in_group("player"):
		return
	PlayerData.current_checkpoint = _respawn_position(body)
	PlayerData.checkpoint_scene = get_tree().current_scene.scene_file_path
	PlayerData.checkpoint_id = _key()
	_set_active(true)
	checkpoint_reached.emit(body)
	_show_screen_notice()


## Onde o jogador nasce: na vertical da placa, com os pés no chão da placa.
func _respawn_position(body: Node2D) -> Vector2:
	var shape_node := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return body.global_position
	var feet_local_y := shape_node.position.y + shape_node.shape.get_rect().end.y
	return global_position + Vector2(0.0, -feet_local_y - 4.0) + respawn_offset


func _set_active(animate: bool) -> void:
	is_active = true
	if sprite != null:
		if animate and _has_animation(&"activate"):
			_play_sprite(&"activate")
			if not sprite.animation_finished.is_connected(_on_activate_finished):
				sprite.animation_finished.connect(_on_activate_finished, CONNECT_ONE_SHOT)
		else:
			_play_sprite(&"active")
	elif board != null:
		_flip_board(animate)
	if animate:
		_burst_fireworks()
		_show_tag()


func _on_activate_finished() -> void:
	_play_sprite(&"active")


func _has_animation(animation_name: StringName) -> bool:
	return sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name)


func _play_sprite(animation_name: StringName) -> void:
	if _has_animation(animation_name):
		sprite.play(animation_name)


## A placa gira (como a do Sonic) e troca de cor no meio do giro.
func _flip_board(animate: bool) -> void:
	if not animate:
		board.color = active_color
		return
	var tween := create_tween()
	tween.tween_property(board, "scale:x", 0.0, 0.12)
	tween.tween_callback(func() -> void: board.color = active_color)
	tween.tween_property(board, "scale:x", -1.0, 0.12)
	tween.tween_property(board, "scale:x", 0.0, 0.12)
	tween.tween_property(board, "scale:x", 1.0, 0.12)


func _burst_fireworks() -> void:
	if fireworks == null:
		return
	for child in fireworks.get_children():
		if child is CPUParticles2D:
			child.restart()
			child.emitting = true


func _show_tag() -> void:
	if tag == null:
		return
	tag.modulate.a = 1.0
	tag.show()
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(tag, "modulate:a", 0.0, 0.6)
	tween.tween_callback(tag.hide)


## Aviso na tela para o jogador saber que o progresso foi registrado.
func _show_screen_notice() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 45
	get_tree().current_scene.add_child(layer)
	var label := Label.new()
	label.text = "✔  " + notice_text
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 70.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", active_color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.05, 0.1, 1.0))
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)
	var tween := layer.create_tween()
	tween.tween_interval(1.4)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(layer.queue_free)
