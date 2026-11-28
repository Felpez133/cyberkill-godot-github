extends Node2D
## ARENA DO BOSS (fase 2) — Boss/boss_arena.gd
##
## Quando o jogador entra na área "Trigger":
##  - a CÂMERA fica FIXA no centro da arena (nó "CameraCenter"), como na luta do Bowser no Super Mario World;
##  - a PORTA da entrada (nó "PortaArena") fecha, para o jogador não sair no meio da luta;
##  - o boss acorda e a luta começa.
## Quando o boss morre: depois de "Release Delay" segundos a câmera volta a seguir o jogador e a porta abre.

signal luta_iniciada
signal luta_terminada

## O boss desta arena (arraste o nó Boss da cena para cá).
@export var boss: Node2D
## Liga/desliga a porta que tranca a entrada durante a luta.
@export var fechar_porta: bool = true
## Velocidade com que a câmera desliza até o centro e de volta (maior = mais rápido).
@export var camera_pan_speed: float = 5.0
## Segundos entre a morte do boss e a câmera ser solta.
@export var release_delay: float = 2.0

var _player: Node2D
var _camera: Camera2D
var _fight_started := false
var _saved_local_position := Vector2.ZERO
var _saved_smoothing_speed := 20.0

@onready var trigger: Area2D = $Trigger
@onready var camera_center: Node2D = $CameraCenter
@onready var door_body: StaticBody2D = get_node_or_null("PortaArena")


func _ready() -> void:
	trigger.body_entered.connect(_on_trigger_body_entered)
	_set_door(false)
	if is_instance_valid(boss):
		if boss.has_signal("boss_morreu"):
			boss.connect("boss_morreu", _on_boss_died)
		# Se o boss acordar por outro motivo (chegou perto / levou dano), a arena também começa.
		if boss.has_signal("ativado"):
			boss.connect("ativado", _on_boss_activated)
	else:
		push_warning("BossArena: o campo 'Boss' está vazio. Arraste o nó do boss para ele no Inspector.")


# Garantia extra: além do sinal, confere todo frame se o jogador já está dentro da área.
func _physics_process(_delta: float) -> void:
	if _fight_started:
		return
	for body in trigger.get_overlapping_bodies():
		if body.is_in_group("player"):
			_start_fight(body)
			return


func _on_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_start_fight(body)


func _on_boss_activated() -> void:
	if _fight_started:
		return
	var found := get_tree().get_first_node_in_group("player") as Node2D
	if found != null:
		_start_fight(found)


func _start_fight(body: Node2D) -> void:
	if _fight_started:
		return
	_fight_started = true
	_player = body
	print("[BossArena] luta começou")
	_lock_camera()
	_set_door(fechar_porta)
	if is_instance_valid(boss) and boss.has_method("activate"):
		boss.call("activate", body)
	luta_iniciada.emit()


func _on_boss_died() -> void:
	await get_tree().create_timer(release_delay).timeout
	_unlock_camera()
	_set_door(false)
	luta_terminada.emit()


# ---------------------------------------------------------------- câmera
func _lock_camera() -> void:
	_camera = _player.get_node_or_null("Camera2D") as Camera2D
	if _camera == null:
		return
	_saved_local_position = _camera.position
	_saved_smoothing_speed = _camera.position_smoothing_speed
	# Congela o script da câmera do jogador (camera_2d.gd mexe no offset) e solta a câmera do jogador.
	_camera.set_process(false)
	_camera.top_level = true
	_camera.position_smoothing_speed = camera_pan_speed
	# O centro da tela é a posição da câmera + offset; por isso desconta o offset.
	_camera.global_position = camera_center.global_position - _camera.offset


func _unlock_camera() -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	_camera.top_level = false
	_camera.position = _saved_local_position
	_camera.set_process(true)
	# Mantém o deslize suave por um instante e só então volta à velocidade normal.
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(_camera):
		_camera.position_smoothing_speed = _saved_smoothing_speed


# ---------------------------------------------------------------- porta
func _set_door(closed: bool) -> void:
	if door_body == null:
		return
	var shape := door_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", not closed)
	var visual := door_body.get_node_or_null("Visual") as CanvasItem
	if visual != null:
		visual.visible = closed
