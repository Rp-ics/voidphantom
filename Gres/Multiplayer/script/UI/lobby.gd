extends Control

@onready var room_code_label = $RoomCode
@onready var player_count_label = $PlayerCount
@onready var player_list = $PlayerList
@onready var start_button = $BScroll/Grid/StartButton
@onready var leave_button = $BScroll/Grid/LeaveButton
@onready var settings_button = $BScroll/Grid/SettingsButton if has_node("BScroll/Grid/SettingsButton") else null
@onready var settings_ui = $PvPSettingsUI if has_node("PvPSettingsUI") else null
@onready var health_label = $HealthLabel if has_node("HealthLabel") else null

var is_host: bool = false
var _host_check_timer: Timer
var _matchmaking_auto_starting: bool = false

func _ready():
	if GlobalSteamScript.current_lobby_is_pve:
		room_code_label.text = "CO-OP ROOM: " + GlobalSteamScript.current_room_code
	elif GlobalSteamScript.is_matchmaking_lobby():
		room_code_label.text = "MATCHMAKING..."
	else:
		room_code_label.text = "ROOM CODE: " + GlobalSteamScript.current_room_code
	
	# Create health label for matchmaking
	if GlobalSteamScript.is_matchmaking_lobby() and health_label == null:
		_create_health_label()
	
	# Connetti segnali Steam
	GlobalSteamScript.player_joined.connect(_update_player_list)
	GlobalSteamScript.player_left.connect(_update_player_list)
	
	# Verifica iniziale host
	_update_host_status()
	_update_player_list()
	_check_matchmaking_auto_start()
	
	# Connetti pulsanti
	start_button.pressed.connect(_on_start_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	
	# Nascondi settings_ui all'inizio
	if settings_ui:
		settings_ui.visible = false
		# Connetti il segnale di chiusura se esiste
		if settings_ui.has_signal("settings_closed"):
			settings_ui.settings_closed.connect(_on_settings_closed)
	
	# Timer per aggiornare health in matchmaking
	if GlobalSteamScript.is_matchmaking_lobby():
		var health_update_timer = Timer.new()
		health_update_timer.wait_time = 0.5
		health_update_timer.one_shot = false
		health_update_timer.timeout.connect(_update_health_display)
		add_child(health_update_timer)
		health_update_timer.start()
		_update_health_display()
	
	# Timer periodico per verificare cambi di host (sicurezza extra)
	_host_check_timer = Timer.new()
	_host_check_timer.wait_time = 5.0
	_host_check_timer.timeout.connect(_check_host_change)
	add_child(_host_check_timer)
	_host_check_timer.start()
	_on_settings_closed()
	

func _update_host_status() -> void:
	var local_steam_id = Steam.getSteamID()
	var lobby_owner = Steam.getLobbyOwner(GlobalSteamScript.current_lobby_id)
	var was_host = is_host
	is_host = (local_steam_id == lobby_owner)
	
	# Aggiorna UI in base allo stato host
	start_button.visible = is_host and not GlobalSteamScript.is_matchmaking_lobby()
	start_button.disabled = false
	start_button.text = "START GAME"
	
	if settings_button:
		settings_button.visible = is_host and not GlobalSteamScript.is_matchmaking_lobby()
		# Se non sei più host, chiudi il settings_ui se aperto
		if not is_host and settings_ui and settings_ui.visible:
			settings_ui.visible = false
			print("[Lobby] Settings chiuso: non sei più host")

func _check_host_change() -> void:
	var current_owner = Steam.getLobbyOwner(GlobalSteamScript.current_lobby_id)
	var local_id = Steam.getSteamID()
	var should_be_host = (local_id == current_owner)
	
	if is_host != should_be_host:
		print("[Lobby] Cambio stato host rilevato! Vecchio: ", is_host, " Nuovo: ", should_be_host)
		_update_host_status()

func _update_player_list(_unused = null):
	player_list.clear()
	var members = GlobalSteamScript.get_lobby_members()
	var max_players := 4 if GlobalSteamScript.current_lobby_is_pve else (2 if GlobalSteamScript.is_matchmaking_lobby() else 4)
	player_count_label.text = "PLAYERS: %d/%d" % [members.size(), max_players]
	
	var local_id = Steam.getSteamID()
	var lobby_owner = Steam.getLobbyOwner(GlobalSteamScript.current_lobby_id)
	
	# Aggiorna anche lo stato host quando aggiorni la lista giocatori
	_update_host_status()
	
	for member_id in members:
		var name = Steam.getFriendPersonaName(member_id)
		var display_name = name
		
		if member_id == local_id:
			display_name += " [YOU]"
		
		if member_id == lobby_owner:
			display_name += " [HOST]"
		
		player_list.add_item(display_name)

	_check_matchmaking_auto_start()

func _on_start_pressed() -> void:
	# Verifica che sia effettivamente l'host
	if not is_host:
		push_warning("[Lobby] Tentativo di start da non-host. Bloccato.")
		return
	
	# Verifica numero minimo giocatori (opzionale)
	var members = GlobalSteamScript.get_lobby_members()
	var min_players = 1 if GlobalSteamScript.current_lobby_is_pve else 2
	if members.size() < min_players:
		push_warning("[Lobby] Minimo %d giocatori richiesti per iniziare." % min_players)
		start_button.disabled = false
		start_button.text = "START CO-OP" if GlobalSteamScript.current_lobby_is_pve else "START GAME"
		return
	
	start_button.disabled = true
	start_button.text = "STARTING..."
	
	# Chiudi settings se aperto prima di avviare
	if settings_ui and settings_ui.visible:
		settings_ui.visible = false
	
	GlobalSteamScript.start_game.rpc()

func _check_matchmaking_auto_start() -> void:
	GlobalTweens.button_disable($LobbySetitings)
	if _matchmaking_auto_starting:
		return

	# Check if it's a bot match (from timeout)
	if MatchmakingManager.is_bot_match:
		_matchmaking_auto_starting = true
		GameModes.set_mode(GameModes.GameMode.CLASSIC)
		GameModes.save_settings()
		if start_button:
			start_button.visible = true
			start_button.disabled = true
			start_button.text = "MATCH FOUND..."
		if settings_button:
			settings_button.visible = false
		MatchmakingManager.notify_match_started()
		await get_tree().create_timer(0.5).timeout
		GlobalSteamScript.start_game()
		return

	if not GlobalSteamScript.is_matchmaking_lobby():
		return
	if not is_host:
		start_button.visible = false
		if settings_button:
			settings_button.visible = false
		return

	var members = GlobalSteamScript.get_lobby_members()
	if members.size() < 2:
		start_button.visible = false
		if settings_button:
			settings_button.visible = false
		return

	_matchmaking_auto_starting = true
	GameModes.set_mode(GameModes.GameMode.CLASSIC)
	GameModes.save_settings()
	Steam.setLobbyData(GlobalSteamScript.current_lobby_id, "status", "full")
	if start_button:
		start_button.visible = true
		start_button.disabled = true
		start_button.text = "MATCH FOUND..."
	if settings_button:
		settings_button.visible = false
	MatchmakingManager.notify_match_started()
	await get_tree().create_timer(1.5).timeout
	GlobalSteamScript.start_game.rpc()

func _on_leave_pressed() -> void:
	# Ferma il timer prima di cambiare scena
	if _host_check_timer:
		_host_check_timer.stop()
	
	# Chiudi settings se aperto
	if settings_ui and settings_ui.visible:
		settings_ui.visible = false
	
	GlobalSteamScript.leave_lobby()
	await GlobalTweens.scene_pixel_dissolve(get_tree(), "res://Gres/Scenes/UI/main_menu.tscn", 100, 0.1)
	
func _on_settings_pressed() -> void:
	# Doppio guard: is_host sul peer locale e controllo Steam owner
	var local_steam_id = Steam.getSteamID()
	var lobby_owner = Steam.getLobbyOwner(GlobalSteamScript.current_lobby_id)
	
	if local_steam_id != lobby_owner:
		push_warning("[Lobby] Client ha tentato di aprire Settings. Bloccato.")
		return
	
	if not settings_ui:
		return
	
	# Toggle visibility
	if settings_ui.visible:
		settings_ui.visible = false
		start_button.disabled = false  # Riabilita start quando chiudi settings
	else:
		# Disabilita start mentre settings è aperto
		start_button.disabled = true
		settings_ui.show_panel()

func _on_settings_closed() -> void:
	# Riabilita il pulsante start quando il pannello settings viene chiuso
	if is_host:
		GlobalTweens.button_enable($LobbySetitings)

func _exit_tree() -> void:
	# Cleanup
	if _host_check_timer:
		_host_check_timer.stop()

func _create_health_label() -> void:
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.theme_override_font_sizes.font_size = 28
	health_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	health_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	health_label.theme_override_constants.outline_size = 2
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.offset_left = 0
	health_label.offset_top = 520.0
	health_label.offset_right = 1152.0
	health_label.offset_bottom = 580.0
	add_child(health_label)

func _update_health_display() -> void:
	if health_label and GlobalSteamScript.is_matchmaking_lobby():
		health_label.text = "YOUR HP: %d / %d" % [Global.player_hp, Global.player_max_hp]
	elif health_label:
		health_label.queue_free()
		health_label = null
