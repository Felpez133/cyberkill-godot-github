extends Node2D
## Tutorial do CyberKill.
##
## O cenário (chão, paredes e pilares no TileMapLayer), o jogador, a caixa do Wall Jump,
## a arma e os gatilhos de diálogo agora são NÓS da cena Tutorial.tscn: abra a cena no
## editor e mova/duplique tudo visualmente. Este script cuida só dos diálogos e do fluxo.
##
## Gatilhos: filhos do nó "Triggers" (cena Tutorial/tutorial_trigger.tscn).
## Escolha a etapa de cada um no Inspector (propriedade "Stage").

var dialogue_layer: CanvasLayer
var dialogue_panel: Panel
var dialogue_title: Label
var dialogue_text: Label
var dialogue_button: Button
var pending_finish := false
var shown_stages: Dictionary = {}

func _ready() -> void:
	PlayerData.new_game()
	_connect_triggers()
	_build_dialogue_ui()
	_show_dialogue(
		"TREINAMENTO // BIKER",
		"Bem-vindo ao treinamento, Biker.\n\nUse A e D ou as setas para andar.\nUse ESPAÇO ou W para pular.\nAperte E para interagir com objetos.\n\nAvance pelo cenário para aprender as habilidades.",
		"COMEÇAR"
	)

func _connect_triggers() -> void:
	var triggers := get_node_or_null("Triggers")
	if triggers == null:
		push_warning("Tutorial: nó 'Triggers' não encontrado; os diálogos de etapa não serão ativados.")
		return
	for trigger in triggers.get_children():
		var stage = trigger.get("stage")
		if trigger is Area2D and stage != null:
			trigger.body_entered.connect(_on_trigger_entered.bind(int(stage)))

func _on_trigger_entered(body: Node2D, stage: int) -> void:
	if not body.is_in_group("player") or shown_stages.has(stage):
		return
	shown_stages[stage] = true
	match stage:
		0:
			_show_dialogue("MOVIMENTAÇÃO", "Você pode andar para a esquerda e para a direita com A/D ou as setas.\n\nPule com ESPAÇO ou W para alcançar plataformas e evitar obstáculos.", "ENTENDI")
		1:
			_show_dialogue("A CAIXA", "Encontrou uma caixa? Chegue perto e aperte E.\n\nEla vai explodir e revelar um pendrive. Chegue perto do pendrive e aperte E para pegá-lo e desbloquear o Wall Jump.", "VOU TENTAR")
		2:
			if PlayerData.has_wall_jump:
				_show_dialogue("WALL JUMP DESBLOQUEADO", "Agora encoste em uma parede e aperte ESPAÇO/W.\n\nO Biker será impulsionado para longe da parede. O salto pode ser repetido respeitando o pequeno intervalo.", "PRATICAR")
			else:
				_show_dialogue("DICA", "A habilidade Wall Jump ainda está bloqueada. Abra a caixa com E e pegue o pendrive (também com E) antes de tentar saltar nas paredes.", "CONTINUAR")
		3:
			_show_dialogue("PEGUE UMA ARMA", "A arma está logo adiante. Chegue perto e aperte E para pegá-la.\n\nSem arma, o Biker não tem ataque.", "CONTINUAR")
		4:
			_show_dialogue("ATAQUE", "Agora que você tem uma arma, clique com o botão esquerdo do mouse para disparar.\n\nBoa! O treinamento terminou. Siga para a cidade quando estiver pronto.", "IR PARA A CIDADE", true)

func _build_dialogue_ui() -> void:
	dialogue_layer = CanvasLayer.new()
	dialogue_layer.layer = 50
	dialogue_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialogue_layer)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.005, 0.008, 0.025, 0.58)
	dialogue_layer.add_child(shade)

	dialogue_panel = Panel.new()
	dialogue_panel.position = Vector2(65, 420)
	dialogue_panel.size = Vector2(1030, 245)
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style())
	dialogue_layer.add_child(dialogue_panel)

	dialogue_title = Label.new()
	dialogue_title.position = Vector2(28, 20)
	dialogue_title.size = Vector2(970, 38)
	dialogue_title.add_theme_font_size_override("font_size", 26)
	dialogue_title.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0))
	dialogue_panel.add_child(dialogue_title)

	dialogue_text = Label.new()
	dialogue_text.position = Vector2(28, 68)
	dialogue_text.size = Vector2(970, 112)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size", 18)
	dialogue_text.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	dialogue_panel.add_child(dialogue_text)

	dialogue_button = Button.new()
	dialogue_button.position = Vector2(790, 185)
	dialogue_button.size = Vector2(205, 42)
	dialogue_button.pressed.connect(_close_dialogue)
	dialogue_panel.add_child(dialogue_button)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.02, 0.07, 0.97)
	style.border_color = Color(0.05, 0.8, 1.0, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style

func _show_dialogue(title: String, message: String, button_text: String, finish: bool = false) -> void:
	pending_finish = finish
	dialogue_title.text = title
	dialogue_text.text = message
	dialogue_button.text = button_text
	dialogue_layer.show()
	get_tree().paused = true

func _close_dialogue() -> void:
	get_tree().paused = false
	dialogue_layer.hide()
	if pending_finish:
		get_tree().change_scene_to_file("res://node_2d.tscn")
