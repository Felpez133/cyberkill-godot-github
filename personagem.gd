
extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const WALL_JUMP_HORIZONTAL_SPEED := 340.0
const WALL_JUMP_VERTICAL_SPEED := -420.0
const WALL_SLIDE_SPEED := 110.0
const WALL_JUMP_COOLDOWN := 0.25
const PROJECTILE_SCENE := preload("res://projectile.tscn")

@export var max_health: int = 5
@export var attack_left_offset: float = 500.0
@export var projectile_speed: float = 520.0
@export var shot_cooldown: float = 0.35
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2

var health: int = 5
var is_attacking := false
var invulnerability_time := 0.0
var near_portal := false
var facing := 1.0
var shot_timer := 0.0
var attack_timer := 0.0
var dead := false
var original_attack_x: float
# Intervalo entre impulsos de Wall Jump após desbloquear a habilidade.
var wall_jump_timer := 0.0
var wall_jump_push_timer := 0.0
var wall_jump_push_direction := 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 1.0
var max_air_dashes: int = 2
var air_dashes_remaining: int = 2

# --- Power-ups / cheats / cutscenes ---
# Multiplicadores aplicados pelos power-ups (1.0 = normal).
var speed_multiplier := 1.0
var jump_multiplier := 1.0
var damage_multiplier := 1.0
var one_hit_kill := false
var powerup_god := false
var touch_kill := false
# Ligado pelo botão da passagem secreta enquanto a câmera passeia: o jogador não leva dano.
var cutscene_lock := false
var active_powerup := ""
var perm_effect := {}
var timed_effect := {}
var powerup_name := ""
var powerup_time_left := 0.0
var powerup_rainbow := false
var powerup_layer: CanvasLayer
var powerup_label: Label
var touch_area: Area2D
var rainbow_time := 0.0

@onready var footsteps: AudioStreamPlayer2D = get_node_or_null("Footsteps")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hearts: Array = [
	get_node_or_null("CanvasLayer/HBoxContainer/Heart1"),
	get_node_or_null("CanvasLayer/HBoxContainer/Heart2"),
	get_node_or_null("CanvasLayer/HBoxContainer/Heart3"),
	get_node_or_null("CanvasLayer/HBoxContainer/Heart4"),
	get_node_or_null("CanvasLayer/HBoxContainer/Heart5")
]

func _ready() -> void:
	health = max_health
	add_to_group("player")
	update_health_display()
	_apply_cheat_skin()
	if PlayerData.current_checkpoint != Vector2.ZERO and PlayerData.checkpoint_scene == get_tree().current_scene.scene_file_path:
		global_position = PlayerData.current_checkpoint


func _physics_process(delta: float) -> void:
	if dead:
		return

	_update_powerup(delta)

