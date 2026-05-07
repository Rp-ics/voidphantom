extends Node

# =============================================================================
#  EARTH LEVEL CONTROLLER — v2.0
#  Gestisce tutte le modalità di gioco tramite enum centrale.
#  Aggiungere una modalità = aggiungere un valore all'enum + un metodo _start_*
# =============================================================================

signal level_completed(success: bool)

# ──────────────────────────────────────────────────────────────────────────────
#  ENUM MODALITÀ (unica fonte di verità — niente stringhe magiche)
# ──────────────────────────────────────────────────────────────────────────────
enum GameMode {
	CAMPAIGN_KILLS,     ## Uccidi N nemici
	CAMPAIGN_WAVES,     ## Sopravvivi N ondate
	CAMPAIGN_TIME,      ## Difendi per N secondi
	ASSAULT,            ## Distruggi tutte le basi nemiche
	SURVIVE,            ## Sopravvivi al fuoco delle torrette per N secondi
	BOSS,               ## Sconfiggi il boss

	## ── NUOVE MODALITÀ ──────────────────────────────────────────────────────
	BLITZ,              ## Kill X nemici nel minor tempo (time attack)
	ESCORT,             ## Scorta l'NPC alla destinazione
	LAST_STAND,         ## 1 vita sola, ondate infinite sempre più difficili
	CONTAMINATION,      ## I nemici uccisi respawnano potenziati dopo N secondi
	EXTRACTION,         ## Raccogli N oggetti sparsi prima che finiscano i nemici
	KING_OF_THE_HILL,   ## Controlla la zona per X secondi accumulati totali
}

# ──────────────────────────────────────────────────────────────────────────────
#  EXPORT — GENERALE
# ──────────────────────────────────────────────────────────────────────────────
@export_group("Level Settings")
@export var game_mode: GameMode = GameMode.CAMPAIGN_KILLS
@export var next_scene: String = "res://Gres/Scenes/UI/main_menu.tscn"
@export var show_mission_complete_chest: bool = true
@export var wave_delay: float = 4.0

@export_group("Spawn Settings")
@export var spawn_origin_path: NodePath
@export var min_spawn_distance: float = 300.0
@export var max_spawn_distance: float = 700.0
@export var max_enemies_on_field_base: int = 50
@export var spawn_points: Array[NodePath] = []

@export_group("Campaign / Wave Settings")
@export var campaign_goal_value: int = 30
@export var campaign_time_limit: float = 60.0

@export_group("Assault Settings")
@export var enemy_base_group: String = "e_base"
@export var assault_max_enemies: int = 20
@export var assault_spawn_rate: float = 1.5

@export_group("Survive Settings")
@export var survive_duration: float = 30.0
@export var turret_scene: PackedScene
@export var turret_positions: Array[Node2D] = []

@export_group("Boss Settings")
@export var spawn_boss_scene: PackedScene

@export_group("Chest Settings")
@export var chest_scenes: Array[PackedScene]
@export var chest_spawn_points: Array[Node2D]

# ── BLITZ ─────────────────────────────────────────────────────────────────────
@export_group("Blitz Settings")
## Numero di nemici da eliminare il più in fretta possibile
@export var blitz_kill_target: int = 25
## Tempo massimo prima del fail (0 = nessun limite)
@export var blitz_time_limit: float = 120.0

# ── ESCORT ────────────────────────────────────────────────────────────────────
@export_group("Escort Settings")
## NPC da scortare (deve avere segnale "reached_destination" e "escort_died")
@export var escort_npc_scene: PackedScene
@export var escort_npc_spawn: Node2D
## Nemici extra aggressivi verso l'NPC
@export var escort_enemy_aggro_npc: bool = true

# ── LAST STAND ────────────────────────────────────────────────────────────────
@export_group("Last Stand Settings")
## Ogni quante ondate aumenta la difficoltà di uno step
@export var last_stand_difficulty_step: int = 3
## Moltiplicatore nemici per step
@export var last_stand_enemy_multiplier: float = 1.4

