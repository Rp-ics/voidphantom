extends Node
class_name PVPBot

enum Difficulty { MEDIUM, HARD }

var player: CharacterBody2D
var difficulty: Difficulty = Difficulty.MEDIUM
var bot_peer_id: int = -2
var target: Node2D = null

var _move_dir: Vector2 = Vector2.ZERO
var _aim_dir: Vector2 = Vector2.RIGHT
var _wander_target: Vector2 = Vector2.ZERO
var _state: String = "wander"
var _reaction_timer: float = 0.0
var _reaction_time: float = 0.4
var _shoot_cooldown: float = 0.0
var _skill_cooldown: float = 0.0
var _strafe_dir: float = 1.0
var _strafe_timer: float = 0.0
var _wander_timer: float = 0.0
var _aggression: float = 0.7
var _aim_error: float = 0.15

var _skin_data: Dictionary = {}
var _player_name: String = "Player"

static var bot_names: Array[String] = [
	"ShadowStrike", "FrostByte", "NightOwl", "SteelFang", "BlazeStorm",
	"VoidWalker", "IronClad", "StormChaser", "DarkPhantom", "CrimsonTide",
	"ThunderFist", "GhostReaper", "SilverHawk", "EmberFury", "FrostWolf",
	"VenomStrike", "BladeDancer", "ShadowFury", "StormBreaker", "DeathWish",
	"ArcaneShot", "WildFire", "IceVein", "DarkMatter", "SoulReaper"
]

static var used_names: Array[String] = []

static func get_unique_bot_name() -> String:
	var available = bot_names.filter(func(n): return not n in used_names)
	if available.is_empty():
		used_names.clear()
		available = bot_names.duplicate()
	var name = available[randi() % available.size()]
	used_names.append(name)
	return name

static func generate_random_skin() -> Dictionary:
	return {
		"body": randi() % 15 + 1,
		"wings": randi() % 15 + 1,
		"prop": randi() % 15 + 1,
		"pfp": randi() % 28 + 1,
		"body_colors": _random_colors(),
		"wings_colors": _random_colors(),
		"prop_colors": _random_colors()
	}

static func _random_colors() -> Array:
	return [
		randf_range(0.0, 1.0), randf_range(0.0, 1.0), randf_range(0.0, 1.0),
		randf_range(0.5, 1.5), randf_range(0.5, 1.5), randf_range(0.5, 1.5),
		randf_range(0.0, 0.0), randf_range(0.8, 1.2)
	]

static func get_random_pvp_weapon() -> String:
	var weapons := ["PVP_RAZOR", "PVP_BOLT", "PVP_SPLITTER", "PVP_BOUNCE", "PVP_PIERCE", "PVP_HOMING", "PVP_EXPLODE", "PVP_FREEZE", "PVP_MAGNET", "PVP_SHOTGUN"]
	return weapons[randi() % weapons.size()]

func _init_bot(p: CharacterBody2D, pid: int, diff: Difficulty, weapon_name: String, skin: Dictionary, pname: String):
	player = p
	bot_peer_id = pid
	difficulty = diff
	_player_name = pname
	_skin_data = skin
	
	player.set_multiplayer_authority(bot_peer_id)
	player.mp_peer_id = bot_peer_id
	player.mp_player_name = pname
	player.bot_controlled = true
	player.is_bot = true
	player.is_local_player = false
	
	if skin.has("pfp"):
		player.texture_pfp_icon = skin["pfp"]
	
	if diff == Difficulty.HARD:
		_reaction_time = randf_range(0.02, 0.1)
		_aim_error = randf_range(0.0, 0.03)
		_aggression = randf_range(0.9, 1.2)
	else:
		_reaction_time = randf_range(0.1, 0.2)
		_aim_error = randf_range(0.05, 0.1)
		_aggression = randf_range(0.8, 1.0)
	
	_equip_weapon(weapon_name)
	_apply_skin()
	_setup_timers()

func _equip_weapon(weapon_name: String):
	if player.has_node("Canon") and player.canon.has_method("equip_weapon"):
		player.canon.equip_weapon(weapon_name, "common")
	player.current_weapon = weapon_name

func _apply_skin():
	if not player.has_method("_apply_skin"):
		return
	player._apply_skin(_skin_data)

func _setup_timers():
	_wander_target = _random_arena_pos()
	_wander_timer = randf_range(2.0, 5.0)
	_strafe_timer = randf_range(1.0, 3.0)
	_strafe_dir = 1.0 if randi() % 2 == 0 else -1.0

func _random_arena_pos() -> Vector2:
	var vp = get_viewport().get_visible_rect().size if get_viewport() else Vector2(2000, 1500)
	return Vector2(randf_range(100, vp.x - 100), randf_range(100, vp.y - 100))

