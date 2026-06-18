extends Node

const APP_ID := "3266180"

signal lobby_created(success: bool, lobby_id: int, room_code: String)
signal lobby_joined(success: bool, lobby_id: int)
signal player_joined(steam_id: int)
signal player_left(steam_id: int)
signal matchmaking_lobby_ready(lobby_id: int, is_host: bool)
signal matchmaking_failed(reason: String)
signal matchmaking_status_changed(message: String)

# --- MULTIPLAYER --- #
signal multiplayer_entered()
signal multiplayer_exited()

# --- PvE / HOST MIGRATION --- #
signal host_changed(new_host_steam_id: int)
signal lobby_mode_set(is_pve: bool)


var is_in_lobby: bool = false
var current_lobby_id: int = 0
var current_room_code: String = ""
var expected_players_count: int = 1
var current_lobby_is_matchmaking: bool = false
var current_lobby_is_pve: bool = false

# Usiamo SteamMultiplayerPeer per il trasporto tramite Steam P2P
var steam_peer: MultiplayerPeer = null
var _pending_lobby_is_matchmaking: bool = false
var _lobby_search_mode: String = ""


# Aggiungi queste funzioni
func notify_multiplayer_entered():
	print("[Steam] Multiplayer entered - switching to arena weapon")
	emit_signal("multiplayer_entered")

func notify_multiplayer_exited():
	print("[Steam] Multiplayer exited - restoring single player weapon")
	emit_signal("multiplayer_exited")
# ------------------------------------------------------------------
# Leaderboard e achievements (invariati)
# ------------------------------------------------------------------
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

var _find_queue: Array = []
var _find_in_progress: bool = false
var _find_timer: float = 0.0
const FIND_TIMEOUT_SEC: float = 10.0

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

func _ready():
	randomize()
	achievement_check_timer.wait_time = 1.0
	achievement_check_timer.autostart = true
	achievement_check_timer.timeout.connect(_check_achievements)
	add_child(achievement_check_timer)

	await _initialize_steam()
	GlobalStats.load_data_stats()

	if steam_initialized:
		Steam.lobby_created.connect(_on_lobby_created)
		Steam.lobby_joined.connect(_on_lobby_joined)
		Steam.lobby_chat_update.connect(_on_lobby_chat_update)
		Steam.lobby_match_list.connect(_on_lobby_match_list)
		Steam.p2p_session_request.connect(_on_p2p_session_request)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _exit_tree() -> void:
	GlobalStats.save_data_stats()
	if steam_initialized:
		Steam.storeStats()

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

	# Attiva il relay globale di Steam (ESSENZIALE per Italia-Ucraina)
	Steam.initRelayNetworkAccess()
	Steam.allowP2PPacketRelay(true)
	# NOTA: setNetworkingP2PSendBufferSize non esiste in questa versione di GodotSteam, lo rimuoviamo.
	print("[Steam] ✅ Relay P2P attivato – connessioni globali possibili.")

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

	# Exclusive weapon unlock for specific Steam user
	if steam_id == 76561198030784015 or player_name == "Obey the Fist!":
		GlobalStats.unlock_obey_the_fist()
		print("[Steam] 🎁 EXCLUSIVE WEAPON UNLOCKED: Obey the Fist! for ", player_name)

# ------------------------------------------------------------------
# Leaderboard (funzioni complete)
# ------------------------------------------------------------------
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
		return
	var type: int = _find_queue[0]
	var lb = LEADERBOARDS[type]
	_find_in_progress = true
	_find_timer = 0.0
	Steam.findOrCreateLeaderboard(lb["name"], lb["sort_method"], lb["display_type"])

func _on_leaderboard_find_result(handle: int, found: bool) -> void:
	_find_in_progress = false
	_find_timer = 0.0

	if not found or handle == 0:
		if not _find_queue.is_empty():
			var failed_type: int = _find_queue.pop_front()
			emit_signal("leaderboard_find_failed", failed_type)
		await get_tree().create_timer(0.3).timeout
		_find_next_leaderboard()
		return

	var lb_name: String = Steam.getLeaderboardName(handle)
	var matched_type: int = -1
	for type in LeaderboardType.values():
		if LEADERBOARDS[type]["name"] == lb_name:
			matched_type = type
			break

	if matched_type == -1:
		if not _find_queue.is_empty():
			_find_queue.pop_front()
		await get_tree().create_timer(0.3).timeout
		_find_next_leaderboard()
		return

	leaderboard_handles[matched_type] = handle
	_find_queue.erase(matched_type)

	var score: int = LEADERBOARDS[matched_type]["score_getter"].call()
	if score > 0:
		Steam.uploadLeaderboardScore(
			handle, score, PackedInt32Array(),
			Steam.LEADERBOARD_UPLOAD_SCORE_METHOD_KEEP_BEST
		)

	emit_signal("leaderboard_handle_ready", matched_type)
	await get_tree().create_timer(0.3).timeout
	_find_next_leaderboard()

