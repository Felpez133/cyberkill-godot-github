extends Node2D
## NPC parado: toca a animação "idle" em loop, não se move e não ataca.
## Para trocar a aparência: selecione o nó AnimatedSprite2D, abra o painel SpriteFrames
## (Inspector > Sprite Frames) e troque as imagens da animação "idle".

## Marque para o NPC olhar para a esquerda.
@export var face_left: bool = false
@export var idle_animation: StringName = &"idle"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	sprite.flip_h = face_left
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(idle_animation):
		sprite.play(idle_animation)