# ── CONTAMINATION ─────────────────────────────────────────────────────────────
@export_group("Contamination Settings")
## Nemici "infetti" da uccidere per vincere
@export var contamination_kill_target: int = 40
## Secondi prima che un nemico ucciso respawni potenziato
@export var contamination_respawn_delay: float = 8.0
## Moltiplicatore HP/danno per nemico contaminato
@export var contamination_power_multiplier: float = 1.6
## Scena del nemico contaminato (se null usa la stessa di default)
@export var contaminated_enemy_scene: PackedScene

# ── EXTRACTION ────────────────────────────────────────────────────────────────
@export_group("Extraction Settings")
## Numero oggetti da raccogliere
@export var extraction_item_count: int = 10
## Scene degli oggetti da raccogliere
@export var extraction_item_scene: PackedScene
## Punti spawn degli oggetti
@export var extraction_item_spawns: Array[Node2D] = []
## Nemici aumentano col tempo anche senza wave
@export var extraction_enemy_pressure: bool = true

# ── KING OF THE HILL ──────────────────────────────────────────────────────────
@export_group("King of the Hill Settings")
## Secondi totali da accumulare nella zona per vincere
@export var koth_capture_target: float = 30.0
## Nodo Area2D che definisce la zona
@export var koth_zone_path: NodePath
## Il contatore si azzera se il nemico è nella zona insieme al player?
@export var koth_contested_pauses: bool = true

# ──────────────────────────────────────────────────────────────────────────────
#  STATO INTERNO
# ──────────────────────────────────────────────────────────────────────────────
var _target_enemies: int = 0
var _enemies_spawned: int = 0
var _killed_enemies: int = 0
var _current_enemies: int = 0
var _can_spawn: bool = false
var _spawn_rate: float = 2.0
var _max_enemies_on_field: int = 50
var _can_give_wave_reward := true
var _campaign_waves_completed: int = 0
var _level_finished: bool = false

# BLITZ
var _blitz_start_time: float = 0.0
var _blitz_kills: int = 0

# ESCORT
var _escort_npc: Node2D = null

# LAST STAND
var _last_stand_wave: int = 0

# CONTAMINATION
var _contamination_kills: int = 0
var _contamination_pending_respawns: int = 0

# EXTRACTION
var _extracted_items: int = 0

# KING OF THE HILL
var _koth_zone: Area2D = null
var _koth_accumulated: float = 0.0
var _player_in_zone: bool = false
var _zone_contested: bool = false

# ──────────────────────────────────────────────────────────────────────────────
#  NODI
# ──────────────────────────────────────────────────────────────────────────────
@onready var enemy_container  = $Gameplay/EnemyContainer
@onready var player           = $Player
@onready var wave_info_label  = $UI/WaveManager/WaveInfo
@onready var spawn_info_label = $UI/WaveManager/SpawnInfo
@onready var kill_info_label  = $UI/WaveManager/KillInfo
@onready var campaign_timer: Timer = $CampaignTimer

var _spawn_origin: Node2D = null

# ──────────────────────────────────────────────────────────────────────────────
#  READY
# ──────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_spawn_origin = get_node_or_null(spawn_origin_path) if spawn_origin_path != NodePath() else player

	_killed_enemies = 0
	_current_enemies = 0
	_enemies_spawned = 0
	_campaign_waves_completed = 0

	_route_mode()

# ──────────────────────────────────────────────────────────────────────────────
#  ROUTER — smista verso la modalità corretta (unico punto di controllo)
# ──────────────────────────────────────────────────────────────────────────────
func _route_mode() -> void:
	await _show_text("==== LEVEL START ====", Color.WHITE)
	match game_mode:
		GameMode.CAMPAIGN_KILLS:  _start_campaign_kills()
		GameMode.CAMPAIGN_WAVES:  _start_campaign_waves()
		GameMode.CAMPAIGN_TIME:   _start_campaign_time()
		GameMode.ASSAULT:         _start_assault()
		GameMode.SURVIVE:         _start_survive()
		GameMode.BOSS:            _start_boss()
		GameMode.BLITZ:           _start_blitz()
		GameMode.ESCORT:          _start_escort()
		GameMode.LAST_STAND:      _start_last_stand()
		GameMode.CONTAMINATION:   _start_contamination()
		GameMode.EXTRACTION:      _start_extraction()
		GameMode.KING_OF_THE_HILL:_start_koth()

# ──────────────────────────────────────────────────────────────────────────────
#  MODALITÀ ORIGINALI (riscritte pulite)
# ──────────────────────────────────────────────────────────────────────────────

