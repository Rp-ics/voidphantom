extends Control

signal pve_game_started()

@onready var room_code_label = $RoomCode
@onready var player_count_label = $PlayerCount
@onready var player_list = $PlayerList
@onready var start_button = $BScroll/Grid/StartButton
@onready var leave_button = $BScroll/Grid/LeaveButton

var is_host: bool = false
var _host_check_timer: Timer
var _host_migration_in_progress: bool = false

const MAX_PLAYERS: int = 4

func _ready():
	if GlobalSteamScript.current_lobby_is_pve:
		room_code_label.text = "CO-OP ROOM: " + GlobalSteamScript.current_room_code
	else:
		room_code_label.text = "ROOM CODE: " + GlobalSteamScript.current_room_code

	GlobalSteamScript.player_joined.connect(_update_player_list)
	GlobalSteamScript.player_left.connect(_update_player_list)
	GlobalSteamScript.host_changed.connect(_on_host_changed)

	_update_host_status()
	_update_player_list()

	start_button.pressed.connect(_on_start_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	_host_check_timer = Timer.new()
	_host_check_timer.wait_time = 5.0
	_host_check_timer.timeout.connect(_check_host_change)
	add_child(_host_check_timer)
	_host_check_timer.start()

func _update_host_status():
	var local_steam_id = Steam.getSteamID()
	var lobby_owner = Steam.getLobbyOwner(GlobalSteamScript.current_lobby_id)
	is_host = (local_steam_id == lobby_owner)
	start_button.visible = is_host
	start_button.disabled = false
	start_button.text = "START CO-OP"

func _check_host_change():
	if _host_migration_in_progress:
		return
	var current_owner = Steam.getLobbyOwner(GlobalSteamScript.current_lobby_id)
	var local_id = Steam.getSteamID()
	var should_be_host = (local_id == current_owner)
	if is_host != should_be_host:
		print("[CoopLobby] Cambio host rilevato!")
		_update_host_status()

func _on_host_changed(new_host_id: int):
	print("[CoopLobby] Host cambiato a ", new_host_id)
	_update_host_status()

func _update_player_list(_unused = null):
	player_list.clear()
	var members = GlobalSteamScript.get_lobby_members()
	player_count_label.text = "PLAYERS: %d/%d" % [members.size(), MAX_PLAYERS]

	var local_id = Steam.getSteamID()
	var lobby_owner = Steam.getLobbyOwner(GlobalSteamScript.current_lobby_id)
	_update_host_status()

	for member_id in members:
		var name = Steam.getFriendPersonaName(member_id)
		var display_name = name
		if member_id == local_id:
			display_name += " [YOU]"
		if member_id == lobby_owner:
			display_name += " [HOST]"
		player_list.add_item(display_name)

func _on_start_pressed():
	if not is_host:
		return
	var members = GlobalSteamScript.get_lobby_members()
	if members.size() < 1:
		return
	start_button.disabled = true
	start_button.text = "STARTING..."
	GlobalSteamScript.start_game.rpc()

func _on_leave_pressed():
	if _host_check_timer:
		_host_check_timer.stop()
	GlobalSteamScript.leave_lobby()
	await GlobalTweens.scene_pixel_dissolve(get_tree(), "res://Gres/Scenes/UI/main_menu.tscn", 100, 0.1)

func _exit_tree():
	if _host_check_timer:
		_host_check_timer.stop()
