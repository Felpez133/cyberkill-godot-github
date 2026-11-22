extends CharacterBody2D
@export var speed: float = 85.0
@export var max_health: int = 3
@export var contact_damage: int = 1
@export var patrol_distance: float = 180.0
@export var detection_radius: float = 230.0
@export var contact_range: float = 30.0
@export var damage_cooldown: float = 1.0
var health: int
var player: Node2D
var damage_timer := 0.0
var patrol_origin := 0.0
var patrol_direction := 1.0
var flash_timer := 0.0
@onready var sprite: Sprite2D = $Sprite2D
@onready var detection: Area2D = $DetectionArea
func _ready() -> void:
	health = max_health
	patrol_origin = global_position.x
	var circle := CircleShape2D.new()
	circle.radius = detection_radius
	$DetectionArea/CollisionShape2D.shape = circle
	detection.body_entered.connect(_on_detection_entered)
	detection.body_exited.connect(_on_detection_exited)
func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity += get_gravity() * delta
	damage_timer = maxf(0.0, damage_timer - delta)
	flash_timer = maxf(0.0, flash_timer - delta)
	sprite.modulate = Color(1, 0.35, 0.35) if flash_timer > 0 else Color.WHITE
	var dir := patrol_direction
	if is_instance_valid(player):
		dir = signf(player.global_position.x - global_position.x)
		var player_body := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
		var enemy_body := get_node_or_null("CollisionShape2D") as CollisionShape2D
		var vertical_gap := (player_body.global_position.y - enemy_body.global_position.y) if player_body and enemy_body else (player.global_position.y - global_position.y)
		# Só causa dano quando o jogador está ao lado, não quando está saltando por cima.
		if absf(player.global_position.x - global_position.x) <= contact_range and absf(vertical_gap) <= 24.0 and damage_timer <= 0:
			if player.has_method("take_damage"):
				player.take_damage(contact_damage)
				damage_timer = damage_cooldown
	else:
		if global_position.x >= patrol_origin + patrol_distance: patrol_direction = -1.0
		elif global_position.x <= patrol_origin - patrol_distance: patrol_direction = 1.0
		dir = patrol_direction
	velocity.x = dir * speed
	sprite.flip_h = dir < 0
	move_and_slide()
func _on_detection_entered(body: Node2D) -> void:
	if body.is_in_group("player"): player = body
func _on_detection_exited(body: Node2D) -> void:
	if body == player: player = null
func take_damage(amount: int) -> void:
	health -= amount
	flash_timer = 0.16
	if health <= 0: queue_free()
