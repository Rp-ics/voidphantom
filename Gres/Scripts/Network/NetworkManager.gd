extends Node

const MAX_PLAYERS := 4
var is_host := false
var lobby_id := 0
var players := {}   # peer_id : Player instance

func _ready():
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_fail)
	Steam.run_callbacks()

func create_lobby():
	is_host = true
	Steam.create_lobby(SteamLobby.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)

func _on_lobby_created(connect, new_lobby_id):
	if connect != SteamResult.OK:
		print("Lobby creation failed")
		return
	lobby_id = new_lobby_id
	Steam.set_lobby_joinable(lobby_id, true)
	Steam.set_lobby_data(lobby_id, "name", "VoidPhantomRun")

func join_lobby(lobby_to_join):
	is_host = false
	Steam.join_lobby(lobby_to_join)

func _on_lobby_joined(lobby_id_res, result):
	if result != SteamResult.OK:
		print("Failed joining lobby")
		return
	lobby_id = lobby_id_res
	_start_network()

func _start_network():
	var peer := SteamMultiplayerPeer.new()
	peer.create_host(0) if is_host else peer.create_client(1)
	multiplayer.multiplayer_peer = peer

	if is_host:
		spawn_player(1)  # host è sempre peer 1
	else:
		rpc_id(1, "request_spawn")

@rpc("any_peer")
func request_spawn():
	if not is_host:
		return
	var id = multiplayer.get_remote_sender_id()
	spawn_player(id)

func spawn_player(peer_id:int):
	var p_scene = preload("res://Gres/Scenes/player/player.tscn")
	var p = p_scene.instantiate()
	p.peer_id = peer_id
	players[peer_id] = p
	get_node("/root/GameCoop/Entities/Players").add_child(p)

	rpc("confirm_spawn", peer_id)

@rpc("authority")
func confirm_spawn(peer_id):
	print("Spawn confirmed for: ", peer_id)

func _on_session_request(peer_id):
	Steam.accept_p2p_session(peer_id)

func _on_p2p_fail(peer_id, error):
	print("Disconnected: ", peer_id)
	players.erase(peer_id)
