extends Area2D
## Gatilho da narradora: arraste Narrator/narrator_trigger.tscn para a fase.
## Escreva as falas em "Lines" e dê um "Narration Id" único (assim ela só fala uma vez).

@export var lines: PackedStringArray = PackedStringArray()
@export var narration_id: String = ""
@export var size: Vector2 = Vector2(300, 300)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null:
		var shape := RectangleShape2D.new()
		shape.size = size
		shape_node.shape = shape
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	Narrator.say(Array(lines), narration_id)
