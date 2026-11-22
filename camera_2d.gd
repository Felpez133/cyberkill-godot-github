
extends Camera2D

@export var tempo_para_ativar: float = 4.0
@export var altura_extra: float = 250.0
@export var velocidade_normal: float = 5.0
@export var velocidade_queda: float = 8.0

var tempo_caindo: float = 0.0
var offset_original: Vector2


func _ready() -> void:
	offset_original = offset


func _process(delta: float) -> void:
	var personagem = get_parent()

	if not personagem is CharacterBody2D:
		return

	if personagem.velocity.y > 0:
		tempo_caindo += delta
	else:
		tempo_caindo = 0.0

	var alvo = offset_original
	var velocidade = velocidade_normal

	if tempo_caindo >= tempo_para_ativar:
		alvo.y += altura_extra
		velocidade = velocidade_queda

	offset = offset.lerp(
		alvo,
		clamp(velocidade * delta, 0.0, 1.0)
	)
