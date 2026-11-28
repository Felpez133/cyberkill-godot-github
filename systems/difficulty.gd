class_name Difficulty
extends RefCounted
## GERENCIADOR CENTRAL DE DIFICULDADE (FÁCIL / MÉDIO).
##
## A escolha fica em PlayerData.difficulty (guardada durante a campanha e zerada em
## PlayerData.new_game()). Tudo que depende de dificuldade pergunta aqui — não leia
## PlayerData.difficulty direto em outros scripts.
##
## Para ajustar o balanceamento, mexa só nas constantes abaixo.

enum Mode { EASY, MEDIUM }

## Fase 1: FÁCIL usa o mapa menor (level-1-cut.tscn); MÉDIO usa o mapa completo.
const LEVEL1_MEDIUM := "res://Level01Entrance.tscn"
const LEVEL1_EASY := "res://level-1-cut.tscn"

## Multiplicador da vida dos inimigos comuns (MÉDIO = vida padrão da cena do inimigo).
const ENEMY_HEALTH_EASY := 0.6
const ENEMY_HEALTH_MEDIUM := 1.0


static func current() -> int:
	return PlayerData.difficulty


static func set_mode(mode: int) -> void:
	PlayerData.difficulty = clampi(mode, Mode.EASY, Mode.MEDIUM)


static func is_easy() -> bool:
	return PlayerData.difficulty == Mode.EASY


static func mode_name() -> String:
	return "FÁCIL" if is_easy() else "MÉDIO"


## Vida de um inimigo comum já ajustada à dificuldade (nunca menos de 1).
static func scaled_enemy_health(base_health: int) -> int:
	var factor := ENEMY_HEALTH_EASY if is_easy() else ENEMY_HEALTH_MEDIUM
	return maxi(1, int(ceil(base_health * factor)))


## Bosses: FÁCIL tem só a fase 1 da luta; MÉDIO tem duas fases.
static func boss_has_second_phase() -> bool:
	return not is_easy()


## Setas de orientação: tier 0 = essencial (aparece nas duas dificuldades);
## tier 1 = extra (aparece só no FÁCIL).
static func shows_arrow(tier: int) -> bool:
	return tier <= 0 or is_easy()


## Se a cena de fase 1 pedida deve ser trocada pela da dificuldade atual.
static func resolve_scene(scene_path: String) -> String:
	if scene_path == LEVEL1_MEDIUM or scene_path == LEVEL1_EASY:
		return LEVEL1_EASY if is_easy() else LEVEL1_MEDIUM
	return scene_path
