extends "res://Enemies/enemy_base.gd"
## Tanque (Enemies/enemy_tank.tscn).
## Tudo do inimigo base (patrulha, perseguição, vida, recuo) + ATIRA no jogador quando ele
## está visivelmente perto: dentro do alcance E sem parede/chão no caminho.
## Ao atirar o tanque para por um instante, toca a animação "attack" e dispara.

const BULLET_SCENE := preload("res://Enemies/enemy_bullet.tscn")

@export_group("Tiro")
## Distância máxima (em pixels) para o tanque começar a atirar.
@export var shoot_range: float = 260.0
## Tempo entre um tiro e o próximo.
@export var shoot_interval: float = 1.8
## Tempo entre começar a animação e o projétil sair.
@export var shoot_windup: float = 0.3
## Duração total da pausa do disparo (animação + recuperação).
@export var shoot_duration: float = 0.55
@export var bullet_speed: float = 260.0
@export var bullet_damage: int = 1
## Posição do cano em relação ao tanque (x é espelhado quando ele vira para a esquerda).
@export var muzzle_offset: Vector2 = Vector2(12.0, -28.0)
## Se ligado, parede ou chão entre o tanque e o jogador impedem o tiro.
@export var need_line_of_sight: bool = true

var shoot_cooldown := 0.8
var shoot_timer := 0.0
var shot_fired := false


func _physics_process(delta: float) -> void:
	shoot_cooldown = maxf(0.0, shoot_cooldown - delta)
	if shoot_timer > 0.0:
		shoot_timer -= delta
		move_locked = true
		if not shot_fired and shoot_duration - shoot_timer >= shoot_windup:
			shot_fired = true
			_fire()
		if shoot_timer <= 0.0:
			move_locked = false
	elif shoot_cooldown <= 0.0 and _can_see_player():
		shoot_timer = shoot_duration
		shot_fired = false
		shoot_cooldown = shoot_interval
		move_locked = true
	super(delta)


func _can_see_player() -> bool:
	if recoil_timer > 0.0 or not is_instance_valid(player):
		return false
	var target := _player_center()
	var from := _muzzle_position()
	if from.distance_to(target) > shoot_range:
		return false
	if not need_line_of_sight:
		return true
	var query := PhysicsRayQueryParameters2D.create(from, target, 1)
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var collider = hit.get("collider")
	return collider == player or (collider is Node and (collider as Node).is_in_group("enemy"))


func _fire() -> void:
	if not is_instance_valid(player):
		return
	var origin := _muzzle_position()
	var bullet := BULLET_SCENE.instantiate()
	bullet.direction = (_player_center() - origin).normalized()
	bullet.speed = bullet_speed
	bullet.damage = bullet_damage
	# Primeiro entra na cena, depois posiciona (vale para cenas cuja raiz não fica em 0,0).
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = origin


func _muzzle_position() -> Vector2:
	return global_position + Vector2(muzzle_offset.x * face_direction, muzzle_offset.y)


func _player_center() -> Vector2:
	var shape := player.get_node_or_null("CollisionShape2D") as Node2D
	return shape.global_position if shape != null else player.global_position


func _update_animation() -> void:
	if shoot_timer > 0.0:
		_play_animation(&"attack")
	else:
		super()
