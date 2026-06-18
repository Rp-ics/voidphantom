extends Node2D

# ==============================================================
# MU_ARENA — CLASSIC + POINT + KING + PROGRESSION + PVE
# ==============================================================

@onready var player_spawner    := $PlayerSpawner as MultiplayerSpawner
@onready var players_container := $Players
@onready var score_manager     := $PointScoreManager as Node

@onready var info_label           := $UI/InfoLabel               if has_node("UI/InfoLabel")               else null
@onready var game_over_panel      := $UI/GameOverPanel            if has_node("UI/GameOverPanel")            else null
@onready var winner_label         := $UI/GameOverPanel/WinnerLabel if has_node("UI/GameOverPanel/WinnerLabel") else null
@onready var back_to_menu_button  := $UI/GameOverPanel/BackToMenuButton if has_node("UI/GameOverPanel/BackToMenuButton") else null
@onready var hp_bar               := $UI/PlayerUI/HPBar
@onready var stm_bar              := $UI/PlayerUI/STMBar
@onready var hp_label             := $UI/PlayerUI/HPBar/HPCounter
@onready var stm_label            := $UI/PlayerUI/STMBar/STCounter
@onready var bull_bar             := $UI/PlayerUI/BulletsBar
@onready var profile_img          := $UI/PlayerUI/PFPBG/PFPIcon
@onready var player_name_label    := $UI/PlayerUI/PFPBG/player_name
@onready var mode_label           := $UI/ModeLabel               if has_node("UI/ModeLabel")               else null
@onready var timer_display        := $UI/TimerDisplay             if has_node("UI/TimerDisplay")             else null
@onready var score_board          := $UI/ScoreBoard               if has_node("UI/ScoreBoard")               else null

# Enemy UI (for PvP) - questi nodi DEVONO esistere nella scena
@onready var enemy_ui              := $UI/EnemyUI              if has_node("UI/EnemyUI")              else null
@onready var enemy_hp_bar          := $UI/EnemyUI/HPBar        if has_node("UI/EnemyUI/HPBar")        else null
@onready var enemy_stm_bar         := $UI/EnemyUI/STMBar       if has_node("UI/EnemyUI/STMBar")       else null
@onready var enemy_hp_label        := $UI/EnemyUI/HPBar/HPCounter if has_node("UI/EnemyUI/HPBar/HPCounter") else null
@onready var enemy_stm_label       := $UI/EnemyUI/STMBar/STCounter if has_node("UI/EnemyUI/STMBar/STCounter") else null
@onready var enemy_profile_img     := $UI/EnemyUI/PFPBG/PFPIcon if has_node("UI/EnemyUI/PFPBG/PFPIcon") else null
@onready var enemy_name_label      := $UI/EnemyUI/PFPBG/player_name if has_node("UI/EnemyUI/PFPBG/player_name") else null

const PLAYER_SCENE  := preload("res://Gres/Multiplayer/scene/Players/mp_player.tscn")
const PVE_RESPAWN_DELAY := 10.0
const RESPAWN_DELAY := 3.0

var spawn_positions: Array[Vector2] = [
	Vector2(300, 250),
	Vector2(700, 250),
	Vector2(300, 550),
	Vector2(700, 550),
	Vector2(100, 400),
	Vector2(900, 400),
	Vector2(500, 150),
	Vector2(500, 650),
]

# King of the Hill state (server only)
var _king_zone_pos:     Vector2 = Vector2(500, 400)
var _king_zone_timer:   float   = 0.0
var _king_zone_node:    Node2D  = null

var alive_players:        Dictionary = {}
var game_timer:           Timer      = null
var game_over_triggered:  bool       = false
var game_started:         bool       = false
var game_ended:           bool       = false
var peers_ready_in_scene: Array[int] = []
var match_winner_id:      int        = -1
var match_start_time:     float      = 0.0
var return_requested:     bool       = false
var returning_to_lobby:   bool       = false
var match_ended:          bool       = false
var progression_label:    RichTextLabel = null

# PvE Endless Mode
var _wave_manager: Node = null
var _pve_gold: int = 0
var _pve_wave_label: Label = null
var _pve_boss_hp_bar: TextureProgressBar = null
var _pve_boss_hp_label: Label = null
var _pve_gold_label: Label = null
var _pve_wave_timer_label: Label = null
var _pve_game_over_triggered: bool = false
var _pve_respawn_queue: Dictionary = {}
var _pve_is_wave_in_progress: bool = false
var _host_migration_done: bool = false

# PvP Bots
var _bot_peer_id_counter: int = -2
var _bot_controllers: Array[Node] = []
var _consecutive_medium_bots: int = 0

# ==============================================================
# READY
# ==============================================================

func _ready() -> void:
	player_name_label.text = str(GlobalSteamScript.player_name)
	var img := "res://Gres/Assets/Icons/pfp/pfp_%s.png" % Global.texture_pfp_icon
	profile_img.texture = load(img)

	player_spawner.spawn_function = _create_player
	player_spawner.spawned.connect(_on_player_spawned)

	if game_over_panel:
		game_over_panel.visible = false
	
	if score_board:
		score_board.visible = GameModes.is_score_mode()
	
	if GameModes.is_pve_mode():
		_setup_pve_ui()
		_setup_wave_manager()
	else:
		_create_progression_hud()
		# Mostra la UI nemica per combattimenti PvP / 1v1
		if enemy_ui:
			enemy_ui.visible = true

	if back_to_menu_button:
		back_to_menu_button.pressed.connect(_on_return_to_lobby_pressed)
		back_to_menu_button.visible = false
		back_to_menu_button.text    = "RETURN TO LOBBY"

	if score_manager and score_manager.has_signal("scores_updated"):
		score_manager.scores_updated.connect(_on_scores_updated)

	if info_label:
		info_label.text = "ROOM: " + GlobalSteamScript.current_room_code
	
	if mode_label:
		mode_label.text = GameModes.get_mode_name()

	if MatchmakingManager.is_bot_match:
		call_deferred("_start_bot_match")
	elif multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		multiplayer.peer_connected.connect(_on_peer_connected)

		peers_ready_in_scene.append(1)
		_check_all_peers_ready()

		var timeout_timer := Timer.new()
		timeout_timer.wait_time = 15.0
		timeout_timer.one_shot  = true
		timeout_timer.timeout.connect(func():
			if players_container.get_child_count() == 0:
				print("[Arena] Timeout attesa peer, spawn forzato.")
				_spawn_all_players()
		)
		add_child(timeout_timer)
		timeout_timer.start()
	else:
		_notify_host_ready.rpc_id(1)

