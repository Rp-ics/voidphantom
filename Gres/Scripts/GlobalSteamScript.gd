extends Node

const APP_ID := "" # Set your Steam App ID here for testing (must match the one in Steamworks)

enum LeaderboardType {
	RICHEST_IN_VOID,
	TOP_HUNTER,
	WAVE_MASTER
}

var LEADERBOARDS = {
	LeaderboardType.RICHEST_IN_VOID: {
		"name": "Richest in Void",
		"score_getter": func(): return GlobalStats.gold,
		"sort_method": Steam.LEADERBOARD_SORT_METHOD_DESCENDING,
		"display_type": Steam.LEADERBOARD_DISPLAY_TYPE_NUMERIC
	},
	LeaderboardType.TOP_HUNTER: {
		"name": "main",
		"score_getter": func(): return GlobalStats.kill_boss_total + GlobalStats.kill_mobs_total + GlobalStats.kill_mini_boss_total,
		"sort_method": Steam.LEADERBOARD_SORT_METHOD_DESCENDING,
		"display_type": Steam.LEADERBOARD_DISPLAY_TYPE_NUMERIC
	},
	LeaderboardType.WAVE_MASTER: {
		"name": "Wave Master",
		"score_getter": func(): return GlobalStats.max_game_wave,
		"sort_method": Steam.LEADERBOARD_SORT_METHOD_DESCENDING,
		"display_type": Steam.LEADERBOARD_DISPLAY_TYPE_NUMERIC
	}
}

var leaderboard_handles: Dictionary = {}
var leaderboard_entries: Dictionary = {}
var current_loading_lb: int = -1

# Sequential find state
var _find_queue: Array = []
var _find_in_progress: bool = false
var _find_timer: float = 0.0
const FIND_TIMEOUT_SEC: float = 10.0

# Download FIFO queue — one download at a time
var _download_queue: Array = []
var _download_in_progress: bool = false

var player_name: String = ""
var steam_initialized: bool = false
var steam_running: bool = false

signal leaderboard_updated(leaderboard_type: int)
signal leaderboard_handle_ready(leaderboard_type: int)
signal leaderboard_find_failed(leaderboard_type: int)

@onready var achievement_check_timer: Timer = Timer.new()

func _init() -> void:
	OS.set_environment("SteamAppID", APP_ID)
	OS.set_environment("SteamGameID", APP_ID)

func _ready() -> void:
	achievement_check_timer.wait_time = 1.0
	achievement_check_timer.autostart = true
	achievement_check_timer.timeout.connect(_check_achievements)
	add_child(achievement_check_timer)
	_initialize_steam()
	GlobalStats.load_data_stats()
	
func _exit_tree() -> void:
	GlobalStats.save_data_stats()
	if steam_initialized:
		Steam.storeStats()

# ──────────────────────────────────────────────────────────────────
# Steam Initialization
# ──────────────────────────────────────────────────────────────────
func _initialize_steam() -> void:
	print("[Steam] Initializing...")
	Steam.steamInit()
	await get_tree().create_timer(1.0).timeout

	steam_running = Steam.isSteamRunning()
	print("[Steam] Running: ", steam_running)
	if not steam_running:
		print("[Steam] ERROR: Steam not running.")
		return

	steam_initialized = true
	Steam.leaderboard_find_result.connect(_on_leaderboard_find_result)
	Steam.leaderboard_scores_downloaded.connect(_on_leaderboard_scores_downloaded)

	_setup_player_info()
	_check_initial_achievements()

	await get_tree().create_timer(0.5).timeout
	_find_all_leaderboards()

func _setup_player_info() -> void:
	if not steam_initialized:
		return
	var steam_id = Steam.getSteamID()
	player_name = Steam.getFriendPersonaName(steam_id)
	print("[Steam] Player: ", player_name, " (ID: ", steam_id, ")")

