extends Node

signal leaderboard_updated(leaderboard_type: int)

enum LeaderboardType {
	RICHEST_IN_VOID,
	TOP_HUNTER,
	WAVE_MASTER
}

var leaderboard_entries: Dictionary = {
	LeaderboardType.RICHEST_IN_VOID: [],
	LeaderboardType.TOP_HUNTER: [],
	LeaderboardType.WAVE_MASTER: []
}

var current_loading_lb: int = -1

func _ready() -> void:
	_initialize_silentwolf()

func _initialize_silentwolf() -> void:
	SilentWolf.configure({
		"api_key": "KF6srFYA0m3UlYK3ziurkaP6aBCI4yqW9aRyiM9G",
		"game_id": "voidphantom",
		"log_level": 1
	})

## Uploads score only if it's a new record, deleting any previous entries to avoid duplicates
func upload_score(lb_type: int) -> bool:
	var lb_name = _get_lb_name(lb_type)
	var score = _get_score_from_stats(lb_type)
	
	if score <= 0: return false

	var p_name = _get_player_name()
	var current_best_in_cache = 0
	for entry in leaderboard_entries[lb_type]:
		if entry.name == p_name:
			current_best_in_cache = entry.score
			break
	
	if score <= current_best_in_cache:
		print("[Scoreboard] Skipping upload: Record not broken (%d <= %d)" % [score, current_best_in_cache])
		return false

	print("[Scoreboard] Uploading new record: %d to %s for %s" % [score, lb_name, p_name])
	
	# --- 1. Elimina tutti i vecchi punteggi di questo giocatore nella classifica ---
	var safe_lb_name = lb_name.uri_encode()
	# Prendiamo TUTTI i punteggi (passiamo un limite molto alto)
	var get_result = await SilentWolf.Scores.get_scores(9999, safe_lb_name).sw_get_scores_complete
	if get_result and get_result.has("scores"):
		for s in get_result.scores:
			if s.player_name == p_name:
				var del_res = await SilentWolf.Scores.delete_score(s.score_id).sw_delete_score_complete
				if not del_res.success:
					push_warning("[Scoreboard] Could not delete old score %s" % s.score_id)
				else:
					print("[Scoreboard] Deleted previous score %s for %s" % [s.score_id, p_name])
	
	# --- 2. Salva il nuovo punteggio (senza overwrite, ora non ci saranno duplicati) ---
	var sw_result = await SilentWolf.Scores.save_score(p_name, score, lb_name).sw_save_score_complete
	
	if sw_result.success:
		print("[Scoreboard] Record saved successfully!")
		await refresh_leaderboard(lb_type)
		return true
	return false

## Fetches the ranking from the server, deduplicating locally if needed
func refresh_leaderboard(lb_type: int) -> void:
	if current_loading_lb != -1: return 
	
	var lb_name = _get_lb_name(lb_type)
	var safe_lb_name = lb_name.uri_encode()
	
	current_loading_lb = lb_type
	
	var sw_result = await SilentWolf.Scores.get_scores(10, safe_lb_name).sw_get_scores_complete
	
	var raw_entries = []
	if sw_result and sw_result.has("scores"):
		for s in sw_result.scores:
			raw_entries.append({"name": s.player_name, "score": int(s.score)})
	
	# Deduplica: tieni solo il miglior punteggio per giocatore
	var deduped = {}
	for entry in raw_entries:
		var n = entry.name
		if not deduped.has(n) or entry.score > deduped[n].score:
			deduped[n] = entry
	var entries = deduped.values()
	entries.sort_custom(func(a, b): return a.score > b.score)
	if entries.size() > 10:
		entries = entries.slice(0, 10)
	
	leaderboard_entries[lb_type] = entries
	current_loading_lb = -1
	leaderboard_updated.emit(lb_type)

## Reset completo: elimina TUTTI i punteggi della classifica dal server
func reset_leaderboard(lb_type: int) -> void:
	var lb_name = _get_lb_name(lb_type)
	print("[Scoreboard] Wiping leaderboard: %s ..." % lb_name)
	
	var sw_result = await SilentWolf.Scores.wipe_leaderboard(lb_name).sw_wipe_leaderboard_complete
	if sw_result.success:
		print("[Scoreboard] Leaderboard wiped successfully.")
		leaderboard_entries[lb_type] = []
		leaderboard_updated.emit(lb_type)
	else:
		push_error("[Scoreboard] Failed to wipe leaderboard: %s" % sw_result.error)

func get_leaderboard_entries(lb_type: int) -> Array:
	return leaderboard_entries.get(lb_type, [])

# --- HELPERS ---

func _get_player_name() -> String:
	if is_instance_valid(GlobalSteamScript) and GlobalSteamScript.player_name != "":
		return GlobalSteamScript.player_name
	return "Void Walker"

func _get_lb_name(type: int) -> String:
	match type:
		LeaderboardType.RICHEST_IN_VOID: return "Richest in Void"
		LeaderboardType.TOP_HUNTER: return "Top Hunter"
		LeaderboardType.WAVE_MASTER: return "Wave Master"
	return "main"

func _get_score_from_stats(type: int) -> int:
	match type:
		LeaderboardType.RICHEST_IN_VOID: return GlobalStats.gold
		LeaderboardType.TOP_HUNTER: return GlobalStats.kill_boss_total + GlobalStats.kill_mobs_total + GlobalStats.kill_mini_boss_total
		LeaderboardType.WAVE_MASTER: return GlobalStats.max_game_wave
	return 0
