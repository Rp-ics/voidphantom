extends Node

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal boss_spawned(wave_number: int)
signal wave_timer_updated(time_left: float)
signal all_players_dead()

var current_wave: int = 0
var enemies_alive: int = 0
var boss_active: bool = false
var wave_in_progress: bool = false
var wave_cooldown: float = 10.0
var _cooldown_timer: float = 0.0
var _player_count: int = 1
var _spawn_positions: Array[Vector2] = []
var _enemy_scene: PackedScene = null
var _boss_scene: PackedScene = null
var _spawned_enemy_ids: Array[int] = []
var _next_enemy_id: int = 1

const BASE_ENEMY_HP: float = 50.0
const BASE_ENEMY_COUNT: int = 5
const BASE_BOSS_HP: float = 500.0
const HP_SCALE_PER_PLAYER: float = 0.2
const ENEMY_COUNT_PER_2_PLAYERS: int = 1
const WAVE_HP_BONUS_PERCENT: float = 0.05
const WAVE_DAMAGE_BONUS_PERCENT: float = 0.03
const RESPAWN_DELAY: float = 10.0
const BOSS_WAVE_INTERVAL: int = 10
const MINI_BOSS_WAVE_INTERVAL: int = 5

var arena_ref: Node = null

func _ready():
	_enemy_scene = preload("res://Gres/Multiplayer/scene/pve/PVEEnemy.tscn") if ResourceLoader.exists("res://Gres/Multiplayer/scene/pve/PVEEnemy.tscn") else null
	_boss_scene = preload("res://Gres/Multiplayer/scene/pve/PVEBoss.tscn") if ResourceLoader.exists("res://Gres/Multiplayer/scene/pve/PVEBoss.tscn") else null

func setup(arena: Node, spawn_positions: Array[Vector2], player_count: int):
	arena_ref = arena
	_spawn_positions = spawn_positions
	_player_count = max(1, player_count)
	print("[WaveManager] Setup con %d giocatori" % _player_count)

func start_game():
	current_wave = 0
	_start_next_wave()

func _start_next_wave():
	current_wave += 1
	enemies_alive = 0
	boss_active = false
	wave_in_progress = true
	_spawned_enemy_ids.clear()
	print("[WaveManager] Inizio ondata %d" % current_wave)
	emit_signal("wave_started", current_wave)

	if current_wave % BOSS_WAVE_INTERVAL == 0:
		_spawn_boss()
	elif current_wave % MINI_BOSS_WAVE_INTERVAL == 0:
		_spawn_mini_bosses()
	else:
		_spawn_enemies()

func get_scaled_hp(base_hp: float) -> float:
	var hp = base_hp
	hp *= (1.0 + HP_SCALE_PER_PLAYER * (_player_count - 1))
	hp *= (1.0 + WAVE_HP_BONUS_PERCENT * (current_wave - 1))
	return hp

func get_scaled_damage(base_damage: float) -> float:
	return base_damage * (1.0 + WAVE_DAMAGE_BONUS_PERCENT * (current_wave - 1))

func get_enemy_count() -> int:
	return BASE_ENEMY_COUNT + floor(_player_count / 2) + floor(current_wave * 0.5)

func _spawn_enemies():
	if not multiplayer.is_server():
		return
	var count = get_enemy_count()
	var hp = get_scaled_hp(BASE_ENEMY_HP)
	var dmg = get_scaled_damage(10.0)
	var gold = 5 + floor(current_wave / 3)

	for i in range(count):
		var pos = _get_spawn_position()
		var eid = _next_enemy_id
		_next_enemy_id += 1
		_spawn_single_enemy.rpc("enemy", eid, pos, hp, hp, 80.0 + current_wave * 2, dmg, gold)

func _spawn_mini_bosses():
	if not multiplayer.is_server():
		return
	var count = 1 + floor(_player_count / 2)
	var hp = get_scaled_hp(BASE_ENEMY_HP * 5)
	var dmg = get_scaled_damage(20.0)
	var gold = 25 + floor(current_wave / 2)

	for i in range(count):
		var pos = _get_spawn_position()
		var eid = _next_enemy_id
		_next_enemy_id += 1
		_spawn_single_enemy.rpc("miniboss", eid, pos, hp, hp, 60.0, dmg, gold)