# ==============================================================
# PROCESS — UI ogni frame
# ==============================================================

func _process(_delta: float) -> void:
	hp_bar.max_value   = Global.player_max_hp
	hp_bar.value       = Global.player_hp
	stm_bar.max_value  = Global.player_max_stamina
	stm_bar.value      = Global.player_stamina
	hp_label.text      = str(int(Global.player_hp))
	stm_label.text     = str(int(Global.player_stamina))
	bull_bar.max_value = Global.max_bullets
	bull_bar.value     = Global.bullets

	if timer_display and game_started and not game_ended:
		if GameModes.is_pve_mode():
			timer_display.text = "WAVE %d" % (_wave_manager.current_wave if _wave_manager else 1)
		else:
			var elapsed:   int = int(Time.get_ticks_msec() / 1000.0 - match_start_time)
			var remaining: int = max(0, GameModes.match_duration - elapsed)
			var minutes:   int = remaining / 60
			var seconds:   int = remaining % 60
			timer_display.text = "%02d:%02d" % [minutes, seconds]

	_update_progression_hud()
	_update_enemy_ui()

	if GameModes.is_pve_mode() and _pve_gold_label:
		_pve_gold_label.text = "GOLD: %d" % _pve_gold

	if GameModes.is_pve_mode() and _wave_manager:
		var boss_node = _get_pve_boss_node()
		if boss_node and is_instance_valid(boss_node):
			if _pve_boss_hp_bar:
				_pve_boss_hp_bar.max_value = boss_node.max_hp
				_pve_boss_hp_bar.value = max(0, boss_node.hp)
				_pve_boss_hp_bar.visible = true
			if _pve_boss_hp_label:
				_pve_boss_hp_label.text = "BOSS: %d/%d" % [max(0, int(boss_node.hp)), int(boss_node.max_hp)]
		else:
			if _pve_boss_hp_bar:
				_pve_boss_hp_bar.visible = false

func _get_pve_boss_node() -> Node:
	if not _wave_manager:
		return null
	for child in _wave_manager.get_children():
		var is_boss = false
		if child.has_method("is_boss"):
			is_boss = child.is_boss()
		elif child.has_meta("is_boss"):
			is_boss = child.get_meta("is_boss")
		elif "is_boss" in child:
			is_boss = child.is_boss
		
		if not is_boss:
			continue
		
		var hp = 0.0
		if child.has_method("get_hp"):
			hp = child.get_hp()
		elif child.has_meta("hp"):
			hp = child.get_meta("hp")
		elif "hp" in child:
			hp = child.hp
		
		if hp > 0:
			return child
	return null

# ==============================================================
# PEER MANAGEMENT
# ==============================================================

func _on_peer_connected(peer_id: int) -> void:
	print("[Arena] Peer connesso: ", peer_id)

@rpc("any_peer", "call_local", "reliable")
func _notify_host_ready() -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id not in peers_ready_in_scene:
		peers_ready_in_scene.append(sender_id)
		print("[Arena] Peer %d ready in scene." % sender_id)
		_check_all_peers_ready()

func _check_all_peers_ready() -> void:
	var expected: int = max(1, GlobalSteamScript.expected_players_count)
	print("[Arena] Checking ready: %d/%d" % [peers_ready_in_scene.size(), expected])
	if peers_ready_in_scene.size() >= expected:
		_sync_game_settings.rpc(GameModes.current_mode, GameModes.match_duration)
		_spawn_all_players()
		_start_match_countdown.rpc()

@rpc("authority", "reliable", "call_local")
func _sync_game_settings(mode: int, duration: int) -> void:
	GameModes.set_mode(mode as GameModes.GameMode)
	GameModes.set_duration(duration)
	if mode_label:
		mode_label.text = GameModes.get_mode_name()
	if score_board:
		score_board.visible = GameModes.is_score_mode()
	_create_progression_hud()

func _on_peer_disconnected(peer_id: int) -> void:
	print("[Arena] Peer disconnesso: ", peer_id)
	var player_node := players_container.get_node_or_null("Player_" + str(peer_id))
	if player_node:
		player_node.queue_free()

	if not GameModes.is_pve_mode() and not game_ended:
		call_deferred("_spawn_bot")

	if GameModes.is_pve_mode():
		alive_players.erase(peer_id)
		_update_info_display()
		_check_pve_game_over()
	elif GameModes.is_classic_mode():
		if not game_over_triggered and alive_players.has(peer_id):
			alive_players.erase(peer_id)
			_check_game_over_classic()
	else:
		alive_players.erase(peer_id)
		_update_info_display()

# ==============================================================
# SPAWN
# ==============================================================

func _spawn_all_players() -> void:
	if players_container.get_child_count() > 0:
		return
	var all_peers := [1]
	all_peers.append_array(Array(multiplayer.get_peers()))

	print("[Arena] Spawning players for peers: ", all_peers, " my ID: ", multiplayer.get_unique_id())

	for peer_id in all_peers:
		alive_players[peer_id] = true
	
	for i in range(all_peers.size()):
		var peer_id: int   = all_peers[i]
		var pos: Vector2   = spawn_positions[i % spawn_positions.size()]
		print("[Arena] Spawning peer ", peer_id, " at ", pos)
		player_spawner.spawn([peer_id, pos])
	
	_update_info_display()

func _create_player(data: Array) -> Node:
	var peer_id:   int     = data[0]
	var spawn_pos: Vector2 = data[1]
	var player: Node = PLAYER_SCENE.instantiate()
	player.name = "Player_%d" % peer_id
	player.position = spawn_pos
	player.set_multiplayer_authority(peer_id)
	player.is_local_player = (peer_id == multiplayer.get_unique_id())

	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died.bind(peer_id))

	alive_players[peer_id] = true
	player.can_move  = false
	player.can_shoot = false
	player.can_be_damaged = false
	
	if GameModes.is_progression_mode() and player.has_method("setup_progression_weapon"):
		player.setup_progression_weapon(0)
	
	return player

func _on_player_spawned(node: Node) -> void:
	print("[Arena] Player spawned → %s | locale: %s | authority: %s" % [node.name, node.is_local_player, node.get_multiplayer_authority()])
	_update_info_display()

