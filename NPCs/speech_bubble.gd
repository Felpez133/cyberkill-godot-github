extends Node2D
## Balão de fala reutilizável (cena NPCs/speech_bubble.tscn).
##
## Fica em cima da cabeça do NPC. O texto padrão "..." é só um marcador: escreva o que quiser em
## "Text" no Inspector, ou controle por código:
##     $SpeechBubble.say("Olá!")         # mostra até chamar hide_bubble()
##     $SpeechBubble.say("Olá!", 3.0)    # mostra e some sozinho depois de 3 segundos
##     $SpeechBubble.hide_bubble()
## Para mudar a cor, a fonte ou o formato do balão, edite o nó Label (Theme Overrides) na cena.

@export_multiline var text: String = "...":
	set(value):
		text = value
		_refresh()
## Largura máxima do balão em pixels. Textos maiores quebram em mais linhas.
@export var max_width: float = 180.0
## Altura (px) do "rabinho" que aponta para o NPC.
@export var tail_height: float = 9.0

@onready var label: Label = $Label
@onready var tail: Polygon2D = $Label/Tail

var _token := 0


func _ready() -> void:
	_refresh()


func say(new_text: String, duration: float = 0.0) -> void:
	text = new_text
	show()
	_token += 1
	if duration > 0.0:
		var my_token := _token
		await get_tree().create_timer(duration).timeout
		if my_token == _token and is_inside_tree():
			hide()


func hide_bubble() -> void:
	_token += 1
	hide()


func _refresh() -> void:
	if not is_node_ready():
		return
	label.text = text
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var natural := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var style := label.get_theme_stylebox("normal")
	var padding := style.get_minimum_size().x if style != null else 0.0
	label.custom_minimum_size = Vector2(minf(natural + padding + 2.0, max_width), 0.0)
	label.reset_size()
	_place.call_deferred()


# Centraliza o balão em cima da origem deste nó e encaixa o rabinho embaixo.
func _place() -> void:
	if not is_inside_tree():
		return
	label.reset_size()
	label.position = Vector2(-label.size.x * 0.5, -label.size.y - tail_height)
	tail.position = Vector2(label.size.x * 0.5, label.size.y - 2.0)