func _start_campaign_kills() -> void:
	MissionManager.set_mission(
		"Operation Earthfall",
		"Secure the area by eliminating all hostiles.",
		"Kill %d Enemies!" % campaign_goal_value
	)
	_target_enemies = campaign_goal_value
	_begin_wave_loop()

func _start_campaign_waves() -> void:
	MissionManager.set_mission(
		"Sustain and Survive",
		"Endure through multiple enemy waves.",
		"Survive %d Waves!" % campaign_goal_value
	)
	_begin_wave_loop()

func _start_campaign_time() -> void:
	MissionManager.set_mission(
		"Defense Protocol",
		"Hold the line and protect the base.",
		"Defend for %d seconds!" % int(campaign_time_limit)
	)
	_start_timer(campaign_time_limit, _on_time_success)
	_begin_wave_loop()

func _start_assault() -> void:
	await _show_text("==== ASSAULT PROTOCOL ====", Color.RED)
	MissionManager.set_mission("ASSAULT PROTOCOL", "Destroy all enemy bases!", "Eliminate all enemy installations.")

	var bases = get_tree().get_nodes_in_group(enemy_base_group)
	if bases.is_empty():
		printerr("[ASSAULT] Nessuna base nemica trovata!")
		return
	for b in bases:
		b.connect("base_destroyed", _on_enemy_base_destroyed)

	_can_spawn = true
	_spawn_rate = assault_spawn_rate
	_max_enemies_on_field = assault_max_enemies
	_run_assault_loop()

func _run_assault_loop() -> void:
	while _can_spawn and not _level_finished:
		var bases = get_tree().get_nodes_in_group(enemy_base_group)
		var active_bases = bases.filter(func(b): return not b.is_destroyed)
		if active_bases.is_empty():
			_finish(true)
			return
		if enemy_container.get_child_count() < _max_enemies_on_field:
			var base = active_bases[randi() % active_bases.size()]
			_spawn_enemy_near(base.global_position, randf_range(300, 600))
		await get_tree().create_timer(_spawn_rate).timeout

func _start_survive() -> void:
	await _show_text("SURVIVE MODE!", Color.ORANGE)
	MissionManager.set_mission("SURVIVE MODE", "Dodge enemy fire until the timer ends!", "%.0f seconds left" % survive_duration)

	for pos in turret_positions:
		if turret_scene:
			var t = turret_scene.instantiate()
			t.global_position = pos.global_position
			enemy_container.add_child(t)

	_start_timer(survive_duration, _on_time_success)

func _start_boss() -> void:
	if not spawn_boss_scene:
		printerr("[BOSS] spawn_boss_scene non impostata!")
		return
	await _show_text("⚠ BOSS INCOMING ⚠", Color.RED)
	MissionManager.set_mission("BOSS FIGHT", "Eliminate the boss to proceed.", "Slay the Boss!")

	var boss = spawn_boss_scene.instantiate()
	boss.global_position = _get_spawn_position()
	var sig = "enemy_died" if boss.has_signal("enemy_died") else "tree_exited"
	boss.connect(sig, _on_boss_killed)
	enemy_container.add_child(boss)

# ──────────────────────────────────────────────────────────────────────────────
#  ★ BLITZ — Time attack: uccidi X in meno tempo possibile
# ──────────────────────────────────────────────────────────────────────────────
func _start_blitz() -> void:
	await _show_text("⚡ BLITZ! ⚡", Color(1.0, 0.8, 0.0))
	MissionManager.set_mission(
		"BLITZ",
		"Eliminate %d enemies as fast as you can!" % blitz_kill_target,
		"Kills: 0 / %d" % blitz_kill_target
	)

	_blitz_kills = 0
	_blitz_start_time = Time.get_ticks_msec() / 1000.0
	_target_enemies = blitz_kill_target

	if blitz_time_limit > 0.0:
		_start_timer(blitz_time_limit, _on_blitz_timeout)

	_can_spawn = true
	_max_enemies_on_field = max_enemies_on_field_base
	_spawn_rate = 0.8  # spawn aggressivo
	_run_continuous_spawn()