func _start_bot_match():
	MatchmakingManager.is_bot_match = false
	GameModes.set_mode(GameModes.GameMode.CLASSIC)

	if multiplayer.multiplayer_peer == null:
		var enet_peer = ENetMultiplayerPeer.new()
		enet_peer.create_server(0, 4)
		multiplayer.multiplayer_peer = enet_peer
		print("[Arena] Bot match: local ENet peer created, my ID = ", multiplayer.get_unique_id())

	await get_tree().process_frame

	_spawn_all_players()
	_ensure_bot_players(1)

	for player in players_container.get_children():
		if player.has_method("set_can_be_damaged"):
			player.set_can_be_damaged(true)
		else:
			player.can_be_damaged = true

func _ensure_bot_players(count: int) -> void:
	for j in range(count):
		_spawn_bot()

func _get_next_bot_peer_id() -> int:
	var id = _bot_peer_id_counter
	_bot_peer_id_counter -= 1
	return id

func _get_bot_difficulty() -> int:
	var diff = randi() % 2
	if diff == 0:
		_consecutive_medium_bots += 1
		if _consecutive_medium_bots >= 3:
			_consecutive_medium_bots = 0
			return 1
	return diff

func _spawn_bot():
	var bot_id = _get_next_bot_peer_id()
	var pos_idx = players_container.get_child_count() % spawn_positions.size()
	var pos = spawn_positions[pos_idx]
	
	var player = PLAYER_SCENE.instantiate()
	player.name = "Player_%d" % bot_id
	player.position = pos
	player.set_multiplayer_authority(bot_id)
	player.is_local_player = false
	player.is_bot = true
	player.bot_controlled = true
	player.mp_peer_id = bot_id
	player.can_be_damaged = true
	
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died.bind(bot_id))
	
	alive_players[bot_id] = true
	player.can_move = false
	player.can_shoot = false
	players_container.add_child(player)
	
	if GameModes.is_progression_mode() and player.has_method("setup_progression_weapon"):
		player.setup_progression_weapon(0)
	
	var weapon = PVPBot.get_random_pvp_weapon()
	var skin = PVPBot.generate_random_skin()
	var pname = PVPBot.get_unique_bot_name()
	var diff = _get_bot_difficulty()
	var difficulty_enum = PVPBot.Difficulty.HARD if diff == 1 else PVPBot.Difficulty.MEDIUM
	
	var bot_ctrl = PVPBotController.new()
	bot_ctrl._init_bot(player, bot_id, difficulty_enum, weapon, skin, pname)
	add_child(bot_ctrl)
	_bot_controllers.append(bot_ctrl)
	
	player.mp_player_name = pname

	if multiplayer.is_server():
		_notify_bot_ready.rpc(bot_id)

@rpc("authority", "call_local", "reliable")
func _notify_bot_ready(bot_id: int):
	pass

func _remove_all_bots():
	for ctrl in _bot_controllers:
		if is_instance_valid(ctrl):
			var p = ctrl.player
			if is_instance_valid(p):
				p.queue_free()
			ctrl.queue_free()
	_bot_controllers.clear()

# ==============================================================
# BULLET TRACKING (POINT & KING mode, server only)
# ==============================================================

func _ready_point_tracking() -> void:
	get_tree().current_scene.child_entered_tree.connect(_on_scene_child_entered)

func _on_scene_child_entered(node: Node) -> void:
	if not multiplayer.is_server(): return
	if not (GameModes.is_point_mode() or GameModes.is_king_mode()): return
	if not node.is_in_group("p_bullet"): return
	await get_tree().process_frame
	if not is_instance_valid(node): return
	if node.has_signal("damage_dealt") and not node.damage_dealt.is_connected(_on_bullet_damage_dealt):
		node.damage_dealt.connect(_on_bullet_damage_dealt)

func _on_bullet_damage_dealt(shooter_id: int, target_id: int, _damage: float) -> void:
	if not multiplayer.is_server(): return
	if not (GameModes.is_point_mode() or GameModes.is_king_mode()): return

	var target_node := players_container.get_node_or_null("Player_%d" % target_id)
	if is_instance_valid(target_node):
		if target_node.get("mp_is_dead") == true or target_node.get("can_be_damaged") == false:
			return

	if shooter_id == 0 or shooter_id == target_id:
		return
	
	if GameModes.is_point_mode():
		score_manager.register_hit(shooter_id, target_id)

# ==============================================================
# COUNTDOWN E START
# ==============================================================

@rpc("authority", "reliable", "call_local")
func _start_match_countdown() -> void:
	_start_countdown_sequence()

func _start_countdown_sequence() -> void:
	var countdown_label := Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.add_theme_font_size_override("font_size", 64)
	countdown_label.add_theme_color_override("font_color", Color.YELLOW)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	countdown_label.position = get_viewport_rect().size / 2 - Vector2(50, 50)
	add_child(countdown_label)

	var countdown := 3
	while countdown > 0:
		countdown_label.text = str(countdown)
		await get_tree().create_timer(1.0).timeout
		countdown -= 1
	countdown_label.text = "GO!"
	await get_tree().create_timer(0.5).timeout
	countdown_label.queue_free()

	_start_match()

	for child in players_container.get_children():
		child.can_move  = true
		child.can_shoot = true
		if child.has_method("apply_buff"):
			child.apply_buff("invincible", 3.0)

func _start_match() -> void:
	if multiplayer.is_server():
		var server_time: float = Time.get_ticks_msec() / 1000.0
		_sync_match_start_time.rpc(server_time)

		if GameModes.is_pve_mode():
			_wave_manager.start_game()
			return

		var peer_ids: Array = []
		peer_ids.append_array(alive_players.keys())

		if GameModes.is_point_mode():
			score_manager.init(peer_ids, true)
			_ready_point_tracking()

		if GameModes.is_king_mode():
			score_manager.init(peer_ids, false)
			_ready_point_tracking()
			_king_zone_pos = spawn_positions[randi() % spawn_positions.size()]
			_spawn_king_zone.rpc(_king_zone_pos)

		if GameModes.is_progression_mode():
			score_manager.init(peer_ids, false)
			_reset_all_progression_weapons()

		game_timer           = Timer.new()
		game_timer.name      = "GameTimer"
		game_timer.wait_time = 1.0
		game_timer.timeout.connect(_on_game_tick)
		add_child(game_timer)
		game_timer.start()

