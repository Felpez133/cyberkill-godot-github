extends "res://PowerUps/powerup_pickup.gd"
## Power-up ALEATÓRIO (cena: PowerUps/powerup_randon.tscn).
## Sorteia uma habilidade e avisa qual foi. Cada habilidade tem o seu ponto fraco/forte.
## Para mudar números ou criar habilidades novas, edite a lista ABILITIES abaixo.
## Chaves aceitas: name, desc, speed (multiplicador), jump (multiplicador), damage (multiplicador),
## one_hit_kill (true/false).

const ABILITIES: Array[Dictionary] = [
	{
		"id": "hitkill",
		"name": "TIRO HITKILL",
		"desc": "Cada tiro seu mata qualquer inimigo na hora.",
		"one_hit_kill": true,
	},
	{
		"id": "fast",
		"name": "VELOCIDADE +",
		"desc": "Você corre muito mais rápido, mas seus tiros causam metade do dano.",
		"speed": 1.6,
		"damage": 0.5,
	},
	{
		"id": "strong",
		"name": "DANO +",
		"desc": "Seus tiros causam o dobro de dano, mas você anda mais devagar.",
		"damage": 2.0,
		"speed": 0.65,
	},
	{
		"id": "superjump",
		"name": "SUPER PULO",
		"desc": "Você pula muito mais alto.",
		"jump": 1.7,
	},
]


func _run() -> void:
	var dialog := _new_dialog()
	var lines := ""
	for ability in ABILITIES:
		lines += "•  %s — %s\n" % [ability["name"], ability["desc"]]
	dialog.open(
		"POWER-UP  //  ALEATÓRIO",
		"AVISO: este power-up sorteia UMA habilidade que dura a partida inteira. Algumas têm ponto fraco:\n\n%s\nVocê pode recusar e deixar o power-up onde está." % lines,
		"SORTEAR",
		"RECUSAR"
	)
	var accepted: bool = await dialog.answered
	if not accepted:
		dialog.close()
		return

	# Roleta: passa pelos nomes e para na habilidade sorteada.
	var chosen: Dictionary = ABILITIES[randi() % ABILITIES.size()]
	dialog.open("SORTEANDO...", "", "", "")
	var steps := 16
	for i in range(steps):
		dialog.set_body(">>  " + String(ABILITIES[i % ABILITIES.size()]["name"]))
		await get_tree().create_timer(0.07 + 0.012 * i, true).timeout
	dialog.open(
		"VOCÊ GANHOU: " + String(chosen["name"]),
		"%s\n\nO efeito dura a partida inteira e começa quando você fechar este aviso." % chosen["desc"],
		"ENTENDI"
	)
	await dialog.answered
	dialog.close()
	var effect := chosen.duplicate()
	effect["duration"] = 0.0  # 0 = permanente (só a VIDA INFINITA tem timer)
	_give(effect)
