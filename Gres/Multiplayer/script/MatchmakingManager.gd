extends Node

signal status_changed(message: String)
signal match_found(lobby_id: int)
signal matchmaking_failed(reason: String)
signal matchmaking_cancelled()
signal bot_match_started()

const MATCHMAKING_TIMEOUT_SEC: float = 15.0

var is_searching: bool = false
var matched_lobby_id: int = 0
var is_bot_match: bool = false
var _timeout_timer: Timer = null

func _ready() -> void:
	_timeout_timer = Timer.new()
	_timeout_timer.one_shot = true
	_timeout_timer.wait_time = MATCHMAKING_TIMEOUT_SEC
	_timeout_timer.timeout.connect(_on_timeout)
	add_child(_timeout_timer)

	GlobalSteamScript.matchmaking_status_changed.connect(_on_steam_status_changed)
	GlobalSteamScript.matchmaking_failed.connect(_on_steam_matchmaking_failed)
	GlobalSteamScript.matchmaking_lobby_ready.connect(_on_matchmaking_lobby_ready)
	GlobalSteamScript.player_joined.connect(_on_lobby_player_joined)

func find_match() -> void:
	if is_searching:
		return
	if GlobalSteamScript.is_in_lobby:
		emit_signal("matchmaking_failed", "Leave the current lobby before searching.")
		return

	is_searching = true
	is_bot_match = false
	matched_lobby_id = 0
	GameModes.set_mode(GameModes.GameMode.CLASSIC)
	GameModes.save_settings()

	emit_signal("status_changed", "Finding match...")
	_timeout_timer.start(MATCHMAKING_TIMEOUT_SEC)
	GlobalSteamScript.find_or_create_matchmaking_lobby()
	get_tree().change_scene_to_file("res://Gres/Multiplayer/scene/UI/lobby.tscn")

func cancel_matchmaking() -> void:
	if not is_searching:
		return
	is_searching = false
	matched_lobby_id = 0
	_timeout_timer.stop()
	GlobalSteamScript.cancel_matchmaking_search()
	if GlobalSteamScript.is_matchmaking_lobby():
		GlobalSteamScript.leave_lobby()
	emit_signal("matchmaking_cancelled")
	emit_signal("status_changed", "Matchmaking cancelled.")

func notify_match_started() -> void:
	is_searching = false
	_timeout_timer.stop()

func _on_steam_status_changed(message: String) -> void:
	if is_searching:
		emit_signal("status_changed", message)

func _on_steam_matchmaking_failed(reason: String) -> void:
	if not is_searching:
		return
	is_searching = false
	matched_lobby_id = 0
	_timeout_timer.stop()
	emit_signal("matchmaking_failed", reason)

func _on_matchmaking_lobby_ready(lobby_id: int, is_host: bool) -> void:
	if not is_searching:
		return
	matched_lobby_id = lobby_id
	if is_host:
		emit_signal("status_changed", "Waiting for an opponent...")
	else:
		is_searching = false
		_timeout_timer.stop()
		emit_signal("match_found", lobby_id)

func _on_lobby_player_joined(_steam_id: int) -> void:
	if not is_searching:
		return
	if not GlobalSteamScript.is_matchmaking_lobby():
		return
	if GlobalSteamScript.get_lobby_member_count() >= 2:
		is_searching = false
		_timeout_timer.stop()
		emit_signal("match_found", GlobalSteamScript.current_lobby_id)

func _on_timeout() -> void:
	if not is_searching:
		return
	is_searching = false
	matched_lobby_id = 0
	GlobalSteamScript.cancel_matchmaking_search()
	if GlobalSteamScript.is_matchmaking_lobby():
		GlobalSteamScript.leave_lobby()
	is_bot_match = true
	# Go to lobby, lobby will auto-start bot match
	get_tree().change_scene_to_file("res://Gres/Multiplayer/scene/UI/lobby.tscn")
	emit_signal("bot_match_started")