@rpc("authority", "reliable", "call_local")
func _sync_match_start_time(server_time: float) -> void:
	match_start_time = server_time
	game_started     = true
	print("[Arena] match_start_time sincronizzato: ", server_time)

# ==============================================================
# GAME TICK (server only)
# ==============================================================

func _on_game_tick() -> void:
	if not multiplayer.is_server(): 
		return
	var elapsed:   int = int(Time.get_ticks_msec() / 1000.0 - match_start_time)
	var remaining: int = GameModes.match_duration - elapsed
	if remaining <= 0 and not game_ended:
		_handle_timeout()
		return

	if GameModes.is_king_mode() and not game_ended:
		_king_zone_timer += 1.0

		for child in players_container.get_children():
			if child.get("mp_is_dead") == true: 
				continue
			var pid = child.get_multiplayer_authority()
			if child is Node2D:
				var dist = child.global_position.distance_to(_king_zone_pos)
				if dist <= GameModes.KING_ZONE_RADIUS:
					score_manager.register_king_zone(pid)

		if _king_zone_timer >= GameModes.KING_ZONE_MOVE_INTERVAL:
			_king_zone_timer = 0.0
			var new_pos = _pick_zone_position()
			_king_zone_pos = new_pos
			_spawn_king_zone.rpc(new_pos)

func _pick_zone_position() -> Vector2:
	var arena_bounds := Rect2(150, 150, 700, 500)
	var x = arena_bounds.position.x + randf() * arena_bounds.size.x
	var y = arena_bounds.position.y + randf() * arena_bounds.size.y
	return Vector2(x, y)

class _KingZoneNode extends Node2D:
	var zone_radius: float = 100.0
	
	func _ready() -> void:
		queue_redraw()
	
	func _draw():
		draw_circle(Vector2.ZERO, zone_radius, Color(0.2, 0.5, 0.8, 0.3))
		draw_arc(Vector2.ZERO, zone_radius, 0, TAU, 64, Color.CYAN, 2.0)

@rpc("authority", "call_local", "reliable")
func _spawn_king_zone(pos: Vector2) -> void:
	if is_instance_valid(_king_zone_node):
		_king_zone_node.queue_free()
		_king_zone_node = null

	var zone = _KingZoneNode.new()
	zone.zone_radius = GameModes.KING_ZONE_RADIUS
	zone.position = pos
	add_child(zone)
	_king_zone_node = zone

# ==============================================================
# PVE RESPAWN
# ==============================================================

func _schedule_pve_respawn(peer_id: int):
	print("[Arena] PvE respawn per peer %d tra %.1f sec" % [peer_id, PVE_RESPAWN_DELAY])
	if peer_id != 1:
		_notify_pve_respawn.rpc_id(peer_id, PVE_RESPAWN_DELAY)

	await get_tree().create_timer(PVE_RESPAWN_DELAY).timeout
	if game_ended:
		return
	if not alive_players.has(peer_id):
		return
	_do_pve_respawn(peer_id)

@rpc("authority", "reliable")
func _notify_pve_respawn(delay: float):
	print("[Arena] PvE respawn in %.1f secondi..." % delay)

func _do_pve_respawn(peer_id: int):
	if not multiplayer.is_server():
		return
	var occupied: Array[Vector2] = []
	for child in players_container.get_children():
		if child is Node2D and is_instance_valid(child):
			occupied.append(child.global_position)
	var respawn_pos := _find_free_spawn(occupied)

	var player_node := players_container.get_node_or_null("Player_%d" % peer_id)
	if not is_instance_valid(player_node):
		player_spawner.spawn([peer_id, respawn_pos])
	else:
		player_node.rpc_reset_visuals.rpc()
		player_node.rpc_do_respawn.rpc(respawn_pos)

	alive_players[peer_id] = true
	_update_info_display()

func _check_pve_game_over():
	if not multiplayer.is_server():
		return
	if _pve_game_over_triggered:
		return
	var alive_count := 0
	for pid in alive_players:
		if alive_players[pid] == true:
			alive_count += 1
	print("[Arena] PvE giocatori vivi: ", alive_count, "/", alive_players.size())
	if alive_count == 0:
		_end_pve_game()

func _end_pve_game():
	if _pve_game_over_triggered:
		return
	_pve_game_over_triggered = true
	game_ended = true
	print("[Arena] PvE GAME OVER! Onda raggiunta: %d" % _wave_manager.current_wave if _wave_manager else 1)

	if _wave_manager:
		GlobalStats.pve_waves_survived = _wave_manager.current_wave
		if _wave_manager.current_wave > GlobalStats.pve_best_wave:
			GlobalStats.pve_best_wave = _wave_manager.current_wave
	GlobalStats.save_data_stats()

	if multiplayer.is_server():
		_pve_game_over.rpc(_wave_manager.current_wave if _wave_manager else 1, _pve_gold)

@rpc("reliable", "call_local")
func _pve_game_over(final_wave: int, gold_earned: int):
	print("[PvE Game Over] Onda: ", final_wave, " Oro: ", gold_earned)

	for player_node in players_container.get_children():
		player_node.set_physics_process(false)
		player_node.set_process(false)
		if "can_shoot" in player_node:
			player_node.can_shoot = false

	if game_over_panel:
		game_over_panel.visible = true
	if winner_label:
		winner_label.text = "GAME OVER\nWave %d\nGold Earned: %d\n\nThanks for playing!" % [final_wave, gold_earned]
		winner_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	if back_to_menu_button:
		back_to_menu_button.visible = true
		back_to_menu_button.text = "RETURN TO MENU"

	GlobalStats.pve_waves_survived = final_wave
	GlobalStats.save_data_stats()

# ==============================================================
# PVE HOST MIGRATION
# ==============================================================

func _on_host_migrated():
	print("[Arena] Host migration ricevuta")
	if not multiplayer.is_server():
		return
	if not GameModes.is_pve_mode():
		return
	_host_migration_done = true
	print("[Arena] Nuovo host: riavvio ondata corrente")
	if _wave_manager:
		_wave_manager.start_game()

