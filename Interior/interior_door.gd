extends Area2D
## Porta/portal interativo do interior (BuildingInterior.tscn).
## Use as cenas Interior/interior_portal.tscn (portal de fase) e
## Interior/interior_exit_door.tscn (porta de saída). Edite tudo no Inspector.

## Cena carregada ao apertar E dentro da área.
@export_file("*.tscn") var target_scene: String = ""
@export var title: String = "FASE"
@export var prompt_text: String = "E  —  ENTRAR"
## Desmarque para deixar o portal bloqueado (aparece cinza e não funciona).
@export var active: bool = true
## Duração do fade de saída (segundos).
@export var fade_time: float = 0.6

var player_inside := false

@onready var title_label: Label = get_node_or_null("TitleLabel") as Label
@onready var prompt_label: Label = get_node_or_null("PromptLabel") as Label


func _ready() -> void:
	add_to_group("interior_doors")
	if title_label != null:
		title_label.text = title
		var color := Color(0.45, 0.95, 1.0) if active else Color(0.65, 0.65, 0.72)
		title_label.add_theme_color_override("font_color", color)
	if prompt_label != null:
		if prompt_text != "":
			prompt_label.text = prompt_text
		prompt_label.hide()
	monitoring = active
	if active:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = true
	if prompt_label != null:
		prompt_label.show()
	if body.has_method("set_near_portal"):
		body.set_near_portal(true)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_inside = false
	if prompt_label != null:
		prompt_label.hide()
	if body.has_method("set_near_portal"):
		body.set_near_portal(false)
