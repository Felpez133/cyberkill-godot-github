
extends Node2D

# Falas da narradora ao chegar na cidade.
const CITY_INTRO: Array = [
	"Ei, Biker... você chegou. Bem-vindo à cidade. Eu sou a sua narradora e vou te acompanhar daqui em diante.",
	"Os portais antigos da rua estão desligados. O caminho agora é pela porta do prédio, logo à frente.",
	"Chegue perto dela e aperte E. Lá dentro ficam os acessos às fases. Algumas coisas por aí só respondem à tecla E: caixas, pendrives, botões...",
	"Pronto para começar? Então vamos nessa.",
]


func _ready() -> void:
	_play_narrator_intro()


func _play_narrator_intro() -> void:
	await get_tree().create_timer(0.8).timeout

	if is_inside_tree():
		Narrator.say(CITY_INTRO, "city_intro")