# ──────────────────────────────────────────────────────────────────
# Leaderboard – Sequential Find (one at a time to avoid dropped callbacks)
# ──────────────────────────────────────────────────────────────────
func _find_all_leaderboards() -> void:
	_find_queue.clear()
	_find_in_progress = false
	_find_timer = 0.0
	leaderboard_entries.clear()
	for type in LeaderboardType.values():
		leaderboard_entries[type] = []
		_find_queue.append(type)
	_find_next_leaderboard()

func _find_next_leaderboard() -> void:
	if _find_queue.is_empty():
		print("[Leaderboard] All leaderboards resolved.")
		return
	var type: int = _find_queue[0]
	var lb = LEADERBOARDS[type]
	_find_in_progress = true
	_find_timer = 0.0
	print("[Leaderboard] Searching: '", lb["name"], "'")
	Steam.findOrCreateLeaderboard(lb["name"], lb["sort_method"], lb["display_type"])

func _on_leaderboard_find_result(handle: int, found: bool) -> void:
	print("[Leaderboard] Find result – handle: ", handle, " found: ", found)
	_find_in_progress = false
	_find_timer = 0.0

	if not found or handle == 0:
		if not _find_queue.is_empty():
			var failed_type: int = _find_queue.pop_front()
			print("[Leaderboard] FAILED: ", LEADERBOARDS[failed_type]["name"])
			emit_signal("leaderboard_find_failed", failed_type)
		await get_tree().create_timer(0.3).timeout
		_find_next_leaderboard()
		return

	var lb_name: String = Steam.getLeaderboardName(handle)
	print("[Leaderboard] Name from Steam: '", lb_name, "'")

	var matched_type: int = -1
	for type in LeaderboardType.values():
		if LEADERBOARDS[type]["name"] == lb_name:
			matched_type = type
			break

	if matched_type == -1:
		print("[Leaderboard] ERROR: '", lb_name, "' not matched!")
		if not _find_queue.is_empty():
			_find_queue.pop_front()
		await get_tree().create_timer(0.3).timeout
		_find_next_leaderboard()
		return

	leaderboard_handles[matched_type] = handle
	_find_queue.erase(matched_type)
	print("[Leaderboard] Handle saved for '", lb_name, "' type ", matched_type)

	# Upload current score only if > 0 (don't spam zeros)
	var score: int = LEADERBOARDS[matched_type]["score_getter"].call()
	if score > 0:
		print("[Leaderboard] Uploading score ", score, " for '", lb_name, "'")
		Steam.uploadLeaderboardScore(
			handle, score, PackedInt32Array(),
			Steam.LEADERBOARD_UPLOAD_SCORE_METHOD_KEEP_BEST
		)

	emit_signal("leaderboard_handle_ready", matched_type)

	await get_tree().create_timer(0.3).timeout
	_find_next_leaderboard()

# ──────────────────────────────────────────────────────────────────
# Leaderboard – Download (FIFO, one at a time)
# ──────────────────────────────────────────────────────────────────
func refresh_leaderboard(lb_type: int) -> void:
	if not steam_initialized:
		return
	var handle: int = leaderboard_handles.get(lb_type, -1)
	if handle == -1:
		print("[Leaderboard] Refresh skipped: handle not ready for type ", lb_type)
		return

	# Upload current score before downloading
	var score: int = LEADERBOARDS[lb_type]["score_getter"].call()
	if score > 0:
		Steam.uploadLeaderboardScore(
			handle, score, PackedInt32Array(),
			Steam.LEADERBOARD_UPLOAD_SCORE_METHOD_KEEP_BEST
		)

	if not _download_queue.has(lb_type):
		_download_queue.append(lb_type)
	_process_download_queue()

func _process_download_queue() -> void:
	if _download_in_progress or _download_queue.is_empty():
		return
	var lb_type: int = _download_queue[0]
	var handle: int = leaderboard_handles.get(lb_type, -1)
	if handle == -1:
		_download_queue.pop_front()
		_process_download_queue()
		return
	_download_in_progress = true
	current_loading_lb = lb_type
	print("[Leaderboard] Downloading '", LEADERBOARDS[lb_type]["name"], "'")
	Steam.downloadLeaderboardEntries(handle, Steam.LEADERBOARD_DATA_REQUEST_GLOBAL, 1, 10)

