extends Node
## Configurações do jogo (autoload "GameSettings"):
##  - volume geral (barramento Master) e volume da música (barramento "Music", criado aqui);
##  - cheats digitados na tela de Configurações do menu.
##
## Volumes ficam salvos em user://cyberkill_settings.cfg. Os cheats valem só enquanto o jogo
## está aberto (não são salvos).
##
## Cheats:
##   morais -> a skin do jogador vira um rato (digite de novo para voltar ao normal)
##   infi   -> o jogador fica invencível (digite de novo para desligar)

signal settings_changed
signal cheats_changed

const SAVE_PATH := "user://cyberkill_settings.cfg"
const MUSIC_BUS := "Music"

## Volumes de 0 a 100.
var master_volume: float = 100.0
var music_volume: float = 100.0

var cheat_rat := false
var cheat_god := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_music_bus()
	_load()
	apply_audio()


func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index(MUSIC_BUS) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, MUSIC_BUS)
	AudioServer.set_bus_send(index, "Master")


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 100.0)
	apply_audio()
	_save()
	settings_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 100.0)
	apply_audio()
	_save()
	settings_changed.emit()


func apply_audio() -> void:
	_set_bus_percent(AudioServer.get_bus_index("Master"), master_volume)
	_set_bus_percent(AudioServer.get_bus_index(MUSIC_BUS), music_volume)


func _set_bus_percent(bus_index: int, percent: float) -> void:
	if bus_index < 0:
		return
	var linear := clampf(percent, 0.0, 100.0) / 100.0
	AudioServer.set_bus_mute(bus_index, linear <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(linear, 0.0001)))


## Aplica um código digitado. Devolve a mensagem para mostrar ao jogador.
func apply_cheat(text: String) -> String:
	var code := text.strip_edges().to_lower()
	var message := ""
	match code:
		"":
			return "Digite um código."
		"morais":
			cheat_rat = not cheat_rat
			message = "Cheat ativado: skin de rato." if cheat_rat else "Cheat desativado: skin de rato."
		"infi":
			cheat_god = not cheat_god
			message = "Cheat ativado: invencível." if cheat_god else "Cheat desativado: invencível."
		_:
			return "Código inválido."
	cheats_changed.emit()
	return message


func active_cheats_text() -> String:
	var list: Array[String] = []
	if cheat_rat:
		list.append("morais")
	if cheat_god:
		list.append("infi")
	return "Cheats ativos: " + (", ".join(list) if not list.is_empty() else "nenhum")


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master", 100.0)), 0.0, 100.0)
	music_volume = clampf(float(config.get_value("audio", "music", 100.0)), 0.0, 100.0)
