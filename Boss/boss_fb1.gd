extends CharacterBody2D
## BOSS DA DEMO (sprites da pasta sprites/inimigos/fB1) — Boss/boss_fb1.tscn
##
## O que ele faz:
##  - ANDA até o jogador e para a uma certa distância (Stop Distance);
##  - ATIRA no jogador (1 tiro; na fase 2 vira leque de 3 tiros e fica mais rápido);
##  - PULA em direção ao jogador de tempos em tempos (Jump Interval Min/Max);
##  - SOBE em estruturas: degrau de até Step Height ele sobe andando; estruturas mais altas
##    (até Max Climb Height) ele sobe pulando.
##  - Ao chegar em 50% da vida entra na FASE 2 (anima "special", fica invulnerável por um instante).
##
## Ele fica dormindo até alguém chamar activate() — quem faz isso é a arena (Boss/boss_arena.gd).

signal ativado
signal vida_mudou(atual: float, maximo: float)
signal boss_morreu

const BULLET_SCENE: PackedScene = preload("res://Boss/boss_bullet.tscn")

# Medidas da arte: cada frame tem 96x96, o corpo fica a ~27 px da esquerda e os pés na base.
const FRAME_SIZE := 96.0
const BODY_CENTER_X := 27.0
# Posição do cano (em pixels da arte, relativa ao centro do corpo/pés).
const MUZZLE_OFFSET := Vector2(30.0, -38.0)
const SHOOT_DURATION := 0.5
const ENRAGE_DURATION := 1.0

enum State { SLEEPING, ACTIVE, SHOOTING, AIRBORNE, ENRAGING, DEAD }

@export_group("Boss")
@export var boss_name: String = "FB-1"
@export var max_health: float = 30.0
## Tamanho do sprite (1.0 = tamanho original da arte). A colisão acompanha.
@export var sprite_scale: float = 1.5
## Dano máximo que um único golpe/tiro do jogador pode causar (evita o TIRO HITKILL matar de uma vez).
@export var max_damage_per_hit: float = 3.0
@export var contact_damage: int = 1
@export var contact_cooldown: float = 1.0
## O boss também acorda sozinho quando o jogador chega a essa distância (0 = só pela arena) ou quando leva dano.
@export var wake_distance: float = 380.0

@export_group("Movimento")
@export var walk_speed: float = 85.0
## Distância (px) em que ele para de andar e só atira.
@export var stop_distance: float = 170.0
@export var jump_velocity: float = -520.0
@export var jump_forward_speed: float = 190.0
@export var jump_interval_min: float = 2.6
@export var jump_interval_max: float = 4.4
## Degraus até essa altura (px) ele sobe andando.
@export var step_height: float = 18.0
## Estruturas até essa altura (px) ele sobe pulando.
@export var max_climb_height: float = 130.0
@export var climb_forward_speed: float = 120.0

@export_group("Tiro")
@export var shoot_interval: float = 1.7
## Segundos da animação até o tiro sair (fase 1 / fase 2).
@export var shoot_windup: float = 0.2
@export var spread_windup: float = 0.3
@export var bullet_speed: float = 300.0
@export var bullet_damage: int = 1
## Ângulo (graus) entre os tiros do leque da fase 2.
@export var spread_angle: float = 14.0

@export_group("Fase 2")
## A fase 2 começa quando a vida chega a essa fração do máximo.
@export_range(0.0, 1.0) var enrage_health_ratio: float = 0.5
@export var enrage_speed_multiplier: float = 1.3
@export var enrage_shoot_interval: float = 1.2

var state: State = State.SLEEPING
var health: float = 0.0
var player: Node2D
var enraged := false
var enrage_pending := false
var invulnerable := false
var face_direction := 1.0

var shoot_timer := 1.0
var shoot_anim_timer := 0.0
var shot_fired := false
var shot_windup_now := 0.2
var jump_timer := 3.0
var contact_timer := 0.0
var climb_cooldown := 0.0
var flash_timer := 0.0
var hurt_timer := 0.0
var enrage_timer := 0.0
var air_time := 0.0
var climbing := false
var jump_dir := 1.0
var jump_speed_x := 0.0

