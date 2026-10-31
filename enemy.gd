
extends CharacterBody2D

@export var speed: float = 90.0
@export var max_health: int = 3
@export var contact_damage: int = 1
@export var contact_range: float = 28.0
@export var damage_cooldown: float = 1.0

var health: int = 3
var player: Node2D = null
var damage_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $Area2D


func _ready() -> void:
	health = max_health

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	sprite.play("idle")


func _physics_process(delta: float) -> void:

	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Tempo entre danos
	if damage_timer > 0:
		damage_timer -= delta

	# Perseguição
	if is_instance_valid(player):

		# Calcula a distância entre Enemy e Player
		var distance_x = player.global_position.x - global_position.x

		# Descobre a direção do jogador
		var direction = 0

		if distance_x > 0:
			direction = 1
		else:
			direction = -1

		# Verifica se o jogador está longe
		if abs(distance_x) > contact_range:

			velocity.x = direction * speed

			sprite.flip_h = direction < 0

			if sprite.animation != "run":
				sprite.play("run")

		else:

			velocity.x = 0

			if sprite.animation != "idle":
				sprite.play("idle")

			# Causar dano ao jogador
			if damage_timer <= 0:
				if player.has_method("take_damage"):
					player.take_damage(contact_damage)
					damage_timer = damage_cooldown

	else:
		velocity.x = 0

		if sprite.animation != "idle":
			sprite.play("idle")

	move_and_slide()


func _on_body_entered(body: Node2D) -> void:
	print("OBJETO DETECTADO: ", body.name)
	print("ESTÁ NO GRUPO PLAYER? ", body.is_in_group("player"))

	if body.is_in_group("player"):
		player = body
		print("JOGADOR REGISTRADO: ", player.name)


func _on_body_exited(body: Node2D) -> void:

	if body == player:
		print("JOGADOR SAIU DA ÁREA!")
		player = null


func take_damage(amount: int) -> void:

	health -= amount

	print("ROBÔ RECEBEU DANO!")
	print("Vida do robô: ", health)

	if health <= 0:
		queue_free()
