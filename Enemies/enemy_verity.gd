extends "res://Enemies/enemy_base.gd"
## VERITY — inimigo da Fase 1 (Enemies/enemy_verity.tscn).
## Usa tudo do inimigo base (patrulha, perseguição, vida, recuo ao encostar, dano de contato).
## A arte do Verity são 3 imagens: de frente (parado), olhando para a esquerda e para a direita
## (andando). Por isso aqui a "virada" troca a textura em vez de espelhar o sprite.

const TEX_FRONT: Texture2D = preload("res://sprites/inimigos/verity/verity-front.png")
const TEX_LEFT: Texture2D = preload("res://sprites/inimigos/verity/verity-left.png")
const TEX_RIGHT: Texture2D = preload("res://sprites/inimigos/verity/verity-rigth.png")

## Altura (px) do quiquinho enquanto anda. Use 0 para desligar.
@export var bounce_height: float = 3.0
@export var bounce_speed: float = 14.0

var _look_texture: Texture2D = TEX_RIGHT
var _sprite_base_y := 0.0
var _bounce_time := 0.0


func _ready() -> void:
	super()
	if plain_sprite != null:
		_sprite_base_y = plain_sprite.position.y
		plain_sprite.texture = TEX_FRONT


func _set_facing(dir: float) -> void:
	if dir == 0.0:
		return
	face_direction = dir
	_look_texture = TEX_RIGHT if dir > 0.0 else TEX_LEFT


func _update_animation() -> void:
	if plain_sprite == null:
		return
	var moving := recoil_timer > 0.0 or absf(velocity.x) > 1.0
	if moving:
		plain_sprite.texture = _look_texture
		_bounce_time += get_physics_process_delta_time() * bounce_speed
		plain_sprite.position.y = _sprite_base_y - absf(sin(_bounce_time)) * bounce_height
	else:
		plain_sprite.texture = TEX_FRONT
		plain_sprite.position.y = _sprite_base_y
		_bounce_time = 0.0