var hud_layer: CanvasLayer
var hud_fill: ColorRect

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var contact_area: Area2D = get_node_or_null("ContactArea")
@onready var contact_shape: CollisionShape2D = get_node_or_null("ContactArea/CollisionShape2D")


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	health = max_health
	_apply_scale()
	_build_hud()
	_face(1.0)
	sprite.play(&"idle")
	jump_timer = randf_range(jump_interval_min, jump_interval_max)


# ---------------------------------------------------------------- configuração
func _apply_scale() -> void:
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.position = Vector2(0.0, -FRAME_SIZE * 0.5 * sprite_scale)
	var body := body_shape.shape as RectangleShape2D
	if body != null:
		body.size = Vector2(24.0, 48.0) * sprite_scale
		body_shape.position = Vector2(0.0, -24.0 * sprite_scale)
	if contact_shape != null:
		var area := contact_shape.shape as RectangleShape2D
		if area != null:
			area.size = Vector2(31.0, 52.0) * sprite_scale
			contact_shape.position = Vector2(0.0, -26.0 * sprite_scale)


## Acorda o boss e começa a luta. Chamado pela arena.
func activate(target: Node2D = null) -> void:
	if state != State.SLEEPING:
		return
	player = target if target != null else get_tree().get_first_node_in_group("player") as Node2D
	# Boss e jogador não se empurram: o boss atravessa o jogador e causa dano por contato.
	if player is PhysicsBody2D:
		add_collision_exception_with(player)
		(player as PhysicsBody2D).add_collision_exception_with(self)
	state = State.ACTIVE
	print("[Boss] acordou: ", name)
	shoot_timer = 1.0
	jump_timer = randf_range(jump_interval_min, jump_interval_max)
	hud_layer.visible = true
	_update_hud()
	ativado.emit()


# ---------------------------------------------------------------- loop principal
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	shoot_timer -= delta
	jump_timer -= delta
	contact_timer -= delta
	climb_cooldown -= delta
	flash_timer -= delta
	hurt_timer -= delta

	match state:
		State.SLEEPING:
			velocity.x = 0.0
			_check_wake_distance()
		State.DEAD:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		State.ENRAGING:
			velocity.x = 0.0
			_process_enraging(delta)
		State.SHOOTING:
			velocity.x = 0.0
			_process_shooting(delta)
		State.AIRBORNE:
			_process_airborne(delta)
		State.ACTIVE:
			_process_active()

	move_and_slide()
	_update_contact_damage()
	_update_sprite()


func _check_wake_distance() -> void:
	if wake_distance <= 0.0:
		return
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target != null and target.global_position.distance_to(global_position) <= wake_distance:
		activate(target)


# ---------------------------------------------------------------- comportamento normal
func _process_active() -> void:
	if enrage_pending:
		_start_enrage()
		return
	if not is_instance_valid(player):
		velocity.x = 0.0
		return
	var to_player := player.global_position.x - global_position.x
	var dir := signf(to_player)
	if dir != 0.0:
		_face(dir)

	if is_on_floor():
		if jump_timer <= 0.0:
			_start_attack_jump(dir, absf(to_player))
			return
		if shoot_timer <= 0.0:
			_start_shoot()
			return

	var speed := walk_speed * (enrage_speed_multiplier if enraged else 1.0)
	if absf(to_player) > stop_distance:
		velocity.x = dir * speed
		_try_climb(dir)
	else:
		velocity.x = 0.0


# ---------------------------------------------------------------- pulo
func _start_attack_jump(dir: float, distance: float) -> void:
	velocity.y = jump_velocity
	jump_dir = dir if dir != 0.0 else face_direction
	jump_speed_x = jump_forward_speed * clampf(distance / 250.0, 0.25, 1.0)
	climbing = false
	air_time = 0.0
	state = State.AIRBORNE
	jump_timer = randf_range(jump_interval_min, jump_interval_max)
	sprite.play(&"jump")


