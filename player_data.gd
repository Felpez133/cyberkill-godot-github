extends Node

## Disparado quando o progresso das missões muda. completed_id é o id da missão que acabou de ser
## concluída ("" quando só o contador de inimigos mudou).
signal missions_changed(completed_id: String)

## Meta do bônus "derrotar inimigos" da fase 1.
const KILL_GOAL := 15

var has_weapon: bool = true
var has_wall_jump: bool = false
var current_checkpoint: Vector2 = Vector2.ZERO
var checkpoint_scene: String = ""
# Identificador do último checkpoint (nó Checkpoint) — evita repetir a animação ao recarregar a fase.
var checkpoint_id: String = ""
var world_unlocked: Array[bool] = [true, false, false, false, false]
# Dificuldade da campanha (0 = FÁCIL, 1 = MÉDIO). Escolhida no fim do tutorial; use a classe
# Difficulty (systems/difficulty.gd) para ler/consultar.
var difficulty: int = 1
# Falas da narradora já exibidas (id -> true). Zerado em new_game().
var narration_seen: Dictionary = {}
# Missões da fase. Só contam enquanto existir uma lista de missões (UI/mission_hud.tscn) na cena;
# ela liga/desliga missions_tracking sozinha. Assim o tutorial e a cidade não contam.
var missions_tracking: bool = false
# Marcado quando o jogador volta de uma fase para a cidade (muda a fala da narradora em world_map.gd).
var returned_from_level: bool = false
var missions_done: Dictionary = {}
var enemies_killed: int = 0

func new_game() -> void:
	has_weapon = false
	has_wall_jump = false
	current_checkpoint = Vector2.ZERO
	checkpoint_scene = ""
	checkpoint_id = ""
	difficulty = 1
	world_unlocked = [true, false, false, false, false]
	narration_seen = {}
	missions_done = {}
	enemies_killed = 0
	returned_from_level = false


## Libera um mundo (0 = Mundo 1, 1 = Mundo 2...). O portal do prédio acende sozinho.
func unlock_world(index: int) -> void:
	if index >= 0 and index < world_unlocked.size():
		world_unlocked[index] = true


func complete_mission(id: String) -> void:
	if not missions_tracking or missions_done.get(id, false):
		return
	missions_done[id] = true
	missions_changed.emit(id)


func register_kill() -> void:
	if not missions_tracking:
		return
	enemies_killed += 1
	missions_changed.emit("")
	if enemies_killed >= KILL_GOAL:
		complete_mission("bonus_inimigos")