func _update_enemy_ui() -> void:
	if not is_instance_valid(enemy_ui) or not enemy_ui.visible:
		return
	var enemy: Node = null
	for child in players_container.get_children():
		if child.get("is_local_player") == false:
			enemy = child
			break
	if is_instance_valid(enemy):
		if enemy_hp_bar:
			enemy_hp_bar.max_value = enemy.get("mp_max_hp") if enemy.get("mp_max_hp") != null else 100.0
			enemy_hp_bar.value = enemy.get("mp_synced_hp") if enemy.get("mp_synced_hp") != null else 0.0
		if enemy_stm_bar:
			enemy_stm_bar.max_value = enemy.get("mp_max_stamina") if enemy.get("mp_max_stamina") != null else 100.0
			enemy_stm_bar.value = enemy.get("mp_stamina") if enemy.get("mp_stamina") != null else 0.0
		if enemy_hp_label:
			enemy_hp_label.text = str(int(enemy.get("mp_synced_hp") if enemy.get("mp_synced_hp") != null else 0))
		if enemy_stm_label:
			enemy_stm_label.text = str(int(enemy.get("mp_stamina") if enemy.get("mp_stamina") != null else 0))
		if enemy_name_label:
			enemy_name_label.text = enemy.get("mp_player_name") if enemy.get("mp_player_name") != null else "Enemy"
		if enemy_profile_img and enemy.get("texture_pfp_icon") != null:
			var icon_id = enemy.get("texture_pfp_icon")
			var img_path = "res://Gres/Assets/Icons/pfp/pfp_%s.png" % str(icon_id)
			if ResourceLoader.exists(img_path):
				enemy_profile_img.texture = load(img_path)

func _handle_timeout() -> void:
	var winner_id: int
	if GameModes.is_score_mode():
		winner_id = score_manager.get_winner_id()
	else:
		winner_id = _get_player_with_highest_hp()
	_end_game(winner_id)

func _get_player_with_highest_hp() -> int:
	var best_id := -1
	var best_hp := -1.0
	for child in players_container.get_children():
		if child.has_method("get_current_hp"):
			var hp: float = child.get_current_hp()
			if hp > best_hp:
				best_hp = hp
				best_id = child.get_multiplayer_authority()
	return best_id

# ==============================================================
# MORTE GIOCATORE
# ==============================================================

func _on_player_died(peer_id: int) -> void:
	print("[Arena] Player morto: ", peer_id)
	if not multiplayer.is_server():
		return

	if GameModes.is_pve_mode():
		alive_players[peer_id] = false
		_update_info_display()
		_schedule_pve_respawn(peer_id)
		_check_pve_game_over()
		return

	var killer_id: int = _get_last_killer(peer_id)

	if GameModes.is_point_mode():
		if killer_id != -1 and killer_id != peer_id:
			score_manager.register_kill(killer_id, peer_id)
		score_manager.register_death(peer_id)
		alive_players[peer_id] = false
		_update_info_display()
		_schedule_respawn(peer_id)
	elif GameModes.is_king_mode():
		if killer_id != -1 and killer_id != peer_id:
			score_manager.register_king_kill(killer_id, peer_id)
		score_manager.register_king_death(peer_id)
		alive_players[peer_id] = false
		_update_info_display()
		_schedule_respawn(peer_id)
	elif GameModes.is_progression_mode():
		if killer_id != -1 and killer_id != peer_id:
			score_manager.register_progression_kill(killer_id, peer_id)
			_handle_progression_kill(killer_id)
		score_manager.register_progression_death(peer_id)
		_handle_progression_death(peer_id)
		alive_players[peer_id] = false
		_update_info_display()
		if not game_ended:
			_schedule_respawn(peer_id)
	else:  # CLASSIC
		if game_over_triggered: 
			return
		alive_players[peer_id] = false
		_update_info_display()
		_check_game_over_classic()

func _get_last_killer(dead_peer_id: int) -> int:
	var player_node := players_container.get_node_or_null("Player_%d" % dead_peer_id)
	if is_instance_valid(player_node) and player_node.has_meta("last_hit_by"):
		return int(player_node.get_meta("last_hit_by"))
	return -1

# ==============================================================
# PROGRESSION - GUN GAME
# ==============================================================

func _reset_all_progression_weapons() -> void:
	for child in players_container.get_children():
		if child.has_method("rpc_set_progression_weapon"):
			child.rpc_set_progression_weapon.rpc(0)

func _handle_progression_kill(killer_id: int) -> void:
	if game_ended:
		return
	var killer_node := _get_player_node_by_peer_id(killer_id)
	if not is_instance_valid(killer_node):
		return
	if killer_node.has_method("is_at_final_progression_weapon") and killer_node.is_at_final_progression_weapon():
		_end_game(killer_id)
		return
	if killer_node.has_method("upgrade_weapon"):
		killer_node.upgrade_weapon()
		if killer_node.has_method("rpc_set_progression_weapon"):
			killer_node.rpc_set_progression_weapon.rpc(killer_node.get("progression_weapon_index"))
	
	var current_hp = killer_node.get("progression_hp")
	if current_hp == null:
		current_hp = 50.0
	var new_hp = min(current_hp + 10.0, 500.0)
	if killer_node.has_method("rpc_set_progression_hp"):
		killer_node.rpc_set_progression_hp.rpc(new_hp)

func _handle_progression_death(dead_id: int) -> void:
	var dead_node := _get_player_node_by_peer_id(dead_id)
	if not is_instance_valid(dead_node):
		return
	if dead_node.has_method("downgrade_weapon"):
		dead_node.downgrade_weapon()
		if dead_node.has_method("rpc_set_progression_weapon"):
			dead_node.rpc_set_progression_weapon.rpc(dead_node.get("progression_weapon_index"))
	
	var current_hp = dead_node.get("progression_hp")
	if current_hp == null:
		current_hp = 50.0
	var new_hp = max(current_hp - 5.0, 50.0)
	if dead_node.has_method("rpc_set_progression_hp"):
		dead_node.rpc_set_progression_hp.rpc(new_hp)

func _create_progression_hud() -> void:
	if progression_label or not has_node("UI"):
		return
	progression_label = RichTextLabel.new()
	progression_label.name = "ProgressionWeaponLabel"
	progression_label.bbcode_enabled = true
	progression_label.fit_content = true
	progression_label.scroll_active = false
	progression_label.visible = GameModes.is_progression_mode()
	progression_label.offset_left = 875.0
	progression_label.offset_top = 345.0
	progression_label.offset_right = 1152.0
	progression_label.offset_bottom = 445.0
	progression_label.add_theme_font_size_override("normal_font_size", 18)
	$UI.add_child(progression_label)

# ==============================================================
# PVE UI SETUP
# ==============================================================