func _start_climb_jump(dir: float, obstacle_height: float) -> void:
	# Impulso exato para passar por cima do obstáculo (+ folga).
	var g := get_gravity().length()
	velocity.y = -sqrt(2.0 * g * (obstacle_height + 28.0))
	jump_dir = dir
	climbing = true
	air_time = 0.0
	state = State.AIRBORNE
	sprite.play(&"jump")


func _process_airborne(delta: float) -> void:
	air_time += delta
	velocity.x = jump_dir * (climb_forward_speed if climbing else jump_speed_x)
	if air_time > 0.12 and is_on_floor() and velocity.y >= 0.0:
		climbing = false
		velocity.x = 0.0
		shoot_timer = maxf(shoot_timer, 0.4)
		state = State.ACTIVE


# ---------------------------------------------------------------- subir em estruturas
## Se tem alguma coisa (que não seja o jogador/inimigos) na frente, procura a menor altura
## em que dá para passar: degrau pequeno = sobe andando; maior = sobe pulando.
func _try_climb(dir: float) -> void:
	if dir == 0.0 or not is_on_floor() or climb_cooldown > 0.0:
		return
	if not _blocked_ahead(global_transform, dir):
		return
	climb_cooldown = 0.3
	var h := 2.0
	while h <= max_climb_height:
		if test_move(global_transform, Vector2(0.0, -h)):
			return # teto: não dá para subir mais
		var raised := global_transform.translated(Vector2(0.0, -h))
		if not _blocked_ahead(raised, dir):
			if h <= step_height:
				global_position.y -= h
				velocity.y = 0.0
			else:
				_start_climb_jump(dir, h)
			return
		h += 2.0


func _blocked_ahead(from: Transform2D, dir: float) -> bool:
	var info := KinematicCollision2D.new()
	if test_move(from, Vector2(dir * 4.0, 0.0), info):
		var collider := info.get_collider() as Node
		if collider != null and (collider.is_in_group("player") or collider.is_in_group("enemy")):
			return false
		return true
	return false


# ---------------------------------------------------------------- tiro
func _start_shoot() -> void:
	state = State.SHOOTING
	shoot_anim_timer = 0.0
	shot_fired = false
	shot_windup_now = spread_windup if enraged else shoot_windup
	shoot_timer = (enrage_shoot_interval if enraged else shoot_interval) + randf_range(-0.2, 0.3)
	sprite.play(&"shoot_spread" if enraged else &"shoot")


func _process_shooting(delta: float) -> void:
	shoot_anim_timer += delta
	if is_instance_valid(player):
		_face(signf(player.global_position.x - global_position.x))
	if not shot_fired and shoot_anim_timer >= shot_windup_now:
		shot_fired = true
		_fire()
	if shoot_anim_timer >= SHOOT_DURATION:
		state = State.ACTIVE


func _fire() -> void:
	if not is_instance_valid(player):
		return
	var origin := _muzzle_position()
	var base_direction := (_player_center() - origin).normalized()
	var angles: Array[float] = [0.0]
	if enraged:
		angles = [-spread_angle, 0.0, spread_angle]
	for angle in angles:
		var bullet := BULLET_SCENE.instantiate()
		bullet.direction = base_direction.rotated(deg_to_rad(angle))
		bullet.speed = bullet_speed * (1.15 if enraged else 1.0)
		bullet.damage = bullet_damage
		# Primeiro entra na cena, depois posiciona (vale para cenas cuja raiz não fica em 0,0).
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = origin


func _muzzle_position() -> Vector2:
	return global_position + Vector2(MUZZLE_OFFSET.x * face_direction, MUZZLE_OFFSET.y) * sprite_scale


func _player_center() -> Vector2:
	var shape := player.get_node_or_null("CollisionShape2D") as Node2D
	return shape.global_position if shape != null else player.global_position


