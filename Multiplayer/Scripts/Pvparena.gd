extends Node
# ================================================================
# PvPArena — Game manager dell'arena PvP
# ================================================================
# Struttura scena:
#
# Node "PvPArena"
# ├── Node2D "World"
# ├── Node "PlayerContainer"
# ├── Node2D "SpawnPoints"
# │   ├── Node2D "Spawn1"
# │   ├── Node2D "Spawn2"
# │   ├── Node2D "Spawn3"
# │   └── Node2D "Spawn4"
# └── CanvasLayer "UI"
#     ├── Label "TimerLabel"
#     ├── Label "SuddenDeathLabel"
#     ├── Label "CountdownLabel"
#     ├── Control "ScoreBoard"
#     └── Control "WinnerPanel"
#         ├── Label "WinnerLabel"
#         ├── Button "BtnRematch"
#         └── Button "BtnLeave"
# ================================================================
"""
@onready var player_container:   Node      = $PlayerContainer
@onready var spawn_points:       Node2D    = $SpawnPoints
@onready var timer_label:        Label     = $UI/TimerLabel
@onready var sudden_death_label: Label     = $UI/SuddenDeathLabel
@onready var countdown_label:    Label     = $UI/CountdownLabel
@onready var winner_panel:       Control   = $UI/WinnerPanel
@onready var winner_label:       Label     = $UI/WinnerPanel/WinnerLabel
@onready var btn_rematch:        Button    = $UI/WinnerPanel/BtnRematch
@onready var btn_leave:          Button    = $UI/WinnerPanel/BtnLeave

const PLAYER_SCENE := "res://Multiplayer/Scenes/PlayerPvP.tscn"

var player_nodes:         Dictionary = {}
var _sudden_death_timer:  float = 0.0
var _sudden_death_active: bool  = false

func _ready() -> void:
	winner_panel.hide()
	sudden_death_label.hide()
	timer_label.visible = GlobalPvP.match_mode == "timed"

	_connect_signals()

	if multiplayer.is_server():
		await _run_countdown(3)
		_spawn_all_players()
		_start_match()

func _connect_signals() -> void:
	GlobalPvP.player_died_pvp.connect(_on_player_died)
	GlobalPvP.winner_declared.connect(_on_winner_declared)
	GlobalPvP.match_state_changed.connect(_on_match_state_changed)
	btn_rematch.pressed.connect(_on_rematch_pressed)
	btn_leave.pressed.connect(_on_leave_pressed)

# ----------------------------------------------------------------
# Countdown
# ----------------------------------------------------------------
func _run_countdown(seconds: int) -> void:
	countdown_label.show()
	for i in range(seconds, 0, -1):
		_show_countdown.rpc(str(i))
		await get_tree().create_timer(1.0).timeout
	_show_countdown.rpc("FIGHT!")
	await get_tree().create_timer(0.8).timeout
	_hide_countdown.rpc()

@rpc("call_local", "reliable")
func _show_countdown(text: String) -> void:
	countdown_label.text = text

@rpc("call_local", "reliable")
func _hide_countdown() -> void:
	countdown_label.hide()

# ----------------------------------------------------------------
# Spawn
# ----------------------------------------------------------------
func _spawn_all_players() -> void:
	var spawn_list = _get_spawn_positions()
	var i = 0
	for pid in GlobalPvP.players:
		var spawn_pos = spawn_list[i % spawn_list.size()]
		_spawn_player_rpc.rpc(pid, spawn_pos)
		i += 1

func _get_spawn_positions() -> Array:
	var positions = []
	for child in spawn_points.get_children():
		if child is Node2D:
			positions.append(child.global_position)
	if positions.is_empty():
		positions = [
			Vector2(-300, 0),
			Vector2( 300, 0),
			Vector2(0, -300),
			Vector2(0,  300),
		]
	return positions

@rpc("call_local", "reliable")
func _spawn_player_rpc(pid: int, spawn_pos: Vector2) -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		push_error("[PvPArena] PlayerPvP.tscn not found at: " + PLAYER_SCENE)
		return

	var player_node = load(PLAYER_SCENE).instantiate()
	player_node.name            = str(pid)
	player_node.peer_id         = pid
	player_node.player_name     = GlobalPvP.get_player(pid).get("name", "Player")
	player_node.global_position = spawn_pos

	player_node.set_weapon({
		"name":            "Pulse Blaster",
		"damage":          25.0,
		"bullet_speed":    700.0,
		"fire_rate":       0.22,
		"projectile_type": "line"
	})

	player_container.add_child(player_node)
	player_nodes[pid] = player_node
	player_node.player_died.connect(_on_player_node_died)
	print("[PvPArena] Spawned player peer_id=", pid, " at ", spawn_pos)

# ----------------------------------------------------------------
# Match
# ----------------------------------------------------------------
func _start_match() -> void:
	GlobalPvP.match_started   = true
	GlobalPvP.match_time_left = GlobalPvP.match_duration
	GlobalPvP.set_state(GlobalPvP.MatchState.PLAYING)
	_sudden_death_timer = GlobalPvP.SUDDEN_DEATH_TICK

func _process(delta: float) -> void:
	if GlobalPvP.state != GlobalPvP.MatchState.PLAYING:
		return
	if not multiplayer.is_server():
		return

	if GlobalPvP.match_mode == "timed":
		GlobalPvP.match_time_left -= delta
		_update_timer_label.rpc(GlobalPvP.match_time_left)
		if GlobalPvP.match_time_left <= 0.0:
			_end_timed_match()
			return
		if GlobalPvP.sudden_death_enabled and GlobalPvP.match_time_left <= 30.0:
			if not _sudden_death_active:
				_sudden_death_active = true
				_activate_sudden_death.rpc()
			_sudden_death_timer -= delta
			if _sudden_death_timer <= 0.0:
				_sudden_death_timer = GlobalPvP.SUDDEN_DEATH_TICK
				_apply_sudden_death_damage()

@rpc("call_local", "reliable")
func _update_timer_label(time_left: float) -> void:
	var mins = int(time_left) / 60
	var secs = int(time_left) % 60
	timer_label.text = "%d:%02d" % [mins, secs]

@rpc("call_local", "reliable")
func _activate_sudden_death() -> void:
	sudden_death_label.show()
	sudden_death_label.text = "⚠ SUDDEN DEATH ⚠"

func _apply_sudden_death_damage() -> void:
	for pid in player_nodes:
		var node = player_nodes[pid]
		if is_instance_valid(node) and node.is_alive():
			node.take_damage_rpc.rpc_id(pid, GlobalPvP.SUDDEN_DEATH_DMG, -1)

func _end_timed_match() -> void:
	var best_peer: int   = -1
	var best_hp:   float = -1.0
	var is_draw:   bool  = false
	for pid in GlobalPvP.players:
		var p = GlobalPvP.players[pid]
		if not p["alive"]:
			continue
		if p["hp"] > best_hp:
			best_hp   = p["hp"]
			best_peer = pid
			is_draw   = false
		elif p["hp"] == best_hp:
			is_draw = true
	if is_draw:
		_force_sudden_death.rpc()
		return
	GlobalPvP._declare_winner(best_peer)

@rpc("call_local", "reliable")
func _force_sudden_death() -> void:
	sudden_death_label.show()
	sudden_death_label.text = "⚠ DRAW — SUDDEN DEATH ⚠"
	_sudden_death_active    = true
	GlobalPvP.match_mode    = "elimination"

# ----------------------------------------------------------------
# Morte / vincitore
# ----------------------------------------------------------------
func _on_player_node_died(_pid: int) -> void:
	pass

func _on_player_died(_pid: int) -> void:
	_refresh_scoreboard.rpc()

@rpc("call_local", "reliable")
func _refresh_scoreboard() -> void:
	pass  # implementa la tua UI kills/deaths qui

func _on_winner_declared(winner_peer_id: int) -> void:
	_show_winner.rpc(winner_peer_id)

@rpc("call_local", "reliable")
func _show_winner(winner_peer_id: int) -> void:
	winner_panel.show()
	if winner_peer_id == -1:
		winner_label.text = "DRAW!"
	else:
		var wname = GlobalPvP.get_player(winner_peer_id).get("name", "Unknown")
		winner_label.text = wname + " WINS!"
	btn_rematch.visible = multiplayer.is_server()

# ----------------------------------------------------------------
# Rematch
# ----------------------------------------------------------------
func _on_rematch_pressed() -> void:
	if not multiplayer.is_server():
		return
	_do_rematch.rpc()

@rpc("call_local", "reliable")
func _do_rematch() -> void:
	winner_panel.hide()
	sudden_death_label.hide()
	_sudden_death_active = false
	_sudden_death_timer  = GlobalPvP.SUDDEN_DEATH_TICK
	GlobalPvP.reset_match()
	var spawn_list = _get_spawn_positions()
	var i = 0
	for pid in player_nodes:
		var node = player_nodes[pid]
		if is_instance_valid(node):
			node.respawn(spawn_list[i % spawn_list.size()])
		i += 1
	if multiplayer.is_server():
		await _run_countdown(3)
		_start_match()

# ----------------------------------------------------------------
# Leave / state
# ----------------------------------------------------------------
func _on_leave_pressed() -> void:
	PvPConnection.disconnect_from_lobby()
	get_tree().change_scene_to_file("res://Gres/Scenes/MainMenu.tscn")

func _on_match_state_changed(new_state: String) -> void:
	match new_state:
		"playing": timer_label.visible = GlobalPvP.match_mode == "timed"
		"ended":   timer_label.hide()
"""