func _on_blitz_enemy_killed() -> void:
	_blitz_kills += 1
	_current_enemies -= 1
	GlobalStats.kill_mobs_lvl += 1
	GlobalStats.kill_mobs_total += 1

	var elapsed = (Time.get_ticks_msec() / 1000.0) - _blitz_start_time
	MissionManager.current_mission.objective = "Kills: %d / %d  |  Time: %.1fs" % [_blitz_kills, blitz_kill_target, elapsed]
	MissionManager.emit_signal("mission_updated")
	kill_info_label.text = "Kills: %d / %d" % [_blitz_kills, blitz_kill_target]

	if _blitz_kills >= blitz_kill_target:
		campaign_timer.stop()
		var total_time = (Time.get_ticks_msec() / 1000.0) - _blitz_start_time
		await _show_text("BLITZ COMPLETE! Time: %.2fs 🏆" % total_time, Color(1.0, 0.85, 0.0))
		var reward = int(blitz_kill_target * 3 + max(0.0, blitz_time_limit - total_time) * 2)
		GlobalStats.gold += reward
		Global.update_mission_progress("rich_game_1", reward)
		Global.update_mission_progress("rich_game_2", reward)
		Global.update_mission_progress("rich_game_3", reward)
		
		_finish(true)

func _on_blitz_timeout() -> void:
	await _show_text("TIME'S UP! %d / %d" % [_blitz_kills, blitz_kill_target], Color.RED)
	_finish(false)

# ──────────────────────────────────────────────────────────────────────────────
#  ★ ESCORT — Scorta l'NPC alla destinazione
# ──────────────────────────────────────────────────────────────────────────────
func _start_escort() -> void:
	if not escort_npc_scene or not escort_npc_spawn:
		printerr("[ESCORT] escort_npc_scene o escort_npc_spawn non impostati!")
		return

	await _show_text("🛡 ESCORT MISSION 🛡", Color(0.4, 0.9, 1.0))
	MissionManager.set_mission(
		"ESCORT",
		"Protect the VIP and escort them to safety.",
		"Keep the VIP alive!"
	)

	_escort_npc = escort_npc_scene.instantiate()
	_escort_npc.global_position = escort_npc_spawn.global_position
	if _escort_npc.has_signal("reached_destination"):
		_escort_npc.connect("reached_destination", _on_escort_success)
	if _escort_npc.has_signal("escort_died"):
		_escort_npc.connect("escort_died", _on_escort_failed)
	get_parent().add_child(_escort_npc)

	# Pressione nemica costante
	_can_spawn = true
	_spawn_rate = 1.8
	_max_enemies_on_field = 15
	_run_continuous_spawn()

func _on_escort_success() -> void:
	_can_spawn = false
	await _show_text("VIP SAFE! MISSION SUCCESS! 🎉", Color(0.4, 1.0, 0.4))
	_finish(true)

func _on_escort_failed() -> void:
	_can_spawn = false
	await _show_text("VIP KIA. MISSION FAILED. 💀", Color.RED)
	_finish(false)

# ──────────────────────────────────────────────────────────────────────────────
#  ★ LAST STAND — 1 vita, ondate infinite, difficoltà crescente
# ──────────────────────────────────────────────────────────────────────────────
func _start_last_stand() -> void:
	await _show_text("☠ LAST STAND ☠", Color.RED)
	MissionManager.set_mission(
		"LAST STAND",
		"No respawns. Survive as long as you can.",
		"Wave 1 — Good luck."
	)

	# Forza 1 sola vita
	if player.has_method("set_extra_lives"):
		player.set_extra_lives(0)

	_last_stand_wave = 0
	_run_last_stand_loop()

