
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
	if PlayerData.current_checkpoint != Vector2.ZERO and PlayerData.checkpoint_scene == get_tree().current_scene.scene_file_path:
		global_position = PlayerData.current_checkpoint


func _physics_process(delta: float) -> void:
	if dead:
		return

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

		velocity.x = dash_direction * dash_speed
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
			velocity.y = JUMP_VELOCITY

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
			velocity.x = direction * SPEED

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
		body.take_damage(1)

func take_damage(amount: int) -> void:
	if invulnerability_time > 0.0 or health <= 0 or dead:
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
	projectile.global_position = sprite.global_position + Vector2(facing * 18.0, -2.0)
	projectile.direction = Vector2(facing, 0)
	get_tree().current_scene.add_child(projectile)

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
