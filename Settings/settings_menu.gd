extends CanvasLayer
## Tela de Configurações (Settings/settings_menu.tscn).
## Volume geral e volume da música (arraste a barra OU digite o número) e campo de cheats.
## Abra com: add_child(preload("res://Settings/settings_menu.tscn").instantiate())

signal closed

@onready var master_slider: HSlider = %MasterSlider
@onready var master_spin: SpinBox = %MasterSpin
@onready var music_slider: HSlider = %MusicSlider
@onready var music_spin: SpinBox = %MusicSpin
@onready var cheat_input: LineEdit = %CheatInput
@onready var cheat_apply: Button = %CheatApply
@onready var cheat_status: Label = %CheatStatus
@onready var back_button: Button = %BackButton

var _syncing := false


func _ready() -> void:
	_syncing = true
	master_slider.value = GameSettings.master_volume
	master_spin.value = GameSettings.master_volume
	music_slider.value = GameSettings.music_volume
	music_spin.value = GameSettings.music_volume
	_syncing = false
	master_slider.value_changed.connect(_on_master_changed)
	master_spin.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	music_spin.value_changed.connect(_on_music_changed)
	cheat_input.text_submitted.connect(_on_cheat_submitted)
	cheat_apply.pressed.connect(_on_cheat_apply_pressed)
	back_button.pressed.connect(_close)
	cheat_status.text = GameSettings.active_cheats_text()
	back_button.grab_focus()


func _on_master_changed(value: float) -> void:
	if _syncing:
		return
	_syncing = true
	master_slider.value = value
	master_spin.value = value
	_syncing = false
	GameSettings.set_master_volume(value)


func _on_music_changed(value: float) -> void:
	if _syncing:
		return
	_syncing = true
	music_slider.value = value
	music_spin.value = value
	_syncing = false
	GameSettings.set_music_volume(value)


func _on_cheat_submitted(text: String) -> void:
	var message := GameSettings.apply_cheat(text)
	cheat_input.clear()
	cheat_status.text = message + "\n" + GameSettings.active_cheats_text()


func _on_cheat_apply_pressed() -> void:
	_on_cheat_submitted(cheat_input.text)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not cheat_input.has_focus():
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()