func _setup_pve_ui():
	if not has_node("UI"):
		return
	var ui = $UI

	_wave_manager = Node.new()
	_wave_manager.name = "PVEWaveManager"
	_wave_manager.set_script(preload("res://Gres/Multiplayer/script/pve/PVEWaveManager.gd"))
	add_child(_wave_manager)

	_wave_manager.wave_started.connect(_on_pve_wave_started)
	_wave_manager.wave_cleared.connect(_on_pve_wave_cleared)
	_wave_manager.boss_spawned.connect(_on_pve_boss_spawned)
	_wave_manager.wave_timer_updated.connect(_on_pve_wave_timer_updated)
	_wave_manager.all_players_dead.connect(_on_pve_all_dead)

	var wave_label = Label.new()
	wave_label.name = "PveWaveLabel"
	wave_label.add_theme_font_size_override("font_size", 28)
	wave_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.offset_left = 0
	wave_label.offset_top = 10
	wave_label.offset_right = 1152
	wave_label.offset_bottom = 50
	wave_label.text = "WAVE 1"
	ui.add_child(wave_label)
	_pve_wave_label = wave_label

	var gold_label = Label.new()
	gold_label.name = "PveGoldLabel"
	gold_label.add_theme_font_size_override("font_size", 22)
	gold_label.add_theme_color_override("font_color", Color(1, 0.84, 0.0))
	gold_label.offset_left = 10
	gold_label.offset_top = 55
	gold_label.offset_right = 300
	gold_label.offset_bottom = 85
	gold_label.text = "GOLD: 0"
	ui.add_child(gold_label)
	_pve_gold_label = gold_label

	var wave_timer_label = Label.new()
	wave_timer_label.name = "PveWaveTimerLabel"
	wave_timer_label.add_theme_font_size_override("font_size", 20)
	wave_timer_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	wave_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_timer_label.offset_left = 0
	wave_timer_label.offset_top = 45
	wave_timer_label.offset_right = 1152
	wave_timer_label.offset_bottom = 75
	wave_timer_label.text = ""
	ui.add_child(wave_timer_label)
	_pve_wave_timer_label = wave_timer_label

func _setup_wave_manager():
	if multiplayer.is_server():
		var spawn_pos = spawn_positions.duplicate()
		for i in range(20):
			spawn_pos.append(Vector2(randf_range(50, 950), randf_range(50, 650)))
		_wave_manager.setup(self, spawn_pos, GlobalSteamScript.get_lobby_member_count())

func _on_pve_wave_started(wave_number: int):
	_pve_is_wave_in_progress = true
	_pve_wave_label.text = "WAVE %d" % wave_number
	if _pve_wave_timer_label:
		_pve_wave_timer_label.text = ""

func _on_pve_wave_cleared(wave_number: int):
	_pve_is_wave_in_progress = false
	print("[Arena] Wave %d cleared!" % wave_number)

func _on_pve_boss_spawned(wave_number: int):
	_pve_wave_label.text = "BOSS WAVE %d!" % wave_number

func _on_pve_wave_timer_updated(time_left: float):
	if _pve_wave_timer_label:
		_pve_wave_timer_label.text = "Next wave in %d" % int(time_left)

func _on_pve_all_dead():
	_end_pve_game()

func _award_pve_loot(killer_peer_id: int, gold_amount: int, _enemy_node: Node):
	if not multiplayer.is_server():
		return
	print("[Arena] Assegnato %d oro a peer %d" % [gold_amount, killer_peer_id])
	if killer_peer_id == multiplayer.get_unique_id():
		GlobalStats.gold += gold_amount
		GlobalStats.pve_gold_earned += gold_amount
		GlobalStats.pve_enemies_killed += 1
		GlobalStats.save_data_stats()
		_pve_gold += gold_amount
		_pve_gold_label.text = "GOLD: %d" % _pve_gold
	elif killer_peer_id > 0:
		_grant_pve_loot.rpc_id(killer_peer_id, gold_amount)

@rpc("authority", "reliable")
func _grant_pve_loot(gold_amount: int):
	GlobalStats.gold += gold_amount
	GlobalStats.pve_gold_earned += gold_amount
	GlobalStats.pve_enemies_killed += 1
	GlobalStats.save_data_stats()
	_pve_gold += gold_amount
	_pve_gold_label.text = "GOLD: %d" % _pve_gold

func _update_progression_hud() -> void:
	if not progression_label:
		return
	progression_label.visible = GameModes.is_progression_mode()
	if not GameModes.is_progression_mode():
		return
	var my_id := multiplayer.get_unique_id()
	var player_node := _get_player_node_by_peer_id(my_id)
	if not is_instance_valid(player_node) or not player_node.has_method("get_progression_weapon_name"):
		progression_label.text = ""
		return
	var weapon_name: String = player_node.get_progression_weapon_name()
	var index: int = player_node.get("progression_weapon_index")
	var total: int = GameModes.PROGRESSION_WEAPON_ORDER.size()
	var status := "FINAL KILL WINS" if index >= total - 1 else "KILLS TO NEXT: 1"
	var bar := ""
	for i in range(total):
		bar += "[color=#55ff55]|[/color]" if i <= index else "[color=#555555]|[/color]"
	progression_label.text = "[right][color=#ffaa00]WEAPON[/color]\n[color=#ffffff]%s[/color]\n%s  %d/%d\n[color=#cccccc]%s[/color][/right]" % [
		weapon_name,
		bar,
		index + 1,
		total,
		status
	]

# ==============================================================
# RESPAWN (POINT & KING, server only)
# ==============================================================

func _schedule_respawn(peer_id: int) -> void:
	if peer_id == 1:
		print("[Arena] Respawn in %.1f secondi..." % RESPAWN_DELAY)
	elif peer_id < 0:
		pass
	else:
		_notify_respawn_incoming.rpc_id(peer_id, RESPAWN_DELAY)

	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if game_ended:
		return
	_do_respawn(peer_id)

@rpc("authority", "reliable")
func _notify_respawn_incoming(delay: float) -> void:
	print("[Arena] Respawn in %.1f secondi..." % delay)

func _do_respawn(peer_id: int) -> void:
	if not multiplayer.is_server(): 
		return

	var occupied: Array[Vector2] = []
	for child in players_container.get_children():
		if child is Node2D and is_instance_valid(child):
			occupied.append(child.global_position)
	var respawn_pos := _find_free_spawn(occupied)

	var player_node := players_container.get_node_or_null("Player_%d" % peer_id)
	if not is_instance_valid(player_node):
		player_spawner.spawn([peer_id, respawn_pos])
	else:
		player_node.rpc_reset_visuals.rpc()
		player_node.rpc_do_respawn.rpc(respawn_pos)

	alive_players[peer_id] = true
	_update_info_display()

