extends Node
# ================================================================
# GlobalPvP — Singleton esclusivo per il PvP
# NON tocca Global.gd né GlobalStats.gd
# Aggiungilo in Project > Autoload come "GlobalPvP"
# ================================================================

const MAX_PLAYERS        := 4
const DEFAULT_HP         := 300.0
const SUDDEN_DEATH_TICK  := 10.0
const SUDDEN_DEATH_DMG   := 15.0

# ----------------------------------------------------------------
# Match settings
# ----------------------------------------------------------------
var match_mode:           String = "elimination"  # "elimination" | "timed"
var match_duration:       float  = 180.0
var sudden_death_enabled: bool   = true

# ----------------------------------------------------------------
# Stato match
# ----------------------------------------------------------------
var match_started:   bool  = false
var match_time_left: float = 0.0
var winner_peer_id:  int   = -1

# ----------------------------------------------------------------
# Dati giocatori  peer_id -> Dictionary
# ----------------------------------------------------------------
var players: Dictionary = {}

# ----------------------------------------------------------------
# Segnali
# ----------------------------------------------------------------
signal player_registered(peer_id: int)
signal player_left(peer_id: int)
signal match_state_changed(new_state: String)
signal player_died_pvp(peer_id: int)
signal winner_declared(peer_id: int)
signal hp_changed(peer_id: int, new_hp: float)

# ----------------------------------------------------------------
# State machine
# ----------------------------------------------------------------
enum MatchState { LOBBY, COUNTDOWN, PLAYING, ENDED }
var state: MatchState = MatchState.LOBBY

func set_state(new_state: MatchState) -> void:
	state = new_state
	match new_state:
		MatchState.LOBBY:     emit_signal("match_state_changed", "lobby")
		MatchState.COUNTDOWN: emit_signal("match_state_changed", "countdown")
		MatchState.PLAYING:   emit_signal("match_state_changed", "playing")
		MatchState.ENDED:     emit_signal("match_state_changed", "ended")

# ----------------------------------------------------------------
# Registrazione giocatori
# ----------------------------------------------------------------
func register_player(peer_id: int, player_name: String) -> void:
	if players.has(peer_id):
		return
	players[peer_id] = {
		"peer_id": peer_id,
		"name":    player_name,
		"hp":      DEFAULT_HP,
		"max_hp":  DEFAULT_HP,
		"kills":   0,
		"deaths":  0,
		"alive":   true,
		"ready":   false,
	}
	emit_signal("player_registered", peer_id)
	print("[GlobalPvP] Player registered: ", player_name, " (peer ", peer_id, ")")

func unregister_player(peer_id: int) -> void:
	if players.has(peer_id):
		print("[GlobalPvP] Player left: ", players[peer_id]["name"])
		players.erase(peer_id)
		emit_signal("player_left", peer_id)

func get_player(peer_id: int) -> Dictionary:
	return players.get(peer_id, {})

func get_alive_players() -> Array:
	var alive = []
	for pid in players:
		if players[pid]["alive"]:
			alive.append(pid)
	return alive

func get_player_count() -> int:
	return players.size()

# ----------------------------------------------------------------
# HP e danno
# ----------------------------------------------------------------
func apply_damage(target_peer_id: int, amount: float, attacker_peer_id: int) -> void:
	if not players.has(target_peer_id):
		return
	var p = players[target_peer_id]
	if not p["alive"]:
		return
	p["hp"] = max(p["hp"] - amount, 0.0)
	emit_signal("hp_changed", target_peer_id, p["hp"])
	if p["hp"] <= 0.0:
		_on_player_died(target_peer_id, attacker_peer_id)

func _on_player_died(dead_peer_id: int, killer_peer_id: int) -> void:
	players[dead_peer_id]["alive"]  = false
	players[dead_peer_id]["deaths"] += 1
	if players.has(killer_peer_id) and killer_peer_id != dead_peer_id:
		players[killer_peer_id]["kills"] += 1
	print("[GlobalPvP] Player died: peer ", dead_peer_id, " killed by ", killer_peer_id)
	emit_signal("player_died_pvp", dead_peer_id)
	_check_win_condition()

func _check_win_condition() -> void:
	var alive = get_alive_players()
	if alive.size() == 1:
		_declare_winner(alive[0])
	elif alive.size() == 0:
		_declare_winner(-1)

func _declare_winner(peer_id: int) -> void:
	winner_peer_id = peer_id
	set_state(MatchState.ENDED)
	emit_signal("winner_declared", peer_id)
	print("[GlobalPvP] Winner: peer ", peer_id)

# ----------------------------------------------------------------
# Reset
# ----------------------------------------------------------------
func reset_match() -> void:
	for pid in players:
		players[pid]["hp"]     = DEFAULT_HP
		players[pid]["alive"]  = true
		players[pid]["kills"]  = 0
		players[pid]["deaths"] = 0
		players[pid]["ready"]  = false
	winner_peer_id  = -1
	match_time_left = match_duration
	match_started   = false
	set_state(MatchState.LOBBY)

func reset_hp_only() -> void:
	for pid in players:
		players[pid]["hp"]    = DEFAULT_HP
		players[pid]["alive"] = true