func _on_leaderboard_scores_downloaded(_message: String, _call_handle: int, entries_result: Array) -> void:
	print("[Leaderboard] Downloaded. Entries: ", entries_result.size())

	if _download_queue.is_empty():
		_download_in_progress = false
		current_loading_lb = -1
		return

	var lb_type: int = _download_queue.pop_front()
	_download_in_progress = false
	current_loading_lb = -1

	var entries: Array = []
	for entry in entries_result:
		var steam_id: int = entry.get("steam_id", 0)
		var score: int = entry.get("score", 0)
		var name: String = Steam.getFriendPersonaName(steam_id)
		if name == "" or name == "[unknown]":
			Steam.requestUserInformation(steam_id, true)
			name = "Player " + str(steam_id)
		entries.append({"name": name, "score": score, "steam_id": steam_id})

	leaderboard_entries[lb_type] = entries
	print("[Leaderboard] '", LEADERBOARDS[lb_type]["name"], "' updated: ", entries.size(), " entries.")
	emit_signal("leaderboard_updated", lb_type)

	_process_download_queue()

# ──────────────────────────────────────────────────────────────────
# Public API
# ──────────────────────────────────────────────────────────────────
func get_leaderboard_entries(lb_type: int) -> Array:
	return leaderboard_entries.get(lb_type, [])

func upload_score(lb_type: int, _force: bool = false) -> void:
	var lb_name = LEADERBOARDS[lb_type]["name"]
	var score = LEADERBOARDS[lb_type]["score_getter"].call()
	
	if score <= 0: return

	# Recuperiamo l'ultimo punteggio salvato localmente per questo tipo di classifica
	var last_saved_score = 0
	var entries = get_leaderboard_entries(lb_type)
	for entry in entries:
		if entry["name"] == player_name:
			last_saved_score = entry["score"]
			break
			
	# Se il punteggio attuale non è superiore a quello salvato (e non è un invio forzato), usciamo
	if score <= last_saved_score and not _force:
		print("[SilentWolf] Score for ", lb_name, " hasn't improved. Skipping upload.")
		return

	var p_name = player_name if player_name != "" else "Void Walker"
	
	print("[SilentWolf] Uploading improved score: ", score, " to ", lb_name)
	var sw_result = await SilentWolf.Scores.save_score(p_name, score, lb_name).sw_save_score_complete
	
	if sw_result.has("score_id") and sw_result.score_id != "":
		print("[SilentWolf] Upload Success!")
		# Dopo un successo, rinfreschiamo subito i dati per allineare last_saved_score
		refresh_leaderboard(lb_type) 
	else:
		print("[SilentWolf] Upload Failed")

func _process(delta: float) -> void:
	if steam_initialized:
		Steam.run_callbacks()

	# Watchdog: if Steam never fires find callback
	if _find_in_progress:
		_find_timer += delta
		if _find_timer >= FIND_TIMEOUT_SEC:
			print("[Leaderboard] Find timeout!")
			_find_in_progress = false
			_find_timer = 0.0
			if not _find_queue.is_empty():
				var failed_type: int = _find_queue.pop_front()
				emit_signal("leaderboard_find_failed", failed_type)
			_find_next_leaderboard()

# ──────────────────────────────────────────────────────────────────
# Achievements
# ──────────────────────────────────────────────────────────────────
func _check_initial_achievements() -> void:
	if not steam_initialized:
		return
	var status = Steam.getAchievement("FIRST LIGHT PIONEER")
	if status["achieved"]:
		Global.unque_achieve = true

func _check_achievements() -> void:
	if not steam_initialized:
		return
	_check_game_achievements()
	_unlock_achievements_by_flags()

