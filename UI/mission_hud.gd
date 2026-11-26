extends CanvasLayer
## Lista de missões da fase, no canto superior esquerdo (cena UI/mission_hud.tscn).
##
## Para usar em uma fase: arraste UI/mission_hud.tscn para dentro dela (já está na fase 1).
## Enquanto esta lista existir na cena, o progresso das missões é contado (PlayerData).
##
## Como cada missão é concluída:
##  - nucleo_ia      -> um botão (button.tscn) com "Mission Id" = nucleo_ia é ativado com E.
##  - chip_walljump  -> o pendrive do Wall Jump é pego (personagem.gd > unlock_wall_jump()).
##  - bonus_inimigos -> o jogador derrota PlayerData.KILL_GOAL (15) inimigos (enemy_base.gd).
## Para editar os textos, mude TEXTS abaixo. Para mudar o visual (fonte, cores, tamanho,
## posição), edite os nós na cena. As cores de estado ficam nos exports abaixo.

@export var pending_color := Color(1.0, 1.0, 1.0, 1.0)
@export var bonus_color := Color(1.0, 0.85, 0.35, 1.0)
@export var done_color := Color(0.45, 1.0, 0.6, 1.0)

const TEXTS := {
	"nucleo_ia": "Desligar um núcleo da IA",
	"chip_walljump": "Encontrar o chip de Wall Jump",
	"bonus_inimigos": "BÔNUS: Derrotar inimigos",
}

@onready var rows := {
	"nucleo_ia": $Margin/Panel/Box/NucleoIA,
	"chip_walljump": $Margin/Panel/Box/ChipWallJump,
	"bonus_inimigos": $Margin/Panel/Box/BonusInimigos,
}


func _enter_tree() -> void:
	PlayerData.missions_tracking = true


func _exit_tree() -> void:
	PlayerData.missions_tracking = false


func _ready() -> void:
	PlayerData.missions_changed.connect(_on_missions_changed)
	_refresh()


func _on_missions_changed(completed_id: String) -> void:
	_refresh()
	if completed_id != "" and rows.has(completed_id):
		var label: Label = rows[completed_id]
		label.modulate = Color(2.2, 2.2, 2.2, 1.0)
		create_tween().tween_property(label, "modulate", Color.WHITE, 0.9)


func _refresh() -> void:
	for id in rows:
		var label: Label = rows[id]
		var done: bool = PlayerData.missions_done.get(id, false)
		var text: String = TEXTS[id]
		if id == "bonus_inimigos":
			text += " (%d/%d)" % [mini(PlayerData.enemies_killed, PlayerData.KILL_GOAL), PlayerData.KILL_GOAL]
		label.text = ("[X]  " if done else "[   ]  ") + text
		var color := bonus_color if id == "bonus_inimigos" else pending_color
		label.add_theme_color_override("font_color", done_color if done else color)