# ---------------------------------------------------------------- fase 2
func _start_enrage() -> void:
	enrage_pending = false
	state = State.ENRAGING
	invulnerable = true
	enrage_timer = ENRAGE_DURATION
	sprite.play(&"special")


func _process_enraging(delta: float) -> void:
	enrage_timer -= delta
	if enrage_timer <= 0.0:
		enraged = true
		invulnerable = false
		shoot_timer = 0.5
		state = State.ACTIVE


# ---------------------------------------------------------------- dano e morte
func take_damage(amount: float) -> void:
	if state == State.SLEEPING:
		activate()
	if state == State.SLEEPING or state == State.DEAD or invulnerable:
		return
	health = maxf(health - minf(amount, max_damage_per_hit), 0.0)
	flash_timer = 0.12
	vida_mudou.emit(health, max_health)
	_update_hud()
	if health <= 0.0:
		_die()
		return
	if not enraged and not enrage_pending and health <= max_health * enrage_health_ratio:
		enrage_pending = true
	if state == State.ACTIVE:
		hurt_timer = 0.2


func _die() -> void:
	state = State.DEAD
	invulnerable = true
	climbing = false
	if contact_area != null:
		contact_area.set_deferred("monitoring", false)
	sprite.play(&"death")
	hud_layer.visible = false
	PlayerData.register_kill()
	boss_morreu.emit()
	await sprite.animation_finished
	await get_tree().create_timer(1.0).timeout
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
	await tween.finished
	queue_free()


func _update_contact_damage() -> void:
	if state == State.SLEEPING or state == State.DEAD or contact_area == null or contact_timer > 0.0:
		return
	for body in contact_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(contact_damage)
			contact_timer = contact_cooldown
			break


# ---------------------------------------------------------------- visual
func _face(dir: float) -> void:
	if dir == 0.0:
		return
	face_direction = dir
	sprite.flip_h = dir < 0.0
	# O corpo não fica no centro do frame; o offset (espelhado) o mantém sobre a colisão.
	sprite.offset.x = (FRAME_SIZE * 0.5 - BODY_CENTER_X) * (-1.0 if dir < 0.0 else 1.0)


func _update_sprite() -> void:
	var base_color := Color(1.0, 0.72, 0.72) if enraged else Color.WHITE
	sprite.modulate = Color(1.0, 0.35, 0.35) if flash_timer > 0.0 else base_color
	if state == State.ACTIVE:
		if hurt_timer > 0.0:
			_play(&"hurt")
		elif absf(velocity.x) > 5.0:
			_play(&"walk")
		else:
			_play(&"idle")
	elif state == State.SLEEPING:
		_play(&"idle")


func _play(animation_name: StringName) -> void:
	if sprite.animation != animation_name:
		sprite.play(animation_name)


# ---------------------------------------------------------------- barra de vida (HUD)
func _build_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 50
	hud_layer.visible = false
	add_child(hud_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(root)

	var title := Label.new()
	title.text = boss_name
	title.anchor_left = 0.25
	title.anchor_right = 0.75
	title.offset_top = 10.0
	title.offset_bottom = 34.0
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title)

	var back := ColorRect.new()
	back.color = Color(0.05, 0.05, 0.08, 0.85)
	back.anchor_left = 0.25
	back.anchor_right = 0.75
	back.offset_top = 36.0
	back.offset_bottom = 54.0
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(back)

	hud_fill = ColorRect.new()
	hud_fill.color = Color(0.9, 0.15, 0.2)
	hud_fill.anchor_right = 1.0
	hud_fill.anchor_bottom = 1.0
	hud_fill.offset_left = 2.0
	hud_fill.offset_top = 2.0
	hud_fill.offset_right = -2.0
	hud_fill.offset_bottom = -2.0
	hud_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(hud_fill)


func _update_hud() -> void:
	if hud_fill == null:
		return
	hud_fill.anchor_right = clampf(health / maxf(max_health, 0.001), 0.001, 1.0)