# DASH
	if Input.is_action_just_pressed("dash") and not is_dashing:
		start_dash()
	# INVULNERABILIDADE
	if invulnerability_time > 0.0:
		invulnerability_time -= delta
		sprite.visible = int(Time.get_ticks_msec() / 90) % 2 == 0
	else:
		sprite.visible = true

	if shot_timer > 0.0:
		shot_timer -= delta

	if wall_jump_timer > 0.0:
		wall_jump_timer = maxf(0.0, wall_jump_timer - delta)

	if wall_jump_push_timer > 0.0:
		wall_jump_push_timer = maxf(0.0, wall_jump_push_timer - delta)

	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		update_facing(direction)

	# MOVIMENTAÇÃO DO DASH
	if is_dashing:
		dash_timer -= delta

		velocity.x = dash_direction * dash_speed * speed_multiplier
		velocity.y = 0

		if dash_timer <= 0.0:
			is_dashing = false
			velocity.x = 0.0

		move_and_slide()
		return
		
		# RECUPERAR DASHES AO TOCAR NO CHÃO
	if is_on_floor():
		air_dashes_remaining = max_air_dashes

	# GRAVIDADE
	if not is_on_floor():
		velocity += get_gravity() * delta

	# WALL SLIDE
	var touching_wall := is_on_wall() and not is_on_floor()

	if touching_wall and velocity.y > 0.0:
		velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)

	# PULO E WALL JUMP
	var did_wall_jump := false

	if Input.is_action_just_pressed("move_up") and not near_portal:
		if is_on_floor():
			velocity.y = JUMP_VELOCITY * jump_multiplier

		elif touching_wall and PlayerData.has_wall_jump and wall_jump_timer <= 0.0:
			var wall_normal := get_wall_normal()

			if wall_normal.x != 0.0:
				velocity.x = wall_normal.x * WALL_JUMP_HORIZONTAL_SPEED
				velocity.y = WALL_JUMP_VERTICAL_SPEED

				wall_jump_timer = WALL_JUMP_COOLDOWN
				wall_jump_push_timer = 0.18
				wall_jump_push_direction = wall_normal.x

				did_wall_jump = true
				update_facing(wall_normal.x)

	# DISPARO
	if PlayerData.has_weapon:
		if Input.is_action_just_pressed("attack") and shot_timer <= 0.0:
			shoot()

	# MOVIMENTAÇÃO NORMAL
	if not did_wall_jump:
		if wall_jump_push_timer > 0.0 and direction == 0.0:
			velocity.x = wall_jump_push_direction * WALL_JUMP_HORIZONTAL_SPEED
		else:
			velocity.x = direction * SPEED * speed_multiplier

	# ANIMAÇÕES
	if not is_on_floor():
		play_animation("jump")
	elif direction != 0:
		play_animation("run")
	else:
		play_animation("idle")

	move_and_slide()

	# PASSOS
	if footsteps:
		if is_on_floor() and abs(velocity.x) > 10 and not dead:
			if not footsteps.playing:
				footsteps.play()
		else:
			footsteps.stop()


func start_dash():
	if is_dashing or air_dashes_remaining <= 0:
		return

	air_dashes_remaining -= 1

	is_dashing = true
	dash_timer = dash_duration
	dash_direction = facing

	velocity.y = 0
func update_facing(direction: float) -> void:
	facing = sign(direction)
	sprite.flip_h = facing < 0
	attack_area.position.x = -original_attack_x if facing < 0 else original_attack_x

func unlock_wall_jump() -> void:
	PlayerData.has_wall_jump = true
	PlayerData.complete_mission("chip_walljump")
	print("HABILIDADE DESBLOQUEADA: WALL JUMP")

func set_near_portal(value: bool) -> void:
	near_portal = value

func play_animation(animation_name: String) -> void:
	if sprite.sprite_frames.has_animation(animation_name) and sprite.animation != animation_name:
		sprite.play(animation_name)

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		is_attacking = false
		attack_shape.set_deferred("disabled", true)

func _on_attack_area_body_entered(body: Node2D) -> void:
	if is_attacking and not body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(999999.0 if one_hit_kill else damage_multiplier)

func is_invincible() -> bool:
	return powerup_god or cutscene_lock or GameSettings.cheat_god


func take_damage(amount: int) -> void:
	if is_invincible() or invulnerability_time > 0.0 or health <= 0 or dead:
		return
	health = max(health - amount, 0)
	invulnerability_time = 1.0
	update_health_display()
	if health <= 0:
		die()

func update_health_display() -> void:
	for i in range(hearts.size()):
		if is_instance_valid(hearts[i]):
			hearts[i].play("full" if i < health else "empty")

func shoot() -> void:
	shot_timer = shot_cooldown
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.direction = Vector2(facing, 0)
	projectile.damage = damage_multiplier
	projectile.instakill = one_hit_kill
	# Primeiro entra na cena, depois define a posição global. Antes era o contrário, e em cenas
	# cuja raiz não fica em (0,0) (como o Tutorial) o tiro nascia deslocado e nunca acertava.
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = sprite.global_position + Vector2(facing * 18.0, -2.0)

