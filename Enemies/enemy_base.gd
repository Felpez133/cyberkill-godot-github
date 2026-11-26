extends CharacterBody2D
## Base de TODOS os inimigos do CyberKill.
##
## Reúne a lógica do BB9 original (patrulha, perseguição, dano de contato, vida)
## e adiciona o RECUO ao encostar no jogador:
##  - ao tocar o jogador, o inimigo anda um pouco para TRÁS (lado oposto ao jogador);
##  - a distância e a duração do recuo são controladas pelos exports abaixo;
##  - o recuo para sozinho se houver parede atrás ou se não houver chão (não cai de plataformas);
##  - depois de recuar existe um tempo de espera (recoil_cooldown) antes de poder recuar de novo,
##    então ele nunca fica recuando para sempre nem preso em animação.
##
## Para criar um inimigo novo: crie uma cena CharacterBody2D (grupo "enemy") com
## CollisionShape2D, DetectionArea (Area2D com CollisionShape2D, collision_layer = 0)
## e um Sprite2D ou AnimatedSprite2D (animações "idle" e "walk"), e use ESTE script nela.

@export_group("Movimento")
@export var speed: float = 85.0
@export var patrol_distance: float = 180.0
@export var detection_radius: float = 230.0
## Marque se a arte original olha para a DIREITA (padrão). Desmarque se ela olha para a esquerda.
@export var sprite_faces_right: bool = true

@export_group("Vida e dano")
@export var max_health: int = 3
## Dano causado ao encostar (sistema de dano original do BB9). Use 0 para um inimigo inofensivo.
@export var contact_damage: int = 1
@export var contact_range: float = 30.0
@export var damage_cooldown: float = 1.0

@export_group("Recuo ao encostar no jogador")
@export var recoil_enabled: bool = true
## Distância total (em pixels) do recuo.
@export var recoil_distance: float = 48.0
## Duração (em segundos) do recuo.
@export var recoil_duration: float = 0.35
## Tempo de espera depois do recuo antes de poder recuar de novo.
@export var recoil_cooldown: float = 0.6
## Se ligado, o recuo é cancelado quando não há chão atrás (evita cair de plataformas).
@export var recoil_avoid_ledges: bool = true

var health: int
var _dead := false
var player: Node2D
var damage_timer := 0.0
var flash_timer := 0.0
var recoil_timer := 0.0
var recoil_cooldown_timer := 0.0
var recoil_direction := 0.0
var patrol_origin := 0.0
var patrol_direction := 1.0
var face_direction := 1.0

var plain_sprite: Sprite2D
var animated_sprite: AnimatedSprite2D
var visual: CanvasItem
var body_shape: CollisionShape2D
var detection: Area2D