func _run_last_stand_loop() -> void:
	while not _level_finished:
		_last_stand_wave += 1
		var difficulty_tier = (_last_stand_wave - 1) / last_stand_difficulty_step
		var enemy_count = int(5 + _last_stand_wave * 2 * pow(last_stand_enemy_multiplier, difficulty_tier))
		_spawn_rate = clamp(2.0 - _last_stand_wave * 0.04, 0.3, 2.0)
		_max_enemies_on_field = min(enemy_count, 80)

		MissionManager.current_mission.title = "LAST STAND — Wave %d" % _last_stand_wave
		MissionManager.current_mission.description = "Enemies this wave: %d" % enemy_count
		MissionManager.current_mission.objective = "Kill them all."
		MissionManager.emit_signal("mission_updated")

		await _show_text("🔥 WAVE %d 🔥" % _last_stand_wave, Color(1.0, 0.4, 0.1))

		_target_enemies = enemy_count
		_enemies_spawned = 0
		_killed_enemies = 0
		_can_spawn = true

		await _run_wave_spawn()

		if _level_finished:
			return

		GlobalStats.gold += _last_stand_wave * 15
		await _show_text("Wave %d Survived! Gold +%d 💰" % [_last_stand_wave, _last_stand_wave * 15], Color.YELLOW)
		await get_tree().create_timer(wave_delay).timeout

func _on_last_stand_player_died() -> void:
	_can_spawn = false
	await _show_text("☠ YOU FELL ON WAVE %d ☠" % _last_stand_wave, Color.RED)
	MissionManager.current_mission.objective = "Survived %d waves" % _last_stand_wave
	MissionManager.emit_signal("mission_updated")
	_level_finished = true
	emit_signal("level_completed", false)
	await get_tree().create_timer(2.0).timeout
	if next_scene != "":
		$UI/trasl/anim.play("trs")

# ──────────────────────────────────────────────────────────────────────────────
#  ★ CONTAMINATION — I nemici uccisi respawnano potenziati
# ──────────────────────────────────────────────────────────────────────────────
func _start_contamination() -> void:
	await _show_text("☣ CONTAMINATION ☣", Color(0.2, 1.0, 0.3))
	MissionManager.set_mission(
		"CONTAMINATION",
		"Enemies are mutating. Kill them before they get too powerful!",
		"Purge: 0 / %d" % contamination_kill_target
	)

	_contamination_kills = 0
	_target_enemies = contamination_kill_target
	_can_spawn = true
	_spawn_rate = 2.5
	_max_enemies_on_field = 20
	_run_continuous_spawn()

func _on_contamination_enemy_killed(position: Vector2) -> void:
	_contamination_kills += 1
	_current_enemies -= 1
	GlobalStats.kill_mobs_lvl += 1
	GlobalStats.kill_mobs_total += 1

	MissionManager.current_mission.objective = "Purge: %d / %d" % [_contamination_kills, contamination_kill_target]
	MissionManager.emit_signal("mission_updated")
	kill_info_label.text = "Purge: %d / %d" % [_contamination_kills, contamination_kill_target]

	# Rispawna un clone più forte dopo il delay
	_contamination_pending_respawns += 1
	_schedule_contaminated_respawn(position)

	if _contamination_kills >= contamination_kill_target:
		_can_spawn = false
		await _show_text("PURGE COMPLETE! ☣ Area Secured.", Color(0.2, 1.0, 0.3))
		_finish(true)

func _schedule_contaminated_respawn(pos: Vector2) -> void:
	await get_tree().create_timer(contamination_respawn_delay).timeout
	if _level_finished:
		return

	var scene = contaminated_enemy_scene if contaminated_enemy_scene else preload("res://Gres/Scenes/enemies/enemy.tscn")
	var enemy = scene.instantiate()
	enemy.global_position = pos + Vector2(randf_range(-80, 80), randf_range(-80, 80))

	# Potenzia l'istanza
	if enemy.has_method("apply_multiplier"):
		enemy.apply_multiplier(contamination_power_multiplier)
	elif "health" in enemy:
		enemy.health = int(enemy.health * contamination_power_multiplier)

	enemy.connect("enemy_died", func(): _on_contamination_enemy_killed(enemy.global_position))
	enemy_container.add_child(enemy)
	_current_enemies += 1
	_contamination_pending_respawns -= 1

# ──────────────────────────────────────────────────────────────────────────────
#  ★ EXTRACTION — Raccogli N oggetti sotto pressione nemica
# ──────────────────────────────────────────────────────────────────────────────
func _start_extraction() -> void:
	if not extraction_item_scene:
		printerr("[EXTRACTION] extraction_item_scene non impostata!")
		return

	await _show_text("📦 EXTRACTION 📦", Color(1.0, 0.6, 0.1))
	MissionManager.set_mission(
		"EXTRACTION",
		"Collect all intel before you're overwhelmed.",
		"Items: 0 / %d" % extraction_item_count
	)

	_extracted_items = 0
	_spawn_extraction_items()

	if extraction_enemy_pressure:
		_can_spawn = true
		_spawn_rate = 2.0
		_max_enemies_on_field = 12
		_run_continuous_spawn()