# ---------------------------------------------------------------- POWER-UPS
## Chamado pelos power-ups (PowerUps/*.tscn). effect = Dictionary com:
## name, duration, speed, jump, damage (multiplicadores), one_hit_kill, god, touch_kill, rainbow.
## duration > 0  = temporário (ex.: VIDA INFINITA, 20 s); duration <= 0 = dura a partida inteira.
## Um temporário e um permanente podem estar ativos ao mesmo tempo.
func apply_powerup(effect: Dictionary) -> void:
	if float(effect.get("duration", 0.0)) > 0.0:
		timed_effect = effect
		powerup_time_left = float(effect["duration"])
	else:
		perm_effect = effect
	_recompute_powerups()
	_ensure_powerup_hud()
	powerup_label.show()
	_update_powerup_label()


func _recompute_powerups() -> void:
	var effects: Array = [perm_effect, timed_effect]
	speed_multiplier = 1.0
	jump_multiplier = 1.0
	damage_multiplier = 1.0
	one_hit_kill = false
	powerup_god = false
	touch_kill = false
	powerup_rainbow = false
	for e in effects:
		speed_multiplier *= float(e.get("speed", 1.0))
		jump_multiplier *= float(e.get("jump", 1.0))
		damage_multiplier *= float(e.get("damage", 1.0))
		one_hit_kill = one_hit_kill or bool(e.get("one_hit_kill", false))
		powerup_god = powerup_god or bool(e.get("god", false))
		touch_kill = touch_kill or bool(e.get("touch_kill", false))
		powerup_rainbow = powerup_rainbow or bool(e.get("rainbow", false))
	active_powerup = "x" if (not perm_effect.is_empty() or not timed_effect.is_empty()) else ""
	if touch_kill:
		_create_touch_area()
	elif touch_area != null:
		touch_area.queue_free()
		touch_area = null
	if not powerup_rainbow:
		sprite.self_modulate = Color.WHITE


func _update_powerup(delta: float) -> void:
	if active_powerup == "":
		return
	if powerup_rainbow:
		rainbow_time += delta
		sprite.self_modulate = Color.from_hsv(fmod(rainbow_time * 1.2, 1.0), 0.55, 1.0)
	if touch_kill and touch_area != null:
		for body in touch_area.get_overlapping_bodies():
			if body != self and body.is_in_group("enemy"):
				if body.has_method("take_damage"):
					body.take_damage(999999.0)
				else:
					body.queue_free()
	if not timed_effect.is_empty():
		powerup_time_left -= delta
		if powerup_time_left <= 0.0:
			var had_god := powerup_god
			timed_effect = {}
			powerup_time_left = 0.0
			_recompute_powerups()
			# Depois da imortalidade, 1 segundo de proteção para não morrer no mesmo instante.
			if had_god:
				invulnerability_time = maxf(invulnerability_time, 1.0)
	_update_powerup_label()


func _clear_powerup(_give_grace: bool) -> void:
	perm_effect = {}
	timed_effect = {}
	powerup_time_left = 0.0
	_recompute_powerups()
	if powerup_label != null:
		powerup_label.hide()


func _create_touch_area() -> void:
	if touch_area != null:
		return
	touch_area = Area2D.new()
	touch_area.collision_layer = 0
	touch_area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var body_rect := body_shape.shape as RectangleShape2D
	rect.size = (body_rect.size if body_rect != null else Vector2(16, 38)) + Vector2(10, 10)
	shape.shape = rect
	shape.position = body_shape.position
	touch_area.add_child(shape)
	add_child(touch_area)


