extends Node

# ==============================================================
# GAME MODES - Autoload
#
# CLASSIC: Ultimo in arena vince (last-man-standing)
# POINT:   Punteggio a tempo. +2/colpo, +6/kill, -4/morte
# KING:    King of the Hill - zona di controllo mobile.
#          +1 pt/sec nella zona, +4/kill, -2/morte
# PROGRESSION: Gun Game a tempo. +2/kill, -1/morte,
#              cambio arma a ogni kill e vittoria immediata
#              con una kill fatta usando PVP_SHOTGUN.
# ==============================================================

enum GameMode {
	CLASSIC,
	POINT,
	KING,
	PROGRESSION,
	PVE_ENDLESS
}

var current_mode: GameMode = GameMode.CLASSIC
var match_duration: int    = 480   # secondi (8 minuti default)
var time_limit_enabled: bool = true

# HP per modalità
const HP_CLASSIC:     float = 250.0
const HP_POINT:       float = 500.0
const HP_KING:        float = 100.0
const HP_PROGRESSION: float = 50.0
const HP_PVE:         float = 500.0

func get_max_hp_for_mode(mode: GameMode) -> float:
	match mode:
		GameMode.CLASSIC:     return HP_CLASSIC
		GameMode.POINT:       return HP_POINT
		GameMode.KING:        return HP_KING
		GameMode.PROGRESSION: return HP_PROGRESSION
		GameMode.PVE_ENDLESS: return HP_PVE
		_:                    return HP_CLASSIC

# Punti modalità POINT
const POINT_HIT_SCORE:   int = 2
const POINT_KILL_SCORE:  int = 6
const POINT_DEATH_SCORE: int = -4

# Punti modalità KING
const KING_ZONE_SCORE_PER_SEC: int = 1   # punti/sec per chi è nella zona
const KING_KILL_SCORE:         int = 4
const KING_DEATH_SCORE:        int = -2
const KING_ZONE_MOVE_INTERVAL: float = 30.0  # secondi prima che la zona si sposti
const KING_ZONE_RADIUS:        float = 400.0  # raggio della zona in pixel

# Punti modalità PROGRESSION
const PROGRESSION_KILL_SCORE:  int = 2
const PROGRESSION_DEATH_SCORE: int = -1

const PROGRESSION_WEAPON_ORDER: Array[String] = [
	"PVP_RAZOR",
	"PVP_BOLT",
	"PVP_SPLITTER",
	"PVP_BOUNCE",
	"PVP_PIERCE",
	"PVP_HOMING",
	"PVP_EXPLODE",
	"PVP_FREEZE",
	"PVP_MAGNET",
	"PVP_SHOTGUN",
]

const MIN_DURATION:     int = 120
const MAX_DURATION:     int = 900
const DEFAULT_DURATION: int = 480

# ------------------------------------------------------------------
# SETTERS
# ------------------------------------------------------------------

func set_mode(mode: GameMode) -> void:
	current_mode = mode

func set_duration(seconds: int) -> void:
	match_duration = clamp(seconds, MIN_DURATION, MAX_DURATION)

# ------------------------------------------------------------------
# GETTERS
# ------------------------------------------------------------------

func get_duration_minutes() -> float:
	return match_duration / 60.0

func get_mode_name() -> String:
	match current_mode:
		GameMode.CLASSIC: return "CLASSIC"
		GameMode.POINT:   return "POINT"
		GameMode.KING:    return "KING"
		GameMode.PROGRESSION: return "PROGRESSION"
	return "CLASSIC"

func get_mode_description() -> String:
	match current_mode:
		GameMode.CLASSIC:
			return "Last player standing wins"
		GameMode.POINT:
			return "+%d/hit  +%d/kill  %d/death  |  Most points wins" % [
				POINT_HIT_SCORE, POINT_KILL_SCORE, POINT_DEATH_SCORE
			]
		GameMode.KING:
			return "+%d/sec in zone  +%d/kill  %d/death  |  Zone moves every %ds" % [
				KING_ZONE_SCORE_PER_SEC, KING_KILL_SCORE, KING_DEATH_SCORE, int(KING_ZONE_MOVE_INTERVAL)
			]
		GameMode.PROGRESSION:
			return "+%d/kill  %d/death  |  Upgrade weapon every kill" % [
				PROGRESSION_KILL_SCORE, PROGRESSION_DEATH_SCORE
			]
	return ""

func is_point_mode() -> bool:
	return current_mode == GameMode.POINT

func is_classic_mode() -> bool:
	return current_mode == GameMode.CLASSIC

func is_king_mode() -> bool:
	return current_mode == GameMode.KING

func is_progression_mode() -> bool:
	return current_mode == GameMode.PROGRESSION

func is_pve_mode() -> bool:
	return current_mode == GameMode.PVE_ENDLESS

func is_score_mode() -> bool:
	return is_point_mode() or is_king_mode() or is_progression_mode()

# ------------------------------------------------------------------
# PERSISTENZA
# ------------------------------------------------------------------

func save_settings() -> void:
	var settings := {
		"mode":     current_mode,
		"duration": match_duration,
	}
	var file := FileAccess.open("user://pvp_settings.save", FileAccess.WRITE)
	if file:
		file.store_var(settings)
		file.close()

func load_settings() -> void:
	if not FileAccess.file_exists("user://pvp_settings.save"):
		return
	var file := FileAccess.open("user://pvp_settings.save", FileAccess.READ)
	if file:
		var settings = file.get_var()
		current_mode  = settings.get("mode", GameMode.CLASSIC)
		match_duration = settings.get("duration", DEFAULT_DURATION)
		file.close()