func _find_free_spawn(occupied: Array[Vector2]) -> Vector2:
	for pos in spawn_positions:
		var too_close := false
		for occ in occupied:
			if pos.distance_to(occ) < 120.0:
				too_close = true
				break
		if not too_close:
			return pos
	return spawn_positions[randi() % spawn_positions.size()]

# ==============================================================
# WIN CONDITION CLASSIC
# ==============================================================

func _check_game_over_classic() -> void:
	if not multiplayer.is_server(): 
		return
	if game_over_triggered: 
		return

	var alive_count := 0
	var winner_id   := -1
	for pid in alive_players:
		if alive_players[pid] == true:
			alive_count += 1
			winner_id    = pid

	print("[Arena] Giocatori vivi: ", alive_count)
	if alive_count <= 1 and alive_players.size() >= 2:
		_end_game(winner_id)

# ==============================================================
# END GAME
# ==============================================================

func _end_game(winner_id: int) -> void:
	if GameModes.is_pve_mode():
		_end_pve_game()
		return
	if game_over_triggered: 
		return
	game_over_triggered = true
	game_ended          = true
	match_winner_id     = winner_id

	print("[Arena] GAME OVER! Vincitore: ", winner_id)

	if game_timer: 
		game_timer.stop()

	if GameModes.is_score_mode():
		var scene := get_tree().current_scene
		if scene.child_entered_tree.is_connected(_on_scene_child_entered):
			scene.child_entered_tree.disconnect(_on_scene_child_entered)

	var loser_id := -1
	for pid in alive_players:
		if pid != winner_id:
			loser_id = pid
			break

	if multiplayer.is_server() and not match_ended:
		match_ended = true
		_award_pvp_coins(winner_id, loser_id)

	var final_scores: Dictionary = score_manager.get_all_scores() if GameModes.is_score_mode() else {}
	_game_over.rpc(winner_id, GameModes.current_mode, final_scores)

func _award_pvp_coins(winner_id: int, loser_id: int) -> void:
	const WINNER_COINS := 5
	const LOSER_COINS  := 1

	var winner_node := _get_player_node_by_peer_id(winner_id)
	if winner_node and winner_node.is_local_player:
		GlobalStats.pvp_coin += WINNER_COINS
	elif winner_id > 0:
		_update_pvp_coins.rpc_id(winner_id, WINNER_COINS)

	if loser_id != -1:
		var loser_node := _get_player_node_by_peer_id(loser_id)
		if loser_node and loser_node.is_local_player:
			GlobalStats.pvp_coin += LOSER_COINS
		elif loser_id > 0:
			_update_pvp_coins.rpc_id(loser_id, LOSER_COINS)

	GlobalStats.save_data_stats()

@rpc("authority", "reliable")
func _update_pvp_coins(amount: int) -> void:
	GlobalStats.pvp_coin += amount
	GlobalStats.save_data_stats()

func _get_player_node_by_peer_id(peer_id: int) -> Node:
	return players_container.get_node_or_null("Player_%d" % peer_id)

# ==============================================================
# GAME OVER RPC — tutti i peer
# ==============================================================

@rpc("reliable", "call_local")
func _game_over(winner_id: int, mode: int, final_scores: Dictionary) -> void:
	print("[Game Over] Vincitore: ", winner_id)

	if multiplayer.multiplayer_peer == null: 
		return

	for player_node in players_container.get_children():
		player_node.set_physics_process(false)
		player_node.set_process(false)
		if "can_shoot" in player_node:
			player_node.can_shoot = false

	# Hide in-game UI (player + enemy) on game over
	if player_name_label: player_name_label.visible = false
	if profile_img: profile_img.visible = false
	if hp_bar: hp_bar.visible = false
	if stm_bar: stm_bar.visible = false
	if bull_bar: bull_bar.visible = false
	if player_name_label: player_name_label.visible = false
	if profile_img: profile_img.visible = false
	if enemy_ui: enemy_ui.visible = false

	if game_over_panel: 
		game_over_panel.visible = true

	if winner_label:
		var my_id := multiplayer.get_unique_id()
		var won   := (winner_id == my_id)

		if mode == GameModes.GameMode.POINT or mode == GameModes.GameMode.KING or mode == GameModes.GameMode.PROGRESSION:
			var board_text := _build_score_board_text(final_scores, my_id)
			if won:
				winner_label.text = "🏆 YOU WIN! 🏆\n\n" + board_text + "\n+5 PvP Coins"
				winner_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			else:
				winner_label.text = "💀 YOU LOSE! 💀\n\n" + board_text + "\n+1 PvP Coin"
				winner_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		else:  # CLASSIC
			if won:
				winner_label.text = "🏆 YOU WIN! 🏆\nLast man standing!\n+5 PvP Coins"
				winner_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
			elif winner_id < 0:
				var bot_name = _get_player_name_for_ui(winner_id)
				winner_label.text = "💀 DEFEATED! 💀\n%s won the match.\n+1 PvP Coin" % [bot_name]
				winner_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			else:
				winner_label.text = "💀 YOU LOSE! 💀\n+1 PvP Coin"
				winner_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))

	if back_to_menu_button: 
		back_to_menu_button.visible = true

