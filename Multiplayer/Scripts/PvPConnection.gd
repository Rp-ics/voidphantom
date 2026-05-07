extends Node
# ================================================================
# PvPConnection — Connessione Steam P2P con SteamMultiplayerPeer
# Aggiungilo in Project > Autoload come "PvPConnection"
# Richiede: https://github.com/expressobits/steam-multiplayer-peer
# ================================================================
"""
const MAX_LOBBY_MEMBERS := 4
const LOBBY_TYPE        := 2   # k_ELobbyTypePrivate

var lobby_id:    int  = 0
var is_host:     bool = false
var connected:   bool = false
var steam_ready: bool = false

signal lobby_created(lobby_id: int)
signal lobby_joined(lobby_id: int)
signal lobby_join_failed(reason: String)
signal peer_connected(peer_id: int, steam_id: int)
signal peer_disconnected(peer_id: int)
signal connection_failed(reason: String)

var steam_to_peer: Dictionary = {}
var peer_to_steam: Dictionary = {}

# ----------------------------------------------------------------
# _ready
# ----------------------------------------------------------------
func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	_init_steam_signals()

func _init_steam_signals() -> void:
	if not GlobalSteamScript.steam_initialized:
		print("[PvPConnection] Steam not initialized — PvP unavailable.")
		return
	steam_ready = true

	# Lobby signals
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_match_list.connect(_on_lobby_match_list)

	# Godot multiplayer signals
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	print("[PvPConnection] Ready. SteamMultiplayerPeer active.")

# ----------------------------------------------------------------
# HOST — crea lobby e avvia server
# ----------------------------------------------------------------
func create_lobby() -> void:
	if not steam_ready:
		emit_signal("connection_failed", "Steam not ready")
		return
	print("[PvPConnection] Creating lobby...")
	Steam.createLobby(LOBBY_TYPE, MAX_LOBBY_MEMBERS)

func _on_lobby_created(result: int, new_lobby_id: int) -> void:
	if result != 1:
		emit_signal("connection_failed", "Lobby creation failed (result " + str(result) + ")")
		return

	lobby_id = new_lobby_id
	is_host  = true
	print("[PvPConnection] Lobby created: ", lobby_id)

	# Metadata per trovare la lobby
	Steam.setLobbyData(lobby_id, "game",    "VoidPhantomPvP")
	Steam.setLobbyData(lobby_id, "version", "1.0")
	Steam.setLobbyData(lobby_id, "host",    str(Steam.getSteamID()))

	_start_as_server()
	emit_signal("lobby_created", lobby_id)

func _start_as_server() -> void:
	var peer = SteamMultiplayerPeer.new()
	var err = peer.host_with_lobby(lobby_id)
	if err != OK:
		print("[PvPConnection] ERROR host_with_lobby: ", err)
		emit_signal("connection_failed", "Could not start server (err " + str(err) + ")")
		return
	multiplayer.multiplayer_peer = peer
	connected = true
	var my_steam_id = Steam.getSteamID()
	var my_name = Steam.getFriendPersonaName(my_steam_id)
	steam_to_peer[my_steam_id] = 1
	peer_to_steam[1] = my_steam_id
	GlobalPvP.register_player(1, my_name)
	print("[PvPConnection] Server started. Host peer_id=1 name=", my_name)
	
# ----------------------------------------------------------------
# CLIENT — entra in lobby e si connette
# ----------------------------------------------------------------
func join_lobby(target_lobby_id: int) -> void:
	if not steam_ready:
		emit_signal("connection_failed", "Steam not ready")
		return
	print("[PvPConnection] Joining lobby: ", target_lobby_id)
	Steam.joinLobby(target_lobby_id)

func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != 1:
		emit_signal("lobby_join_failed", _lobby_join_error(response))
		return

	# Se siamo già l'host di questa lobby, ignora
	if is_host and joined_lobby_id == lobby_id:
		print("[PvPConnection] Already hosting this lobby — ignoring join callback.")
		return

	lobby_id = joined_lobby_id
	is_host  = false
	print("[PvPConnection] Joined lobby: ", lobby_id)
	_start_as_client()
	emit_signal("lobby_joined", lobby_id)

func _start_as_client() -> void:
	var peer = SteamMultiplayerPeer.new()
	var err = peer.connect_to_lobby(lobby_id)
	if err != OK:
		print("[PvPConnection] ERROR connect_to_lobby: ", err)
		emit_signal("connection_failed", "Could not connect to host (err " + str(err) + ")")
		return
	multiplayer.multiplayer_peer = peer
	print("[PvPConnection] Client connecting via Steam lobby: ", lobby_id)

# ----------------------------------------------------------------
# Godot Multiplayer callbacks
# ----------------------------------------------------------------
func _on_multiplayer_peer_connected(peer_id: int) -> void:
	print("[PvPConnection] Peer connected: ", peer_id)
	if is_host:
		# Chiedi al nuovo peer di registrarsi
		_request_player_info.rpc_id(peer_id)
	emit_signal("peer_connected", peer_id, peer_to_steam.get(peer_id, 0))

func _on_multiplayer_peer_disconnected(peer_id: int) -> void:
	print("[PvPConnection] Peer disconnected: ", peer_id)
	GlobalPvP.unregister_player(peer_id)
	peer_to_steam.erase(peer_id)
	emit_signal("peer_disconnected", peer_id)

func _on_connected_to_server() -> void:
	var my_peer_id  = multiplayer.get_unique_id()
	var my_steam_id = Steam.getSteamID()
	var my_name     = Steam.getFriendPersonaName(my_steam_id)
	print("[PvPConnection] Connected! peer_id=", my_peer_id, " name=", my_name)
	connected = true
	_register_self.rpc_id(1, my_steam_id, my_name, my_peer_id)

func _on_connection_failed() -> void:
	print("[PvPConnection] Connection failed.")
	connected = false
	emit_signal("connection_failed", "Could not connect to host")

func _on_server_disconnected() -> void:
	print("[PvPConnection] Server disconnected.")
	connected = false
	disconnect_from_lobby()
	emit_signal("connection_failed", "Host disconnected")

# ----------------------------------------------------------------
# RPC — registrazione giocatori
# ----------------------------------------------------------------
@rpc("any_peer", "reliable")
func _request_player_info() -> void:
	var my_steam_id = Steam.getSteamID()
	var my_name     = Steam.getFriendPersonaName(my_steam_id)
	var my_peer     = multiplayer.get_unique_id()
	_register_self.rpc_id(1, my_steam_id, my_name, my_peer)

@rpc("any_peer", "reliable")
func _register_self(steam_id: int, player_name: String, peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	print("[PvPConnection] Registered peer=", peer_id, " steam_id=", steam_id, " name=", player_name)
	steam_to_peer[steam_id] = peer_id
	peer_to_steam[peer_id]  = steam_id
	GlobalPvP.register_player(peer_id, player_name)

# ----------------------------------------------------------------
# Disconnect
# ----------------------------------------------------------------
func disconnect_from_lobby() -> void:
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
	multiplayer.multiplayer_peer = null
	connected  = false
	is_host    = false
	steam_to_peer.clear()
	peer_to_steam.clear()
	GlobalPvP.players.clear()
	GlobalPvP.set_state(GlobalPvP.MatchState.LOBBY)
	print("[PvPConnection] Disconnected.")

# ----------------------------------------------------------------
# Utility
# ----------------------------------------------------------------
func invite_friend_to_lobby(friend_steam_id: int) -> void:
	if lobby_id == 0:
		return
	Steam.inviteUserToLobby(lobby_id, friend_steam_id)
	print("[PvPConnection] Invited steam_id: ", friend_steam_id)

func find_public_lobbies() -> void:
	Steam.addRequestLobbyListStringFilter("game", "VoidPhantomPvP", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.addRequestLobbyListNumericalFilter("members", MAX_LOBBY_MEMBERS, Steam.LOBBY_COMPARISON_LESS_THAN)
	Steam.requestLobbyList()

func get_my_peer_id() -> int:
	return multiplayer.get_unique_id()

func get_lobby_steam_url() -> String:
	return "steam://joinlobby/%s/%d" % [GlobalSteamScript.APP_ID, lobby_id]

func _on_lobby_match_list(_lobbies: Array) -> void:
	pass

func _on_lobby_chat_update(_updated_lobby: int, user_changed: int, _user_making_change: int, chat_state: int) -> void:
	if chat_state in [2, 4, 8, 16]:
		var leaving_peer = steam_to_peer.get(user_changed, -1)
		if leaving_peer != -1:
			GlobalPvP.unregister_player(leaving_peer)

func _lobby_join_error(response: int) -> String:
	match response:
		2: return "Lobby doesn't exist"
		3: return "Lobby is full"
		4: return "Lobby access denied"
		_: return "Unknown error (" + str(response) + ")"
"""
