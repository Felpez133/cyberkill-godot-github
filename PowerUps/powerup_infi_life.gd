extends "res://PowerUps/powerup_pickup.gd"
## Power-up VIDA INFINITA (cena: PowerUps/powerup_infi_life.tscn).
## Antes de começar aparece uma tela de aviso; só depois de CONFIRMAR o timer começa.
## Durante o efeito: imortal e qualquer inimigo que encostar em você morre na hora.


func _run() -> void:
	var dialog := _new_dialog()
	dialog.open(
		"POWER-UP  //  VIDA INFINITA",
		"AVISO: ao confirmar, o tempo começa a contar NA HORA.\n\nPor %d segundos você fica IMORTAL e qualquer ser que encostar em você morre instantaneamente.\nQuando o tempo acabar, o efeito termina.\n\nVocê pode recusar e deixar o power-up onde está." % int(duration),
		"COMEÇAR  (%ds)" % int(duration),
		"RECUSAR"
	)
	var accepted: bool = await dialog.answered
	dialog.close()
	if not accepted:
		return
	_give({
		"id": "infi_life",
		"name": "VIDA INFINITA",
		"duration": duration,
		"god": true,
		"touch_kill": true,
		"rainbow": true,
	})
