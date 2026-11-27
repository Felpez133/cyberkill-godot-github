extends Area2D
@export var speed := 520.0
@export var damage: float = 1.0
## Se ligado (power-up TIRO HITKILL), o tiro mata o inimigo de uma vez.
var instakill := false
var direction := Vector2.RIGHT
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var timer := get_tree().create_timer(2.2)
	timer.timeout.connect(queue_free)
func _physics_process(delta: float) -> void:
	position += direction.normalized() * speed * delta
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage") and body.is_in_group("enemy"):
		body.take_damage(999999.0 if instakill else damage)
		queue_free()
	elif not body.is_in_group("player"):
		queue_free()
