extends Node2D
## NPC parado: toca a animação "idle" em loop, não se move e não ataca.
## Para trocar a aparência: selecione o nó AnimatedSprite2D, abra o painel SpriteFrames
## (Inspector > Sprite Frames) e troque as imagens da animação "idle".
##
## BALÃO DE FALA: cada NPC tem um nó filho "SpeechBubble" (NPCs/speech_bubble.tscn).
##  - "Bubble Text": o que aparece no balão (padrão "..." até você escrever algo).
##  - "Bubble Visible": desmarque para o balão começar escondido.
##  - Por código: npc.say("Olá!"), npc.say("Olá!", 3.0) (some depois de 3 s) e npc.hide_bubble().

## Marque para o NPC olhar para a esquerda.
@export var face_left: bool = false
@export var idle_animation: StringName = &"idle"
@export_group("Balão de fala")
@export_multiline var bubble_text: String = "..."
@export var bubble_visible: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bubble: Node2D = get_node_or_null("SpeechBubble") as Node2D


func _ready() -> void:
	sprite.flip_h = face_left
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(idle_animation):
		sprite.play(idle_animation)
	if bubble != null:
		bubble.set("text", bubble_text)
		bubble.visible = bubble_visible


func say(text: String, duration: float = 0.0) -> void:
	if bubble != null:
		bubble.call("say", text, duration)


func hide_bubble() -> void:
	if bubble != null:
		bubble.call("hide_bubble")
