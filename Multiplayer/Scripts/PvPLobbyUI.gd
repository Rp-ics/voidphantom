extends Control
# ================================================================
# PvPLobbyUI — UI della lobby PvP
# Struttura scena:
#
# Control "PvPLobbyUI"
# ├── Label "LabelStatus"
# ├── Control "PanelMain"
# │   ├── Button "BtnHost"
# │   ├── Button "BtnJoin"
# │   ├── Button "BtnFindPublic"
# │   └── LineEdit "LobbyIDInput"
# └── Control "PanelLobby"
#     ├── Label "LabelLobbyID"
#     ├── VBoxContainer "PlayerList"
#     ├── Button "BtnInviteFriend"
#     ├── Button "BtnReady"
#     ├── Button "BtnStartMatch"
#     ├── OptionButton "OptionMatchMode"
#     └── Button "BtnLeave"
# ================================================================
"""
@onready var panel_main:      Control       = $PanelMain
@onready var panel_lobby:     Control       = $PanelLobby
@onready var btn_host:        Button        = $PanelMain/BtnHost
@onready var btn_join:        Button        = $PanelMain/BtnJoin
@onready var btn_find_public: Button        = $PanelMain/BtnFindPublic
@onready var lobby_id_input:  LineEdit      = $PanelMain/LobbyIDInput
@onready var label_lobby_id:  LineEdit         = $PanelLobby/LabelLobbyID
@onready var player_list:     VBoxContainer = $PanelLobby/PlayerList
@onready var btn_invite:      Button        = $PanelLobby/BtnInviteFriend
@onready var btn_ready:       Button        = $PanelLobby/BtnReady
@onready var btn_start:       Button        = $PanelLobby/BtnStartMatch
@onready var option_mode:     OptionButton  = $PanelLobby/OptionMatchMode
@onready var btn_leave:       Button        = $PanelLobby/BtnLeave
@onready var label_status:    Label         = $LabelStatus

const ARENA_SCENE := "res://Multiplayer/Scenes/PvPArena.tscn"

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_show_main_panel()

func _setup_ui() -> void:
	option_mode.clear()
	option_mode.add_item("Elimination (last alive wins)", 0)
	option_mode.add_item("Timed (most HP wins)",          1)
	btn_start.visible    = false
	option_mode.disabled = true

func _connect_signals() -> void:
	btn_host.pressed.connect(_on_host_pressed)
	btn_join.pressed.connect(_on_join_pressed)
	btn_find_public.pressed.connect(_on_find_public_pressed)
	btn_invite.pressed.connect(_on_invite_pressed)
	btn_ready.pressed.connect(_on_ready_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_leave.pressed.connect(_on_leave_pressed)
	option_mode.item_selected.connect(_on_mode_selected)

	PvPConnection.lobby_created.connect(_on_lobby_created)
	PvPConnection.lobby_joined.connect(_on_lobby_joined)
	PvPConnection.lobby_join_failed.connect(_on_join_failed)
	PvPConnection.peer_connected.connect(_on_peer_connected)
	PvPConnection.peer_disconnected.connect(_on_peer_disconnected)
	PvPConnection.connection_failed.connect(_on_connection_failed)

	GlobalPvP.player_registered.connect(_refresh_player_list)
	GlobalPvP.player_left.connect(_refresh_player_list)

func _show_main_panel() -> void:
	panel_main.show()
	panel_lobby.hide()
	_set_status("")

func _show_lobby_panel() -> void:
	panel_main.hide()
	panel_lobby.show()

# ----------------------------------------------------------------
# Bottoni
# ----------------------------------------------------------------
func _on_host_pressed() -> void:
	_set_status("Creating lobby...")
	btn_host.disabled = true
	PvPConnection.create_lobby()

func _on_join_pressed() -> void:
	var raw = lobby_id_input.text.strip_edges()
	if raw == "":
		_set_status("Enter a lobby ID first.")
		return
	if not raw.is_valid_int():
		_set_status("Invalid lobby ID.")
		return
	_set_status("Joining lobby...")
	btn_join.disabled = true
	PvPConnection.join_lobby(int(raw))

func _on_find_public_pressed() -> void:
	_set_status("Searching public lobbies...")
	PvPConnection.find_public_lobbies()

func _on_invite_pressed() -> void:
	var url = PvPConnection.get_lobby_steam_url()
	DisplayServer.clipboard_set(url)
	_set_status("Lobby link copied!")

func _on_ready_pressed() -> void:
	var my_peer = PvPConnection.get_my_peer_id()
	if GlobalPvP.players.has(my_peer):
		GlobalPvP.players[my_peer]["ready"] = true
	btn_ready.disabled = true
	_set_status("Ready!")
	_refresh_player_list(my_peer)

func _on_start_pressed() -> void:
	if not PvPConnection.is_host:
		return
	if GlobalPvP.get_player_count() < 2:
		_set_status("Need at least 2 players.")
		return
	_start_match.rpc()

func _on_leave_pressed() -> void:
	PvPConnection.disconnect_from_lobby()
	_show_main_panel()
	btn_host.disabled = false
	btn_join.disabled = false

func _on_mode_selected(index: int) -> void:
	if not PvPConnection.is_host:
		return
	GlobalPvP.match_mode = "elimination" if index == 0 else "timed"

# ----------------------------------------------------------------
# PvPConnection signals
# ----------------------------------------------------------------
func _on_lobby_created(new_lobby_id: int) -> void:
	label_lobby_id.text  = "Lobby ID: " + str(new_lobby_id)
	btn_start.visible    = true
	option_mode.disabled = false
	_set_status("Lobby created! Waiting for players...")
	_show_lobby_panel()
	_refresh_player_list(-1)

func _on_lobby_joined(joined_lobby_id: int) -> void:
	label_lobby_id.text  = "Lobby ID: " + str(joined_lobby_id)
	btn_start.visible    = false
	option_mode.disabled = true
	_set_status("Joined lobby!")
	_show_lobby_panel()
	_refresh_player_list(-1)

func _on_join_failed(reason: String) -> void:
	_set_status("Join failed: " + reason)
	btn_join.disabled = false

func _on_peer_connected(_peer_id: int, _steam_id: int) -> void:
	_refresh_player_list(-1)

func _on_peer_disconnected(_peer_id: int) -> void:
	_refresh_player_list(-1)

func _on_connection_failed(reason: String) -> void:
	_set_status("Connection failed: " + reason)
	btn_host.disabled = false
	btn_join.disabled = false
	_show_main_panel()

# ----------------------------------------------------------------
# Player list
# ----------------------------------------------------------------
func _refresh_player_list(_peer_id: int) -> void:
	for child in player_list.get_children():
		child.queue_free()
	for pid in GlobalPvP.players:
		var p   = GlobalPvP.players[pid]
		var lbl = Label.new()
		lbl.text = p["name"] \
			+ (" [HOST]" if pid == 1 else "") \
			+ (" ✓" if p["ready"] else " ...")
		player_list.add_child(lbl)

# ----------------------------------------------------------------
# Match start RPC
# ----------------------------------------------------------------
@rpc("call_local", "reliable")
func _start_match() -> void:
	print("[PvPLobbyUI] Starting match!")
	GlobalPvP.reset_match()
	GlobalPvP.set_state(GlobalPvP.MatchState.COUNTDOWN)
	get_tree().change_scene_to_file(ARENA_SCENE)

func _set_status(msg: String) -> void:
	if is_instance_valid(label_status):
		label_status.text = msg
"""