func _spawn_extraction_items() -> void:
	for i in extraction_item_count:
		var item = extraction_item_scene.instantiate()
		if i < extraction_item_spawns.size():
			item.global_position = extraction_item_spawns[i].global_position
		else:
			item.global_position = _get_spawn_position()

		if item.has_signal("item_collected"):
			item.connect("item_collected", _on_item_extracted)
		get_parent().add_child(item)

func _on_item_extracted() -> void:
	_extracted_items += 1
	MissionManager.current_mission.objective = "Items: %d / %d" % [_extracted_items, extraction_item_count]
	MissionManager.emit_signal("mission_updated")
	kill_info_label.text = "Collected: %d / %d" % [_extracted_items, extraction_item_count]

	if _extracted_items >= extraction_item_count:
		_can_spawn = false
		await _show_text("📦 ALL INTEL SECURED! Extraction complete!", Color(1.0, 0.8, 0.2))
		_finish(true)

# ──────────────────────────────────────────────────────────────────────────────
#  ★ KING OF THE HILL — Controlla la zona per X secondi totali
# ──────────────────────────────────────────────────────────────────────────────
func _start_koth() -> void:
	if koth_zone_path == NodePath():
		printerr("[KOTH] koth_zone_path non impostato!")
		return

	_koth_zone = get_node(koth_zone_path)
	if not _koth_zone:
		printerr("[KOTH] Zona non trovata al path: %s" % str(koth_zone_path))
		return

	await _show_text("👑 KING OF THE HILL 👑", Color(1.0, 0.9, 0.0))
	MissionManager.set_mission(
		"KING OF THE HILL",
		"Hold the zone to claim victory. Enemies contest your control.",
		"Zone control: 0 / %.0fs" % koth_capture_target
	)

	_koth_accumulated = 0.0
	_player_in_zone = false
	_zone_contested = false

	_koth_zone.connect("body_entered", _on_koth_body_entered)
	_koth_zone.connect("body_exited", _on_koth_body_exited)

	_can_spawn = true
	_spawn_rate = 1.5
	_max_enemies_on_field = 20
	_run_continuous_spawn()

func _on_koth_body_entered(body: Node2D) -> void:
	if body == player:
		_player_in_zone = true
	elif body.is_in_group("enemies"):
		_zone_contested = true

func _on_koth_body_exited(body: Node2D) -> void:
	if body == player:
		_player_in_zone = false
	elif body.is_in_group("enemies"):
		# Ricontrolla se ci sono ancora nemici nella zona
		var has_enemies = _koth_zone.get_overlapping_bodies().any(func(b): return b.is_in_group("enemies"))
		_zone_contested = has_enemies

func _process_koth(delta: float) -> void:
	if _level_finished:
		return
	var is_capturing = _player_in_zone and not (koth_contested_pauses and _zone_contested)
	if is_capturing:
		_koth_accumulated += delta
		var pct = (_koth_accumulated / koth_capture_target) * 100.0
		MissionManager.current_mission.objective = "Zone: %.1fs / %.0fs  [%.0f%%]%s" % [
			_koth_accumulated, koth_capture_target, pct,
			" — CONTESTED" if _zone_contested else ""
		]
		MissionManager.emit_signal("mission_updated")

		if _koth_accumulated >= koth_capture_target:
			_can_spawn = false
			await _show_text("👑 ZONE HELD! VICTORY ROYALE! 👑", Color(1.0, 0.9, 0.0))
			_finish(true)

# ──────────────────────────────────────────────────────────────────────────────
#  PROCESS
# ──────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	# Minimap
	$UI/MiniMap.global_position = Vector2(Global.mapX, Global.mapY)
	$UI/MiniMap.visible = Global.can_show_map

	# KOTH accumulator
	if game_mode == GameMode.KING_OF_THE_HILL:
		_process_koth(delta)

	# Timer survive/time obiettivo live
	if campaign_timer and campaign_timer.time_left > 0:
		match game_mode:
			GameMode.CAMPAIGN_TIME:
				MissionManager.current_mission.objective = "Defend for\n%.0f seconds" % campaign_timer.time_left
				MissionManager.emit_signal("mission_updated")
			GameMode.SURVIVE, GameMode.BLITZ:
				MissionManager.current_mission.objective = "%.0f seconds left" % campaign_timer.time_left
				MissionManager.emit_signal("mission_updated")

