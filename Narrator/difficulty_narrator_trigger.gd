extends "res://Narrator/narrator_trigger.gd"
## GATILHO DE DICA POR DIFICULDADE (Narrator/difficulty_narrator_trigger.tscn).
## Usa a mesma narradora (Narrator.say) do narrator_trigger, mas com falas diferentes:
##   Lines Easy   -> FÁCIL: tutorial explicativo, ensina a mecânica passo a passo.
##   Lines Medium -> MÉDIO: só uma introdução curta do que é aquele objeto/mecânica.
## Deixe uma das listas vazia para não mostrar nada naquela dificuldade.
## Dê um "Narration Id" único: a dica só aparece uma vez por campanha.

@export var lines_easy: PackedStringArray = PackedStringArray()
@export var lines_medium: PackedStringArray = PackedStringArray()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var chosen := lines_easy if Difficulty.is_easy() else lines_medium
	if chosen.is_empty():
		return
	Narrator.say(Array(chosen), narration_id)
