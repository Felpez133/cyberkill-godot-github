extends Area2D
## Projétil do tanque (Enemies/enemy_bullet.tscn).
## Anda em linha reta, machuca o jogador ao encostar e some ao bater em parede/chão.
## Não machuca outros inimigos.

@export var speed := 260.0
@export var damage := 1
@export var lifetime := 2.5

var direction := Vector2.RIGHT


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