func _process(delta):
	if not is_instance_valid(player) or player.mp_is_dead:
		return
	
	_find_target()
	_update_state(delta)
	_update_movement(delta)
	_update_aiming(delta)
	_update_shooting(delta)
	_update_skills(delta)

func _find_target():
	var nearest: Node2D = null
	var min_dist := INF
	for p in get_tree().get_nodes_in_group("player"):
		if p == player or p.get("mp_is_dead") == true:
			continue
		var d = player.global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest = p
	target = nearest

func _update_state(delta):
	if not is_instance_valid(target):
		_state = "wander"
		return

	var dist = player.global_position.distance_to(target.global_position)
	var hp_ratio = player.mp_synced_hp / max(player.mp_max_hp, 1.0)

	if hp_ratio < 0.25:
		_state = "flee"
	elif dist < 600:
		_state = "combat"
	elif dist < 1200:
		_state = "chase"
	else:
		_state = "wander"

func _update_movement(delta):
	var speed_mult = 1.0
	if player.has_buff("chrono_speed"):
		speed_mult = 1.2
	
	match _state:
		"wander":
			_wander_timer -= delta
			if _wander_timer <= 0:
				_wander_target = _random_arena_pos()
				_wander_timer = randf_range(2.0, 5.0)
			_move_dir = (player.global_position.direction_to(_wander_target))
		
		"chase":
			if is_instance_valid(target):
				_move_dir = player.global_position.direction_to(target.global_position)
		
		"combat":
			if is_instance_valid(target):
				_strafe_timer -= delta
				if _strafe_timer <= 0:
					_strafe_dir = 1.0 if randi() % 2 == 0 else -1.0
					_strafe_timer = randf_range(0.2, 1.0)
				var to_target = player.global_position.direction_to(target.global_position)
				var perp = Vector2(-to_target.y, to_target.x)
				var dist = player.global_position.distance_to(target.global_position)
				var move_forward = -to_target if dist < 300 else to_target
				_move_dir = (move_forward * _aggression + perp * _strafe_dir * 1.2).normalized()
		
		"flee":
			if is_instance_valid(target):
				_move_dir = target.global_position.direction_to(player.global_position)
				_wander_timer -= delta
				if _wander_timer <= 0:
					_wander_target = _random_arena_pos()
					_wander_timer = randf_range(2.0, 4.0)
				_move_dir = (_move_dir + player.global_position.direction_to(_wander_target) * 0.3).normalized()
	
	var move_speed = 300.0 * speed_mult
	player.velocity = _move_dir * move_speed
	player.move_and_slide()

func _update_aiming(delta):
	if is_instance_valid(target):
		var target_pos = target.global_position
		var lead = Vector2.ZERO
		if target.has_method("get_current_velocity"):
			var tv = target.get_current_velocity()
			var dist = player.global_position.distance_to(target_pos)
			lead = tv * (dist / 400.0) * 0.3
		var aim_pos = target_pos + lead
		var error_offset = Vector2(randf_range(-_aim_error, _aim_error), randf_range(-_aim_error, _aim_error)) * 100.0
		_aim_dir = player.global_position.direction_to(aim_pos + error_offset)
	else:
		_aim_dir = _move_dir
	
	player.rotation = _aim_dir.angle()

func _update_shooting(delta):
	if _shoot_cooldown > 0:
		_shoot_cooldown -= delta
		return
	
	if not is_instance_valid(target):
		return
	
	var dist = player.global_position.distance_to(target.global_position)
	var in_range = dist < 800
	
	if not in_range and _state != "combat":
		return
	
	var aim_diff = abs(_aim_dir.angle_to(player.global_position.direction_to(target.global_position)))
	var on_target = aim_diff < 0.3
	
	if on_target and player.has_node("Canon") and player.canon.has_method("shoot"):
		player.canon.shoot(true)
		var fire_rate = player.canon.current_weapon.get("fire_rate", 0.25)
		_shoot_cooldown = fire_rate + _reaction_time * 0.5

func _update_skills(delta):
	if _skill_cooldown > 0:
		_skill_cooldown -= delta
		return
	
	if not is_instance_valid(target):
		return
	
	if player.has_method("_trigger_active_skill") and player._skill_ready:
		var dist = player.global_position.distance_to(target.global_position)
		if dist < 800 or randf() < 0.3:
			player._trigger_active_skill()
			_skill_cooldown = 5.0 + randf_range(0, 3.0)

func set_difficulty_string(diff_str: String):
	match diff_str.to_lower():
		"hard": difficulty = Difficulty.HARD
		_: difficulty = Difficulty.MEDIUM