func _ensure_powerup_hud() -> void:
	if powerup_label != null:
		return
	powerup_layer = CanvasLayer.new()
	powerup_layer.layer = 20
	add_child(powerup_layer)
	powerup_label = Label.new()
	powerup_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	powerup_label.offset_top = 14.0
	powerup_label.offset_left = -220.0
	powerup_label.offset_right = 220.0
	powerup_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	powerup_label.add_theme_font_size_override("font_size", 26)
	powerup_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35))
	powerup_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	powerup_label.add_theme_constant_override("outline_size", 6)
	powerup_layer.add_child(powerup_label)


func _update_powerup_label() -> void:
	if powerup_label == null:
		return
	var lines: Array[String] = []
	if not perm_effect.is_empty():
		lines.append(String(perm_effect.get("name", "POWER-UP")))
	if not timed_effect.is_empty():
		lines.append("%s   %.1fs" % [String(timed_effect.get("name", "POWER-UP")), maxf(powerup_time_left, 0.0)])
	powerup_label.text = "\n".join(lines)
	powerup_label.visible = not lines.is_empty()


# ---------------------------------------------------------------- CHEAT "morais": skin de rato
func _apply_cheat_skin() -> void:
	if not GameSettings.cheat_rat:
		return
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	var idle: Array = ["giant_rat_idle_0", "giant_rat_idle_1"]
	var walk: Array = ["giant_rat_walk_0", "giant_rat_walk_1"]
	_add_rat_animation(frames, &"idle", idle, 3.0)
	_add_rat_animation(frames, &"run", walk, 8.0)
	_add_rat_animation(frames, &"jump", walk, 6.0)
	sprite.sprite_frames = frames
	sprite.scale = Vector2(1.5, 1.5)
	# Pés do rato alinhados com a base da hitbox do jogador.
	sprite.position = Vector2(body_shape.position.x, body_shape.position.y + 18.5 - 15.0 * 1.5)
	sprite.play(&"idle")


func _add_rat_animation(frames: SpriteFrames, anim: StringName, names: Array, fps: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, true)
	for n in names:
		var path := "res://sprites/inimigos/rat/%s.png" % n
		if ResourceLoader.exists(path):
			frames.add_frame(anim, load(path))


func die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	if footsteps:
		footsteps.stop()
	set_physics_process(false)
	_show_end_panel(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not dead:
		get_tree().paused = not get_tree().paused
		if get_tree().paused:
			_show_pause_panel()
		else:
			_remove_panel()

func _show_pause_panel() -> void:
	_show_panel("JOGO PAUSADO", "CONTINUAR", "REINICIAR FASE", "MENU", false)

func _show_end_panel(is_death: bool) -> void:
	_show_panel("VOCÊ MORREU", "RECOMEÇAR", "ÚLTIMO CHECKPOINT", "MENU", true)

func _show_panel(title_text: String, first_text: String, second_text: String, third_text: String, is_death: bool) -> void:
	var layer := CanvasLayer.new()
	layer.name = "GameOverlay"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.01, 0.08, 0.92)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.position = Vector2(-180, -140)
	box.size = Vector2(360, 280)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	for entry in [[first_text, 0], [second_text, 1], [third_text, 2]]:
		var b := Button.new()
		b.text = entry[0]
		box.add_child(b)
		b.pressed.connect(_on_overlay_choice.bind(entry[1], is_death))
	if is_death:
		get_tree().paused = true

func _on_overlay_choice(choice: int, is_death: bool) -> void:
	if not is_death and choice == 0:
		get_tree().paused = false
		_remove_panel()
		return
	if choice == 0 or choice == 1:
		if choice == 1 and PlayerData.current_checkpoint != Vector2.ZERO and PlayerData.checkpoint_scene == get_tree().current_scene.scene_file_path:
			get_tree().paused = false
			get_tree().reload_current_scene()
			return
		if is_death:
			PlayerData.current_checkpoint = Vector2.ZERO
			PlayerData.checkpoint_scene = ""
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif choice == 2:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://Menu.tscn")

func _remove_panel() -> void:
	var overlay := get_node_or_null("GameOverlay")
	if overlay:
		overlay.queue_free()
