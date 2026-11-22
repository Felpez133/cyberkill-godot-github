extends Area2D

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	animation.play("explosion")
	sound.play()

func _on_animated_sprite_2d_animation_finished() -> void:
	queue_free()