# ──────────────────────────────────────────────────────────────────────────────
#  WAVE / SPAWN INTERNALS
# ──────────────────────────────────────────────────────────────────────────────

func _begin_wave_loop() -> void:
	_start_wave()

func _start_wave() -> void:
	if _level_finished:
		return
	await _show_text("==== WAVE %d ====" % Global.wave, Color.WHITE)

	_enemies_spawned = 0
	_killed_enemies  = 0
	_can_give_wave_reward = true

	if game_mode == GameMode.CAMPAIGN_KILLS:
		_target_enemies = campaign_goal_value
	else:
		_target_enemies = 5 + Global.wave * 2

	_spawn_rate = clamp(2.0 - Global.wave * 0.05, 0.4, 2.0)
	_max_enemies_on_field = max_enemies_on_field_base if Global.wave < 5 \
		else max_enemies_on_field_base + (Global.wave - 4) * 5

	_can_spawn = true
	await _run_wave_spawn()

func _run_wave_spawn() -> void:
	while _can_spawn and _enemies_spawned < _target_enemies and not _level_finished:
		if _current_enemies < _max_enemies_on_field:
			_spawn_enemy(_get_spawn_position())
			_enemies_spawned += 1
			_current_enemies += 1
			spawn_info_label.text = "Enemies: %d / %d" % [_enemies_spawned, _target_enemies]
		await get_tree().create_timer(_spawn_rate).timeout
	_can_spawn = false

func _run_continuous_spawn() -> void:
	while _can_spawn and not _level_finished:
		if _current_enemies < _max_enemies_on_field:
			_spawn_enemy(_get_spawn_position())
			_current_enemies += 1
		await get_tree().create_timer(_spawn_rate).timeout

func _spawn_enemy(pos: Vector2) -> Node2D:
	var enemy = preload("res://Gres/Scenes/enemies/enemy.tscn").instantiate()
	enemy.global_position = pos
	enemy.connect("enemy_died", _on_enemy_killed)
	enemy_container.add_child(enemy)
	return enemy

func _spawn_enemy_near(origin: Vector2, radius: float) -> void:
	var angle = randf_range(0.0, TAU)
	var enemy = preload("res://Gres/Scenes/enemies/enemy.tscn").instantiate()
	enemy.global_position = origin + Vector2(cos(angle), sin(angle)) * radius
	enemy.connect("enemy_died", _on_enemy_killed)
	enemy_container.add_child(enemy)
	_current_enemies += 1

func _get_spawn_position() -> Vector2:
	if _spawn_origin == null:
		_spawn_origin = player
	var angle = randf() * TAU
	var dist  = randf_range(min_spawn_distance, max_spawn_distance)
	return _spawn_origin.global_position + Vector2(cos(angle), sin(angle)) * dist

# ──────────────────────────────────────────────────────────────────────────────
#  CALLBACKS NEMICI / BASI / BOSS
# ──────────────────────────────────────────────────────────────────────────────

func _on_enemy_killed() -> void:
	_killed_enemies  += 1
	_current_enemies -= 1
	GlobalStats.kill_mobs_lvl   += 1
	GlobalStats.kill_mobs_total += 1

	# Dispatch per modalità speciali
	match game_mode:
		GameMode.BLITZ:
			_on_blitz_enemy_killed()
			return
		GameMode.CONTAMINATION:
			# la contamination gestisce kill tramite segnale diretto su ogni nemico
			pass

	kill_info_label.text = "Killed: %d / %d" % [_killed_enemies, _target_enemies]

	# Aggiorna obiettivo campagna
	if game_mode == GameMode.CAMPAIGN_KILLS:
		MissionManager.current_mission.objective = "Kill Enemies: %d / %d" % [_killed_enemies, campaign_goal_value]
		MissionManager.emit_signal("mission_updated")
		if _killed_enemies >= campaign_goal_value:
			_finish(true)
			return

	if _killed_enemies >= _target_enemies and not _level_finished:
		_end_wave()

