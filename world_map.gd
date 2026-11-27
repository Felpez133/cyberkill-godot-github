
extends Node2D

# Falas da narradora ao chegar na cidade.
const CITY_INTRO: Array = [
	"Ei, Biker... você chegou. Bem-vindo à cidade. Eu sou a sua narradora e vou te acompanhar daqui em diante.",
	"Os portais antigos da rua estão desligados. O caminho agora é pela porta do prédio, logo à frente.",
	"Chegue perto dela e aperte E. Lá dentro ficam os acessos às fases. Algumas coisas por aí só respondem à tecla E: caixas, pendrives, botões...",
	"Pronto para começar? Então vamos nessa.",
]

# Falas da narradora ao VOLTAR de uma fase (botão que leva de volta à cidade). Edite à vontade.
const CITY_RETURN: Array = [
	"Você voltou, Biker. O núcleo da IA foi desligado e a cidade respira mais aliviada.",
	"Isso foi só o começo. A IA não vai ficar parada, e ainda existem outros núcleos por aí.",
	"Descanse um pouco. Quando estiver pronto, a porta do prédio continua à sua espera.",
]


func _ready() -> void:
	_play_narrator_intro()


func _play_narrator_intro() -> void:
	await get_tree().create_timer(0.8).timeout

	if not is_inside_tree():
		return
	if PlayerData.returned_from_level:
		PlayerData.returned_from_level = false
		Narrator.say(CITY_RETURN)
	else:
		Narrator.say(CITY_INTRO, "city_intro")