func refresh_leaderboard(lb_type: int) -> void:
	if not steam_initialized:
		return
	var handle: int = leaderboard_handles.get(lb_type, -1)
	if handle == -1:
		return

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
	Steam.downloadLeaderboardEntries(handle, Steam.LEADERBOARD_DATA_REQUEST_GLOBAL, 1, 10)

func _on_leaderboard_scores_downloaded(_message: String, _call_handle: int, entries_result: Array) -> void:
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
	emit_signal("leaderboard_updated", lb_type)
	_process_download_queue()

func get_leaderboard_entries(lb_type: int) -> Array:
	return leaderboard_entries.get(lb_type, [])

func upload_score(lb_type: int, _force: bool = false) -> void:
	var lb_name = LEADERBOARDS[lb_type]["name"]
	var score = LEADERBOARDS[lb_type]["score_getter"].call()
	if score <= 0:
		return

	var last_saved_score = 0
	var entries = get_leaderboard_entries(lb_type)
	for entry in entries:
		if entry["name"] == player_name:
			last_saved_score = entry["score"]
			break

	if score <= last_saved_score and not _force:
		return

	var p_name = player_name if player_name != "" else "Void Walker"
	var sw_result = await SilentWolf.Scores.save_score(p_name, score, lb_name).sw_save_score_complete
	if sw_result.has("score_id") and sw_result.score_id != "":
		refresh_leaderboard(lb_type)

func _process(delta: float) -> void:
	if steam_initialized:
		Steam.run_callbacks()

	if _find_in_progress:
		_find_timer += delta
		if _find_timer >= FIND_TIMEOUT_SEC:
			_find_in_progress = false
			_find_timer = 0.0
			if not _find_queue.is_empty():
				var failed_type: int = _find_queue.pop_front()
				emit_signal("leaderboard_find_failed", failed_type)
			_find_next_leaderboard()

# ------------------------------------------------------------------
# Achievements (funzioni complete)
# ------------------------------------------------------------------
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
	_unlock_achievement("Leviathan's Hunger")
	_unlock_achievement("Leviathan's Hunger")
	_unlock_achievement("Void-King's Triumph")
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

# ================================================================
# LOBBY E MULTIPLAYER – Steam P2P + ENet (Italia-Ucraina)
# ================================================================

func create_pve_lobby(max_players: int = 4, is_private: bool = false) -> void:
	if not steam_initialized:
		push_error("Steam non inizializzato")
		return
	_pending_lobby_is_matchmaking = false
	current_lobby_is_pve = true
	var lobby_type = Steam.LOBBY_TYPE_PRIVATE if is_private else Steam.LOBBY_TYPE_PUBLIC
	Steam.createLobby(lobby_type, max_players)
	print("[Steam] createLobby (PvE) chiamato")

func create_lobby(max_players: int = 4, is_private: bool = false, is_matchmaking: bool = false) -> void:
	if not steam_initialized:
		push_error("Steam non inizializzato")
		return
	_pending_lobby_is_matchmaking = is_matchmaking
	var lobby_type = Steam.LOBBY_TYPE_PRIVATE if is_private else Steam.LOBBY_TYPE_PUBLIC
	Steam.createLobby(lobby_type, max_players)
	print("[Steam] createLobby chiamato")