func _ready() -> void:
	health = max_health
	patrol_origin = global_position.x
	plain_sprite = get_node_or_null("Sprite2D") as Sprite2D
	animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	visual = plain_sprite if plain_sprite != null else animated_sprite
	body_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D
	detection = get_node_or_null("DetectionArea") as Area2D
	var detection_shape := get_node_or_null("DetectionArea/CollisionShape2D") as CollisionShape2D
	if detection_shape != null:
		var circle := CircleShape2D.new()
		circle.radius = detection_radius
		detection_shape.shape = circle
	if detection != null:
		detection.body_entered.connect(_on_detection_entered)
		detection.body_exited.connect(_on_detection_exited)
	_play_animation(&"idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	damage_timer = maxf(0.0, damage_timer - delta)
	flash_timer = maxf(0.0, flash_timer - delta)
	recoil_cooldown_timer = maxf(0.0, recoil_cooldown_timer - delta)
	if visual != null:
		visual.modulate = Color(1, 0.35, 0.35) if flash_timer > 0.0 else Color.WHITE

	if _player_in_contact():
		_try_damage_player()
		if recoil_enabled and recoil_timer <= 0.0 and recoil_cooldown_timer <= 0.0:
			_start_recoil()

	if recoil_timer > 0.0:
		_recoil_step(delta)
	else:
		_walk_step()

	move_and_slide()

	# Parede atrás durante o recuo: encerra o recuo (não atravessa nem fica empurrando).
	if recoil_timer > 0.0 and is_on_wall() and get_wall_normal().x * recoil_direction < 0.0:
		_end_recoil()
	_update_animation()


# ---------------------------------------------------------------- movimento normal
func _walk_step() -> void:
	var dir := patrol_direction
	if is_instance_valid(player):
		dir = signf(player.global_position.x - global_position.x)
	else:
		if global_position.x >= patrol_origin + patrol_distance:
			patrol_direction = -1.0
		elif global_position.x <= patrol_origin - patrol_distance:
			patrol_direction = 1.0
		dir = patrol_direction
	velocity.x = dir * speed
	_set_facing(dir)


# ---------------------------------------------------------------- recuo
func _start_recoil() -> void:
	var away := -signf(player.global_position.x - global_position.x)
	if away == 0.0:
		away = -face_direction
	recoil_direction = away
	if recoil_avoid_ledges and not _has_floor_ahead(away):
		# Sem chão atrás: não recua (evita cair). Só espera o cooldown.
		recoil_cooldown_timer = recoil_cooldown
		return
	recoil_timer = maxf(recoil_duration, 0.01)


func _recoil_step(delta: float) -> void:
	recoil_timer -= delta
	velocity.x = recoil_direction * (recoil_distance / maxf(recoil_duration, 0.01))
	# Anda de costas: continua virado para o jogador.
	_set_facing(-recoil_direction)
	if recoil_avoid_ledges and not _has_floor_ahead(recoil_direction):
		_end_recoil()
	elif recoil_timer <= 0.0:
		_end_recoil()


func _end_recoil() -> void:
	recoil_timer = 0.0
	recoil_cooldown_timer = recoil_cooldown
	velocity.x = 0.0


# ---------------------------------------------------------------- contato e dano
func _player_in_contact() -> bool:
	if not is_instance_valid(player):
		return false
	# 1) Colisão física direta com o jogador no último movimento.
	for i in range(get_slide_collision_count()):
		if get_slide_collision(i).get_collider() == player:
			return true
	# 2) Mesma regra de proximidade do BB9 original (ao lado, não por cima).
	var player_body := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var vertical_gap := player.global_position.y - global_position.y
	if player_body != null and body_shape != null:
		vertical_gap = player_body.global_position.y - body_shape.global_position.y
	return absf(player.global_position.x - global_position.x) <= contact_range and absf(vertical_gap) <= 24.0


func _try_damage_player() -> void:
	if damage_timer > 0.0 or contact_damage <= 0:
		return
	if player.has_method("take_damage"):
		player.take_damage(contact_damage)
		damage_timer = damage_cooldown


func take_damage(amount: int) -> void:
	if _dead:
		return
	health -= amount
	flash_timer = 0.16
	if health <= 0:
		_dead = true
		PlayerData.register_kill()
		queue_free()


func _on_detection_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body


func _on_detection_exited(body: Node2D) -> void:
	if body == player:
		player = null


# ---------------------------------------------------------------- utilidades
func _has_floor_ahead(dir: float) -> bool:
	var from := _feet_position() + Vector2(dir * (_half_width() + 4.0), -4.0)
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 24.0), 1)
	query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _feet_position() -> Vector2:
	if body_shape == null or body_shape.shape == null:
		return global_position
	var half_height := 16.0
	var rect := body_shape.shape as RectangleShape2D
	var capsule := body_shape.shape as CapsuleShape2D
	var circle := body_shape.shape as CircleShape2D
	if rect != null:
		half_height = rect.size.y * 0.5
	elif capsule != null:
		half_height = capsule.height * 0.5
	elif circle != null:
		half_height = circle.radius
	return body_shape.global_position + Vector2(0.0, half_height)


func _half_width() -> float:
	if body_shape == null or body_shape.shape == null:
		return 12.0
	var rect := body_shape.shape as RectangleShape2D
	var capsule := body_shape.shape as CapsuleShape2D
	var circle := body_shape.shape as CircleShape2D
	if rect != null:
		return rect.size.x * 0.5
	if capsule != null:
		return capsule.radius
	if circle != null:
		return circle.radius
	return 12.0


func _set_facing(dir: float) -> void:
	if dir == 0.0:
		return
	face_direction = dir
	var flip := (dir < 0.0) if sprite_faces_right else (dir > 0.0)
	if plain_sprite != null:
		plain_sprite.flip_h = flip
	if animated_sprite != null:
		animated_sprite.flip_h = flip


func _update_animation() -> void:
	if recoil_timer > 0.0 or absf(velocity.x) > 1.0:
		_play_animation(&"walk")
	else:
		_play_animation(&"idle")


func _play_animation(animation_name: StringName) -> void:
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return
	if animated_sprite.sprite_frames.has_animation(animation_name) and animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
