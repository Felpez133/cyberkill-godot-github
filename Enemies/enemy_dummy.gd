extends CharacterBody2D
## DUMMY DO TUTORIAL — boneco de treino (cena: Enemies/enemy_dummy_tutorial.tscn).
## É independente do BB9 (enemy.tscn / enemy_base.gd): mexer em um não afeta o outro.
##
## Estados (AnimatedSprite2D com os sprites de sprites/inimigos/dummy):
##   idle      -> parado (IDLE.png)
##   hit       -> levou um acerto (HIT.png); depois volta para idle
##   breaking  -> acertou o limite de acertos (BREAKING.png): toca UMA vez e fica quebrado no chão
## Morre depois de "Max Hits" acertos (padrão 6 tiros), não importa o dano de cada tiro.

signal hit(hits_taken: int)
signal died

@export var max_hits: int = 6
## Segundos em que acertos repetidos são ignorados (evita contar o mesmo tiro duas vezes).
@export var hit_lockout: float = 0.05

var hits_taken := 0
var _dying := false
var _lockout := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("enemy")
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"idle")


func _physics_process(delta: float) -> void:
	_lockout = maxf(0.0, _lockout - delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity.x = 0.0
	move_and_slide()


## Chamado pelos tiros (projectile.gd), pelo golpe e pelo dash do jogador (grupo "enemy").
func take_damage(_amount: float = 1.0) -> void:
	if _dying or _lockout > 0.0:
		return
	_lockout = hit_lockout
	hits_taken += 1
	hit.emit(hits_taken)
	if hits_taken >= max_hits:
		_die()
	else:
		sprite.play(&"hit")


func _on_animation_finished() -> void:
	if _dying:
		return # a animação de morte termina no último quadro e fica lá
	if sprite.animation == &"hit":
		sprite.play(&"idle")


func _die() -> void:
	_dying = true
	remove_from_group("enemy")
	# Quebrado: sem colisão e sem física, para não ser mais atingido nem se mexer.
	body_shape.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	set_physics_process(false)
	velocity = Vector2.ZERO
	sprite.play(&"breaking")
	PlayerData.register_kill()
	get_tree().call_group("enemy_labels", "on_enemy_died", self)
	for child in get_children():
		if child is Label:
			child.hide()
	died.emit()
