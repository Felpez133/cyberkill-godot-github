extends CharacterBody2D
## Rato de ambiente. Não causa dano e não ataca.
## Anda em UM só sentido (sem voltar) e desaparece ao chegar à "borda do mapa":
##  - WallRay (RayCast2D horizontal): detecta parede/limite sólido à frente;
##  - FloorRay (RayCast2D para baixo, à frente): detecta o fim do chão.
## Se um dos dois indicar borda, o rato para, some com um fade e é removido da cena.
## Não usa coordenadas fixas: funciona em qualquer ponto de qualquer mapa.

## Sentido do movimento (1 = direita, -1 = esquerda).
@export_enum("Direita:1", "Esquerda:-1") var direction: int = -1
@export var speed: float = 70.0
## Alcance do raio horizontal que procura parede à frente.
@export var wall_check_distance: float = 10.0
## Distância à frente do corpo em que o raio do chão é lançado.
@export var floor_check_offset: float = 16.0
## Quanto o raio do chão desce. Se não achar chão, é a borda.
@export var floor_check_depth: float = 20.0
@export var fade_time: float = 0.35
## Se o rato ficar sem avançar por este tempo (preso), ele também desaparece.
@export var stuck_timeout: float = 1.5

var vanishing := false
var stuck_timer := 0.0
var last_x := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_ray: RayCast2D = $WallRay
@onready var floor_ray: RayCast2D = $FloorRay


func _ready() -> void:
	var dir := _dir()
	sprite.flip_h = dir < 0.0
	wall_ray.position = Vector2(dir * 12.0, -8.0)
	wall_ray.target_position = Vector2(dir * wall_check_distance, 0.0)
	floor_ray.position = Vector2(dir * floor_check_offset, -4.0)
	floor_ray.target_position = Vector2(0.0, floor_check_depth)
	last_x = global_position.x
	sprite.play(&"walk")


func _dir() -> float:
	return 1.0 if direction >= 0 else -1.0


func _physics_process(delta: float) -> void:
	if vanishing:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity.x = _dir() * speed
	move_and_slide()

	if not is_on_floor():
		stuck_timer = 0.0
		return

	wall_ray.force_raycast_update()
	floor_ray.force_raycast_update()
	if wall_ray.is_colliding() or not floor_ray.is_colliding() or is_on_wall():
		_vanish()
		return

	# Segurança: se não avançou quase nada, está preso.
	if absf(global_position.x - last_x) < speed * delta * 0.25:
		stuck_timer += delta
		if stuck_timer >= stuck_timeout:
			_vanish()
	else:
		stuck_timer = 0.0
	last_x = global_position.x


func _vanish() -> void:
	if vanishing:
		return
	vanishing = true
	velocity = Vector2.ZERO
	sprite.stop()
	var body_collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_collision != null:
		body_collision.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(queue_free)