func _check_game_achievements() -> void:
	_unlock_achievement("FIRST LIGHT PIONEER")
	_unlock_achievement("Leviathan’s Hunger")
	_unlock_achievement("Leviathan's Hunger")
	_unlock_achievement("Void-King’s Triumph")
	_unlock_achievement("Startborn Power")
	if GlobalStats.achievements["Was Easy"]:
		_unlock_achievement("Was Easy")
	if GlobalStats.achievements["God of NULLBORN"]:
		_unlock_achievement("God of NULLBORN")
	if GlobalStats.achievements["God of OBLIVION"]:
		_unlock_achievement("God of OBLIVION")
	if GlobalStats.achievements["God of MIND"]:
		_unlock_achievement("God of MIND")
	if GlobalStats.achievements["God of AEGIS"]:
		_unlock_achievement("God of AEGIS")
	if GlobalStats.achievements["God of PROXIMITY"]:
		_unlock_achievement("God of PROXIMITY")
	if GlobalStats.achievements["God if WALL"]:
		_unlock_achievement("God if WALL")
	if Global.wave == 10:
		GlobalStats.achievements["Wave-Master I"] = true
	if Global.boss_killed and Global.player_hp <= 30:
		GlobalStats.achievements["Aegis of the Fallen Star"] = true
	if Global.boss_killed and GlobalStats.damage_rec_boss_lvl <= 0:
		GlobalStats.achievements["Void-King's Triumph"] = true
	if Global.boss_killed and Global.player_hp < 10:
		GlobalStats.achievements["Final Breath Victory"] = true
	if GlobalStats.play_hours >= 168:
		GlobalStats.achievements["Frost-Bound Epoch"] = true
	if GlobalStats.kill_boss_total >= 4:
		GlobalStats.achievements["Arcane Ascendancy"] = true
	if Global.boss_killed and Global.player_hp <= (Global.player_max_hp * 0.05):
		GlobalStats.achievements["Defile the Fate"] = true
	if GlobalStats.total_craft >= 10:
		GlobalStats.achievements["Forge of the Common Star"] = true
	if GlobalStats.died_times >= 500:
		GlobalStats.achievements["Forge of the Void-Titan"] = true
	if GlobalStats.damage_inf_total >= 1000000:
		GlobalStats.achievements["Galactic Destruction"] = true
	if GlobalStats.stars >= 1:
		GlobalStats.achievements["Starborn Awakening"] = true
	if GlobalStats.stars >= 4:
		GlobalStats.achievements["Cosmic Armory"] = true
	if GlobalStats.stars >= 10:
		GlobalStats.achievements["Celestial Ascendancy"] = true
	if GlobalStats.stars >= 29:
		GlobalStats.achievements["Stellar Omnipotence"] = true

func _unlock_achievements_by_flags() -> void:
	var achievement_list = [
		"Ascent of the Unbroken", "Tempest Sovereign", "Walker of the Abyss",
		"Harvest of Power", "Frost-Bound Epoch", "Aegis of the Fallen Star",
		"Void-King's Triumph", "Phantom of the Twentieth Dawn", "Leviathan's Hunger",
		"Astral Collector", "Mirage of Million Shots", "Abyssal Deadshot",
		"Celestial Onslaught", "Solar Tide Immortal", "Final Breath Victory",
		"Nuclear Oblivion", "Frozen Catastrophe", "Arcane Ascendancy",
		"Defile the Fate", "Godslayer Marksman", "Forge of the Common Star",
		"Forge of the Shattered Moon", "Forge of the Void-Titan", "Galactic Destruction",
		"Starborn Awakening", "Cosmic Armory", "Celestial Ascendancy",
		"Stellar Omnipotence", "Nebula-Forged Form", "Wave-Master I"
	]
	for ach in achievement_list:
		if GlobalStats.achievements.get(ach, false):
			_unlock_achievement(ach)

func _unlock_achievement(key: String) -> void:
	if not steam_initialized:
		return
	if GlobalStats.achievements.has(key) and GlobalStats.achievements[key]:
		var status = Steam.getAchievement(key)
		if not status["achieved"]:
			Steam.setAchievement(key)
			Steam.storeStats()
			GlobalStats.save_data_stats()
