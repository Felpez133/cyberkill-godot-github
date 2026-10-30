
extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@export var max_health: int = 5
var health: int = 5
var is_attacking: bool = false
var invulnerability_time: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

@onready var hearts: Array[AnimatedSprite2D] = [
	$CanvasLayer/HBoxContainer/Heart1,
	$CanvasLayer/HBoxContainer/Heart2,
	$CanvasLayer/HBoxContainer/Heart3,
	$CanvasLayer/HBoxContainer/Heart4,
	$CanvasLayer/HBoxContainer/Heart5
]


func _ready() -> void:
	health = max_health
	attack_shape.disabled = true
	update_health_display()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if invulnerability_time > 0.0:
		invulnerability_time -= delta

	# Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_attacking:
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")

	# Ataque com E (ação "attack")
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		sprite.play("attack")
		attack_shape.set_deferred("disabled", false)

	# Movimento
	if is_attacking:
		velocity.x = 0
	else:
		velocity.x = direction * SPEED

		if direction != 0:
			sprite.flip_h = direction < 0

		if not is_on_floor():
			sprite.play("jump")
		elif direction != 0:
			sprite.play("run")
		else:
			sprite.play("idle")

	move_and_slide()


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		is_attacking = false
		attack_shape.set_deferred("disabled", true)


func _on_attack_area_body_entered(body: Node2D) -> void:
	if is_attacking and body.has_method("take_damage"):
		body.take_damage(1)


func take_damage(amount: int) -> void:
	if invulnerability_time > 0.0 or health <= 0:
		return

	health = max(health - amount, 0)
	invulnerability_time = 0.8
	update_health_display()

	if health <= 0:
		die()


func update_health_display() -> void:
	for i in range(hearts.size()):
		if i < health:
			hearts[i].play("full")
		else:
			hearts[i].play("empty")


func die() -> void:
	print("O jogador morreu!")
	set_physics_process(false)
	sprite.stop()