func join_lobby_by_code(room_code: String) -> void:
	if not steam_initialized:
		return
	_lobby_search_mode = "room_code"
	Steam.addRequestLobbyListStringFilter("room_code", room_code, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()
	print("[Steam] Ricerca lobby con codice: ", room_code)

func find_or_create_matchmaking_lobby() -> void:
	if not steam_initialized:
		emit_signal("matchmaking_failed", "Steam is not initialized.")
		return
	_lobby_search_mode = "matchmaking"
	emit_signal("matchmaking_status_changed", "Searching for an opponent...")
	Steam.addRequestLobbyListStringFilter("matchmaking", "1", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.addRequestLobbyListStringFilter("mode", "CLASSIC", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.addRequestLobbyListStringFilter("status", "waiting", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()
	print("[Steam] Ricerca lobby matchmaking CLASSIC")

func cancel_matchmaking_search() -> void:
	if _lobby_search_mode == "matchmaking":
		_lobby_search_mode = ""
		_pending_lobby_is_matchmaking = false
		emit_signal("matchmaking_status_changed", "Matchmaking cancelled.")

func is_matchmaking_lobby() -> bool:
	return current_lobby_is_matchmaking

func leave_lobby() -> void:
	if current_lobby_id != 0:
		Steam.leaveLobby(current_lobby_id)
		current_lobby_id = 0
		is_in_lobby = false
		current_room_code = ""
		current_lobby_is_matchmaking = false
		current_lobby_is_pve = false
		_lobby_search_mode = ""
		_pending_lobby_is_matchmaking = false
	if steam_peer:
		steam_peer.close()
		steam_peer = null
	multiplayer.multiplayer_peer = null
	notify_multiplayer_exited()


func _on_lobby_created(result: int, lobby_id: int) -> void:
	print("[Steam] Lobby created - result: ", result, " lobby_id: ", lobby_id)
	if result == 1:
		current_lobby_id = lobby_id
		is_in_lobby = true
		current_lobby_is_matchmaking = _pending_lobby_is_matchmaking
		current_room_code = _generate_room_code()
		Steam.setLobbyData(lobby_id, "room_code", current_room_code)
		if current_lobby_is_pve:
			Steam.setLobbyData(lobby_id, "pve", "1")
			Steam.setLobbyData(lobby_id, "mode", "PVE_ENDLESS")
		if current_lobby_is_matchmaking:
			Steam.setLobbyData(lobby_id, "matchmaking", "1")
			Steam.setLobbyData(lobby_id, "mode", "CLASSIC")
			Steam.setLobbyData(lobby_id, "status", "waiting")
			Steam.setLobbyData(lobby_id, "room_code", "")

		# Creazione host tramite SteamMultiplayerPeer
		steam_peer = SteamMultiplayerPeer.new()
		var err = steam_peer.create_host(0)
		if err != OK:
			push_error("[Steam] create_host fallito: ", err)
			emit_signal("lobby_created", false, 0, "")
			return

		multiplayer.multiplayer_peer = steam_peer
		print("[Steam] ✅ Server SteamMultiplayerPeer creato. In attesa di connessioni...")

		emit_signal("lobby_created", true, lobby_id, current_room_code)
		if current_lobby_is_matchmaking:
			emit_signal("matchmaking_status_changed", "Waiting for an opponent...")
			emit_signal("matchmaking_lobby_ready", lobby_id, true)
		else:
			get_tree().change_scene_to_file("res://Gres/Multiplayer/scene/UI/lobby.tscn")
	else:
		_pending_lobby_is_matchmaking = false
		emit_signal("lobby_created", false, 0, "")

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, _chat_room_enter_response: int) -> void:
	print("[Steam] Lobby joined: ", lobby_id)
	if current_lobby_id == lobby_id:
		print("[Steam] Già in questa lobby, ignoro")
		return

	current_lobby_id = lobby_id
	is_in_lobby = true
	current_room_code = Steam.getLobbyData(lobby_id, "room_code")
	current_lobby_is_matchmaking = Steam.getLobbyData(lobby_id, "matchmaking") == "1"
	current_lobby_is_pve = Steam.getLobbyData(lobby_id, "pve") == "1"
	print("[Steam] Room code: ", current_room_code, " is_pve: ", current_lobby_is_pve)

	var host_id: int = Steam.getLobbyOwner(lobby_id)
	print("[Steam] Host Steam ID: ", host_id)

	# Creazione client tramite SteamMultiplayerPeer all'host
	steam_peer = SteamMultiplayerPeer.new()
	var err = steam_peer.create_client(host_id, 0)
	if err != OK:
		push_error("[Steam] create_client fallito: ", err)
		emit_signal("lobby_joined", false, 0)
		return

	multiplayer.multiplayer_peer = steam_peer
	print("[Steam] ✅ Client SteamMultiplayerPeer creato. In attesa di connessione globale...")

	emit_signal("lobby_joined", true, lobby_id)
	if current_lobby_is_matchmaking:
		emit_signal("matchmaking_status_changed", "Opponent found.")
		emit_signal("matchmaking_lobby_ready", lobby_id, false)
	else:
		get_tree().change_scene_to_file("res://Gres/Multiplayer/scene/UI/lobby.tscn")

func _on_lobby_match_list(lobbies: Array) -> void:
	if _lobby_search_mode == "matchmaking":
		_lobby_search_mode = ""
		if lobbies.size() > 0:
			emit_signal("matchmaking_status_changed", "Opponent found. Joining lobby...")
			Steam.joinLobby(lobbies[0])
		else:
			emit_signal("matchmaking_status_changed", "No opponent found. Creating queue lobby...")
			create_lobby(2, false, true)
		return

	if _lobby_search_mode == "room_code":
		_lobby_search_mode = ""
		if lobbies.size() > 0:
			Steam.joinLobby(lobbies[0])
		else:
			emit_signal("lobby_joined", false, 0)

func _on_lobby_chat_update(lobby_id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
	if chat_state == 1:
		emit_signal("player_joined", changed_id)
	elif chat_state == 2:
		emit_signal("player_left", changed_id)
		if changed_id == Steam.getLobbyOwner(lobby_id):
			var members = get_lobby_members()
			for member in members:
				if member != changed_id:
					Steam.setLobbyOwner(lobby_id, member)
					var new_host = Steam.getLobbyOwner(lobby_id)
					emit_signal("host_changed", new_host)
					if current_lobby_is_pve:
						_handle_pve_host_migration(new_host)
					break
	elif chat_state == 4:
		emit_signal("player_left", changed_id)

func _handle_pve_host_migration(new_host_id: int) -> void:
	print("[Steam] PvE host migration a ", new_host_id)
	var local_id = Steam.getSteamID()
	if local_id == new_host_id:
		print("[Steam] Questo peer è il nuovo host PvE")
		if steam_peer:
			steam_peer.close()
		steam_peer = SteamMultiplayerPeer.new()
		var err = steam_peer.create_host(0)
		if err == OK:
			multiplayer.multiplayer_peer = steam_peer
			print("[Steam] Nuovo host SteamMultiplayerPeer creato")
			_restore_pve_state_as_host.rpc()
		else:
			push_error("[Steam] Nuovo host create_host fallito: ", err)
	else:
		print("[Steam] Client: riconnessione al nuovo host ", new_host_id)
		if steam_peer:
			steam_peer.close()
		steam_peer = SteamMultiplayerPeer.new()
		var err = steam_peer.create_client(new_host_id, 0)
		if err == OK:
			multiplayer.multiplayer_peer = steam_peer
			print("[Steam] Client riconnesso al nuovo host")

@rpc("authority", "call_local", "reliable")
func _restore_pve_state_as_host() -> void:
	print("[Steam] Nuovo host: ripristino stato PvE")
	var arena = get_tree().current_scene
	if arena and arena.has_method("_on_host_migrated"):
		arena._on_host_migrated()

func _on_p2p_session_request(remote_steam_id: int) -> void:
	print("[Steam] 📡 Richiesta sessione P2P da: ", remote_steam_id)
	Steam.acceptP2PSessionWithUser(remote_steam_id)
	print("[Steam] ✅ Sessione P2P accettata")

func _on_connected_to_server() -> void:
	print("[Steam] 🎉 CONNESSO! Peer ID: ", multiplayer.get_unique_id())

func _on_peer_connected(peer_id: int) -> void:
	print("[Steam] 👥 Peer connesso: ", peer_id)

func _on_server_disconnected() -> void:
	print("[Steam] ❌ Server disconnesso")
	leave_lobby()

func _on_connection_failed() -> void:
	print("[Steam] ❌ Connessione fallita")
	leave_lobby()

func get_lobby_members() -> Array[int]:
	var members: Array[int] = []
	if current_lobby_id == 0:
		return members
	var count = Steam.getNumLobbyMembers(current_lobby_id)
	for i in range(count):
		members.append(Steam.getLobbyMemberByIndex(current_lobby_id, i))
	return members

func get_lobby_member_count() -> int:
	return get_lobby_members().size()

func _generate_room_code() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_part = randi() % 1000
	var code = str(int(timestamp) % 900000 + random_part + 100000)
	return code.substr(0, 6)

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	print("[Steam] RPC start_game ricevuta sul peer ", multiplayer.get_unique_id())
	if multiplayer.is_server():
		expected_players_count = get_lobby_member_count()
		print("[Steam] Host: cambio scena. Aspettando %d giocatori." % expected_players_count)
		notify_multiplayer_entered()
		if current_lobby_is_pve:
			GameModes.set_mode(GameModes.GameMode.PVE_ENDLESS)
			get_tree().change_scene_to_file("res://Gres/Multiplayer/scene/areans/mu_arena.tscn")
		else:
			get_tree().change_scene_to_file("res://Gres/Multiplayer/scene/areans/mu_arena.tscn")
	else:
		print("[Steam] Client: attendo 0.5 secondi poi cambio scena")
		await get_tree().create_timer(0.5).timeout
		notify_multiplayer_entered()
		if current_lobby_is_pve:
			GameModes.set_mode(GameModes.GameMode.PVE_ENDLESS)
		get_tree().change_scene_to_file("res://Gres/Multiplayer/scene/areans/mu_arena.tscn")
	
