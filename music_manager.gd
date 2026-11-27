extends Node
## Música de fundo contínua (autoload "MusicManager").
##
## A música toca nas cenas listadas em MUSIC_SCENES e NÃO reinicia ao trocar entre elas
## (cidade -> prédio/seletor de fases -> fase 1, morrer e recarregar a fase, etc.).
## Ao ir para uma cena que não está na lista (menu, prólogo, tutorial), ela some com fade.
## Para a música tocar em outra cena, acrescente o caminho da cena em MUSIC_SCENES.

const MUSIC_PATH := "res://sounds/BackgroundMusic/Endless Cyber Runner.mp3"
const MUSIC_SCENES: Array[String] = [
	"res://node_2d.tscn",
	"res://WorldMap.tscn",
	"res://BuildingInterior.tscn",
	"res://Level01Entrance.tscn",
	"res://level_2.tscn",
	"res://WorldSelect.tscn",
]
const TARGET_VOLUME_DB := -3.5
const SILENT_DB := -40.0
const FADE_TIME := 0.8

var player: AudioStreamPlayer
var tween: Tween
var last_scene: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.name = "Music"
	# Barramento "Music" criado pelo GameSettings (slider de música nas Configurações).
	player.bus = GameSettings.MUSIC_BUS if AudioServer.get_bus_index(GameSettings.MUSIC_BUS) != -1 else "Master"
	if ResourceLoader.exists(MUSIC_PATH):
		var stream := load(MUSIC_PATH)
		if stream is AudioStreamMP3:
			stream.loop = true
		player.stream = stream
	add_child(player)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene == last_scene:
		return
	last_scene = scene
	if MUSIC_SCENES.has(scene.scene_file_path):
		play_music()
	else:
		stop_music()


func play_music() -> void:
	if player == null or player.stream == null:
		return
	if tween:
		tween.kill()
	if not player.playing:
		player.volume_db = SILENT_DB
		player.play()
	tween = create_tween()
	tween.tween_property(player, "volume_db", TARGET_VOLUME_DB, FADE_TIME)


func stop_music() -> void:
	if player == null or not player.playing:
		return
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(player, "volume_db", SILENT_DB, FADE_TIME)
	tween.tween_callback(player.stop)