func _create_game_over_opponent_panel(winner_id: int) -> void:
	if not game_over_panel: 
		return
	var my_id := multiplayer.get_unique_id()
	var won := (winner_id == my_id)

	var opponent_id := -1
	for pid in alive_players:
		if pid != my_id:
			opponent_id = pid
			break

	if opponent_id == -1:
		if not won and winner_id != my_id:
			opponent_id = winner_id

	var opponent_panel = Panel.new()
	opponent_panel.name = "OpponentPanel"
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0, 0, 0, 0.7)
	stylebox.corner_radius_top_left = 12
	stylebox.corner_radius_top_right = 12
	stylebox.corner_radius_bottom_left = 12
	stylebox.corner_radius_bottom_right = 12
	opponent_panel.add_theme_stylebox_override("panel", stylebox)
	opponent_panel.anchors_preset = Control.PRESET_CENTER
	opponent_panel.offset_left = -250
	opponent_panel.offset_top = -80
	opponent_panel.offset_right = 250
	opponent_panel.offset_bottom = 80
	game_over_panel.add_child(opponent_panel)

	var layout = VBoxContainer.new()
	layout.anchors_preset = Control.PRESET_FULL_RECT
	opponent_panel.add_child(layout)

	var title = Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "YOUR OPPONENT" if won else "DEFEATED BY"
	layout.add_child(title)

	var hbox = HBoxContainer.new()
	layout.add_child(hbox)

	var pfp_rect = TextureRect.new()
	pfp_rect.custom_minimum_size = Vector2(80, 80)
	pfp_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	pfp_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(pfp_rect)

	var info_vbox = VBoxContainer.new()
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_label.add_theme_constant_override("outline_size", 2)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_vbox.add_child(name_label)

	var status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_vbox.add_child(status_label)

	var opponent_name = "Unknown"
	var opponent_pfp = 0
	var opponent_node = _get_player_node_by_peer_id(opponent_id)
	if is_instance_valid(opponent_node):
		var mp_name = opponent_node.get("mp_player_name")
		opponent_name = mp_name if mp_name != null else "Player"
		if opponent_name == "" or opponent_name == "Player":
			opponent_name = "P" + str(opponent_id)
		var pfp_icon = opponent_node.get("texture_pfp_icon")
		opponent_pfp = pfp_icon if pfp_icon != null else 0
	else:
		if opponent_id == -1 and winner_id != my_id:
			var winner_node = _get_player_node_by_peer_id(winner_id)
			if is_instance_valid(winner_node):
				var mp_name = winner_node.get("mp_player_name")
				opponent_name = mp_name if mp_name != null else "Player"
				if opponent_name == "" or opponent_name == "Player":
					opponent_name = "P" + str(winner_id)
				var pfp_icon = winner_node.get("texture_pfp_icon")
				opponent_pfp = pfp_icon if pfp_icon != null else 0

	if opponent_id < 0:
		if opponent_name == "Unknown" or opponent_name == "Player":
			opponent_name = "Player Left"
		opponent_pfp = 0
	elif opponent_id == -1:
		opponent_name = "Player Left"
		opponent_pfp = 0

	name_label.text = opponent_name
	status_label.text = "HP: %d / %d" % [0, 0]

	if opponent_pfp != 0:
		var pfp_path = "res://Gres/Assets/Icons/pfp/pfp_%s.png" % opponent_pfp
		if ResourceLoader.exists(pfp_path):
			pfp_rect.texture = load(pfp_path)
		else:
			pfp_rect.texture = preload("res://Gres/Assets/Icons/skill/icon_empty.png")
	else:
		pfp_rect.texture = preload("res://Gres/Assets/Icons/skill/icon_empty.png")

	var tween = create_tween()
	tween.tween_property(opponent_panel, "modulate:a", 0.0, 0.0)
	tween.tween_property(opponent_panel, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(opponent_panel, "scale", Vector2(0.9, 0.9), 0.0)
	tween.tween_property(opponent_panel, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _build_score_board_text(scores: Dictionary, my_id: int) -> String:
	var sorted: Array = []
	for pid in scores:
		sorted.append({"id": pid, "pts": scores[pid]})
	sorted.sort_custom(func(a, b): return a.pts > b.pts)

	var text := "─── SCORES ───\n"
	var rank  := 1
	for entry in sorted:
		var pid:   int    = entry.id
		var pts:   int    = entry.pts
		var tag:   String = " (YOU)" if pid == my_id else ""
		var crown: String = "🥇" if rank == 1 else ("🥈" if rank == 2 else "🥉")
		var p_name = _get_player_name_for_ui(pid)
		text += "%s  %s%s: %d pts\n" % [crown, p_name, tag, pts]
		rank += 1
	return text

func _get_player_name_for_ui(peer_id: int) -> String:
	var player_node = _get_player_node_by_peer_id(peer_id)
	if is_instance_valid(player_node):
		var name = player_node.get("mp_player_name")
		if name != null and name != "" and name != "Player":
			return name
	if peer_id < 0:
		return "Player Left"
	return "P" + str(peer_id)

# ==============================================================
# SCOREBOARD LIVE (POINT & KING)
# ==============================================================

func _on_scores_updated(scores: Dictionary) -> void:
	if not score_board: 
		return
	if not GameModes.is_score_mode(): 
		return

	var sorted: Array = []
	for pid in scores:
		sorted.append({"id": pid, "pts": scores[pid]})
	sorted.sort_custom(func(a, b): return a.pts > b.pts)

	var my_id := multiplayer.get_unique_id()
	var text  := "[center][color=#ffaa00]── SCORES ──[/color]\n"
	for entry in sorted:
		var pid:   int    = entry.id
		var pts:   int    = entry.pts
		var color: String = "#ffff55" if pid == my_id else "#ffffff"
		var p_name = _get_player_name_for_ui(pid)
		text += "[color=%s]%s: %d[/color]\n" % [color, p_name, pts]
	text += "[/center]"
	score_board.text = text

# ==============================================================
# INFO DISPLAY
# ==============================================================

func _update_info_display() -> void:
	if not info_label: 
		return
	var alive_count := 0
	for is_alive in alive_players.values():
		if is_alive: 
			alive_count += 1
	var time_text := " | %d min" % (GameModes.match_duration / 60) if GameModes.time_limit_enabled else ""
	info_label.text = "ROOM: %s\nMODE: %s%s\nALIVE: %d/%d" % [
		GlobalSteamScript.current_room_code,
		GameModes.get_mode_name(),
		time_text,
		alive_count,
		alive_players.size()
	]

	_update_enemy_ui()

# ==============================================================
# NAVIGAZIONE
# ==============================================================

func _on_return_to_lobby_pressed() -> void:
	print("[Arena] Ritorno alla lobby")
	return_requested   = true
	returning_to_lobby = true
	if game_timer: 
		game_timer.stop()
	if not GlobalSteamScript.is_in_lobby:
		get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")
		return
	get_tree().change_scene_to_file("res://Gres/Multiplayer/scene/UI/lobby.tscn")

func _exit_tree() -> void:
	if returning_to_lobby: 
		return
	if not GlobalSteamScript.is_in_lobby:
		Global.last_sp_weapon.name   = Global.equipped_weapon.name
		Global.last_sp_weapon.rarity = Global.equipped_weapon.rarity
	if multiplayer.is_server():
		GlobalSteamScript.leave_lobby()
