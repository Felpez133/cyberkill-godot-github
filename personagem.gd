extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -400.0
const PROJECTILE_SCENE := preload("res://projectile.tscn")
const ARMED_SPRITES := {
	"armed_idle": ["res://sprites/guns/1 Characters/1 Biker/Idle1.png", 4, 5.0],
	"armed_run": ["res://sprites/guns/1 Characters/1 Biker/Run1.png", 6, 10.0],
	"armed_jump": ["res://sprites/guns/1 Characters/1 Biker/Jump1.png", 4, 7.0]
}

@export var max_health: int = 5
@export var body_left_offset: float = 16.0
@export var attack_left_offset: float = 500.0
@export var projectile_speed: float = 520.0
@export var shot_cooldown: float = 0.35

var health: int = 5
var is_attacking := false
var invulnerability_time := 0.0
var near_portal := false
var facing := 1.0
var shot_timer := 0.0
var attack_timer := 0.0
var dead := false
var original_body_x: float
var original_attack_x: float

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
	_setup_armed_animations()
	original_body_x = body_shape.position.x
	original_attack_x = attack_area.position.x
	attack_shape.disabled = true
	update_health_display()
	if PlayerData.current_checkpoint != Vector2.ZERO and PlayerData.checkpoint_scene == get_tree().current_scene.scene_file_path:
		global_position = PlayerData.current_checkpoint

func _setup_armed_animations() -> void:
	sprite.sprite_frames = sprite.sprite_frames.duplicate()
	for animation_name in ARMED_SPRITES:
		sprite.sprite_frames.add_animation(animation_name)
		var texture: Texture2D = load(ARMED_SPRITES[animation_name][0])
		var frame_count: int = ARMED_SPRITES[animation_name][1]
		for i in range(frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * 48, 0, 48, 48)
			sprite.sprite_frames.add_frame(animation_name, atlas)
		sprite.sprite_frames.set_animation_speed(animation_name, ARMED_SPRITES[animation_name][2])
		sprite.sprite_frames.set_animation_loop(animation_name, true)

func _physics_process(delta: float) -> void:
	if dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if invulnerability_time > 0.0:
		invulnerability_time -= delta
		sprite.visible = int(Time.get_ticks_msec() / 90) % 2 == 0
	else:
		sprite.visible = true
	if shot_timer > 0.0:
		shot_timer -= delta
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		update_facing(direction)
	if Input.is_action_just_pressed("move_up") and is_on_floor() and not near_portal:
		velocity.y = JUMP_VELOCITY
	if PlayerData.has_weapon:
		if Input.is_action_just_pressed("attack") and shot_timer <= 0.0:
			shoot()
		velocity.x = direction * SPEED
		if not is_on_floor():
			play_animation("armed_jump")
		elif direction != 0:
			play_animation("armed_run")
		else:
			play_animation("armed_idle")
	else:
		if Input.is_action_just_pressed("attack") and not is_attacking:
			is_attacking = true
			sprite.play("attack")
			attack_shape.set_deferred("disabled", false)
		velocity.x = direction * SPEED
		if is_attacking:
			if direction != 0 and sprite.sprite_frames.has_animation("walking_attack"):
				play_animation("walking_attack")
			elif sprite.animation != "attack":
				sprite.play("attack")
		elif not is_on_floor():
			play_animation("jump")
		elif direction != 0:
			play_animation("run")
		else:
			play_animation("idle")
	move_and_slide()
	if footsteps:
		if is_on_floor() and abs(velocity.x) > 10 and not dead:
			if not footsteps.playing: footsteps.play()
		else:
			footsteps.stop()

func update_facing(direction: float) -> void:
	facing = sign(direction)
	sprite.flip_h = facing < 0
	body_shape.position.x = -original_body_x - body_left_offset if facing < 0 else original_body_x
	attack_area.position.x = -original_attack_x if facing < 0 else original_attack_x

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
	if dead: return
	dead = true
	velocity = Vector2.ZERO
	if footsteps: footsteps.stop()
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
	if overlay: overlay.queue_free()