func _spawn_boss():
	if not multiplayer.is_server():
		return
	var hp = get_scaled_hp(BASE_BOSS_HP * _player_count)
	var dmg = get_scaled_damage(30.0)
	var gold = 100 + current_wave * 5
	var pos = _get_spawn_position()
	var eid = _next_enemy_id
	_next_enemy_id += 1
	_spawn_single_enemy.rpc("boss", eid, pos, hp, hp, 50.0, dmg, gold)
	emit_signal("boss_spawned", current_wave)

@rpc("authority", "call_local", "reliable")
func _spawn_single_enemy(type: String, eid: int, pos: Vector2, hp_val: float, max_hp_val: float, spd: float, dmg: float, gold: int):
	var scene = null
	var is_boss = false
	var is_mini = false
	var max_phases = 1

	match type:
		"boss":
			scene = _boss_scene
			is_boss = true
			max_phases = 3
		"miniboss":
			scene = _boss_scene
			is_mini = true
			max_phases = 2
		_:
			scene = _enemy_scene

	if not scene:
		print("[WaveManager] Nessuna scena per tipo: ", type)
		return

	var enemy = scene.instantiate()
	enemy.position = pos
	enemy.hp = hp_val
	enemy.max_hp = max_hp_val
	enemy.move_speed = spd
	enemy.contact_damage = dmg
	enemy.gold_reward = gold
	enemy.enemy_id = eid
	enemy.is_boss = is_boss
	enemy.is_mini_boss = is_mini
	if max_phases > 1:
		enemy.max_phases = max_phases

	enemy.enemy_killed.connect(_on_enemy_killed.bind(enemy))
	add_child(enemy)

	if multiplayer.is_server():
		enemies_alive += 1
		_spawned_enemy_ids.append(eid)

	if not multiplayer.is_server():
		enemy.set_physics_process(false)

func _on_enemy_killed(killer_peer_id: int, enemy_id: int, gold_reward: int, enemy_node: Node):
	if not multiplayer.is_server():
		return
	enemies_alive -= 1
	print("[WaveManager] Nemico %d ucciso da peer %d. Rimanenti: %d" % [enemy_id, killer_peer_id, enemies_alive])

	if arena_ref and arena_ref.has_method("_award_pve_loot"):
		arena_ref._award_pve_loot(killer_peer_id, gold_reward, enemy_node)

	if enemies_alive <= 0 and not boss_active:
		wave_in_progress = false
		emit_signal("wave_cleared", current_wave)
		_start_wave_cooldown()

func _get_spawn_position() -> Vector2:
	if _spawn_positions.is_empty():
		return Vector2(randf_range(100, 900), randf_range(100, 600))
	return _spawn_positions[randi() % _spawn_positions.size()]

func _start_wave_cooldown():
	_cooldown_timer = wave_cooldown
	print("[WaveManager] Cooldown %.1f secondi" % _cooldown_timer)

func _process(delta):
	if not wave_in_progress and _cooldown_timer > 0:
		_cooldown_timer -= delta
		emit_signal("wave_timer_updated", _cooldown_timer)
		if _cooldown_timer <= 0:
			_cooldown_timer = 0
			if enemies_alive <= 0 and not boss_active:
				_start_next_wave()

func get_wave_state() -> Dictionary:
	return {
		"current_wave": current_wave,
		"enemies_alive": enemies_alive,
		"boss_active": boss_active,
		"wave_in_progress": wave_in_progress,
		"cooldown_timer": _cooldown_timer,
		"player_count": _player_count
	}

func restore_state(state: Dictionary):
	current_wave = state.get("current_wave", 0)
	enemies_alive = state.get("enemies_alive", 0)
	boss_active = state.get("boss_active", false)
	wave_in_progress = state.get("wave_in_progress", false)
	_cooldown_timer = state.get("cooldown_timer", 0.0)
	_player_count = state.get("player_count", _player_count)

func serialize_state() -> Dictionary:
	return get_wave_state()