func _on_enemy_base_destroyed() -> void:
	var remaining = get_tree().get_nodes_in_group(enemy_base_group).filter(func(b): return not b.is_destroyed)
	if remaining.is_empty():
		_finish(true)

func _on_boss_killed() -> void:
	_finish(true)

func _on_time_success() -> void:
	_finish(true)

# ──────────────────────────────────────────────────────────────────────────────
#  END WAVE
# ──────────────────────────────────────────────────────────────────────────────

func _end_wave() -> void:
	_can_spawn = false

	if _can_give_wave_reward:
		_can_give_wave_reward = false
		var reward = Global.wave * 10
		GlobalStats.gold += reward
		GlobalStats.total_gold_collected += reward

	Global.wave += 1

	if game_mode == GameMode.CAMPAIGN_WAVES:
		_campaign_waves_completed += 1
		if _campaign_waves_completed >= campaign_goal_value:
			_finish(true)
			return

	if game_mode in [GameMode.CAMPAIGN_KILLS, GameMode.CAMPAIGN_WAVES, GameMode.CAMPAIGN_TIME]:
		if not _level_finished:
			await _countdown_between_waves()
			_start_wave()

func _countdown_between_waves() -> void:
	await _show_text("==== WAVE %d COMPLETED ====" % (Global.wave - 1), Color.GREEN)
	for i in range(int(wave_delay), 0, -1):
		wave_info_label.show()
		wave_info_label.text = "%d..." % i
		wave_info_label.modulate = Color.YELLOW
		await get_tree().create_timer(1.0).timeout
	await _show_text("START!", Color.CYAN)
	_can_give_wave_reward = true

# ──────────────────────────────────────────────────────────────────────────────
#  FINISH
# ──────────────────────────────────────────────────────────────────────────────

func _finish(success: bool) -> void:
	if _level_finished:
		return
	_level_finished = true
	_can_spawn = false

	if success:
		await _show_text("✔ MISSION COMPLETED!", Color.CYAN)
		if show_mission_complete_chest:
			_spawn_chest()
		GlobalStats.gold += campaign_goal_value * 2
		GlobalStats.total_gold_collected += campaign_goal_value * 2
	else:
		await _show_text("✘ MISSION FAILED", Color.RED)

	emit_signal("level_completed", success)
	await get_tree().create_timer(1.0).timeout

	if next_scene != "":
		$UI/trasl/anim.play("trs")
	else:
		print("[earth_level] next_scene non impostata.")

# ──────────────────────────────────────────────────────────────────────────────
#  CHEST
# ──────────────────────────────────────────────────────────────────────────────

func _spawn_chest() -> void:
	if chest_scenes.is_empty():
		return
	var chest: Node2D = chest_scenes.pick_random().instantiate()
	if not chest_spawn_points.is_empty():
		chest.global_position = chest_spawn_points.pick_random().global_position
	else:
		var angle = randf_range(0, TAU)
		chest.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(200, 500)
	get_parent().add_child(chest)

# ──────────────────────────────────────────────────────────────────────────────
#  TIMER HELPER
# ──────────────────────────────────────────────────────────────────────────────

func _start_timer(duration: float, callback: Callable) -> void:
	campaign_timer.stop()
	campaign_timer.wait_time = duration
	campaign_timer.one_shot = true
	if not campaign_timer.timeout.is_connected(callback):
		campaign_timer.timeout.connect(callback)
	campaign_timer.start()

# ──────────────────────────────────────────────────────────────────────────────
#  UI HELPER
# ──────────────────────────────────────────────────────────────────────────────

func _show_text(text: String, color: Color) -> void:
	wave_info_label.show()
	wave_info_label.text = text
	wave_info_label.modulate = color
	var tw = create_tween()
	tw.tween_property(wave_info_label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(0.8)
	tw.tween_property(wave_info_label, "modulate:a", 0.0, 0.2)
	tw.tween_callback(Callable(wave_info_label, "hide"))
	await tw.finished

# ──────────────────────────────────────────────────────────────────────────────
#  SCENE TRANSITION
# ──────────────────────────────────────────────────────────────────────────────

func _on_anim_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file(next_scene)
