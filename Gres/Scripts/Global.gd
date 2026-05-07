extends Node

#-signals-#
signal gun_box(weapon_name)
signal bonus_touched(bonus_type: String)
signal weapon_equipped(weapon_name: String, rarity: String)
signal weapon_unlocked(weapon_name: String, rarity: String)
signal material_changed(mat_name: String)
signal save_completed(success: bool)
signal load_completed(success: bool)

# === SAVE SYSTEM (SOLO LOCALE) === #
var LOCAL_SAVE_PATH = "user://player_data_local.save"
var BACKUP_PATH = "user://backups/"
var SAVE_VERSION = 3
var last_save_time = 0.0
var autosave_timer: Timer
var backup_timer: Timer

# === STARTER === #
var starter := true
var bonus_taken := false
var unque_achieve := false
var in_tutorial := true

# === TEXT === #
var story_line := 0

# === ENEMY B === #
var is_deflected := false

# === PLAYER === #
var player: Node = null
var canon: Node = null

# === DAILY === #
var spin_gem := 0

var player_hp := 100
var player_max_hp := 100
var player_hp_reg := 0
var player_stamina := 100
var player_max_stamina := 100
var chance_not_consum_stamina := 0.0
var stamina_regen_skill := false

# ==== VELOCITÀ ====
var move_speed := 400.0
var dash_speed := 800.0
var dash_duration := 0.2
var dash_cooldown := 3.0

var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0

var player_bullets := 10
var player_max_bullets := 10
var player_damage := 1.0
var player_bullet_speed := 400
var player_max_bullet_speed := 400
var PlayerX := 0.0
var PlayerY := 0.0
var player_immunity := false
var player_immunity_time := 6.0
var player_dead := false
var shoot_freeze := 0.1
var cam_shake := 20.0
var texture_body := 1
var texture_wing := 1
var texture_prop := 1
var texture_canon := 0
var texture_pfp_icon := 1
var texture_pfp_bg := 1
var texture_pfp_cover := 1
var wave := 1

var hurt := false
var slow_factor := 1.0
var bullets := 20
var max_bullets := 20

var bullets_cons_percent := 2.0

var LOCKED_BODIES = [12, 13, 14, 15] as Array[int]
var LOCKED_PROPS = [12, 13, 14, 15] as Array[int]
var LOCKED_WINGS = [12, 13, 14, 15] as Array[int]

var menu_max_offset := 20.0
var menu_smooth_speed := 200.0

# === COLOR SETTINGS === #
var mouse_color_red := 1.0
var mouse_color_blue := 1.0
var mouse_color_green := 1.0

var body_red_factor := 1.0
var body_green_factor := 1.0
var body_blue_factor := 1.0
var body_saturation := 1.0
var body_brightness := 0.0
var body_contrast := 1.0
var body_hue_shift := 0.0
var body_gamma := 1.0

var prop_red_factor := 1.0
var prop_green_factor := 1.0
var prop_blue_factor := 1.0
var prop_saturation := 1.0
var prop_brightness := 0.0
var prop_contrast := 1.0
var prop_hue_shift := 0.0
var prop_gamma := 1.0

var wings_red_factor := 1.0
var wings_green_factor := 1.0
var wings_blue_factor := 1.0
var wings_saturation := 1.0
var wings_brightness := 0.0
var wings_contrast := 1.0
var wings_hue_shift := 0.0
var wings_gamma := 1.0

var canon_red_factor := 1.0
var canon_green_factor := 1.0
var canon_blue_factor := 1.0
var canon_saturation := 1.0
var canon_brightness := 0.0
var canon_contrast := 1.0
var canon_hue_shift := 0.0
var canon_gamma := 1.0

# === ICONS === #
var wrath_icons := {
	"easy": false,
	"normal": false,
	"hard": false
}

# === AUDIO SETTINGS ===
var music_volume: float = 50.0
var effects_volume: float = 10.0
var master_volume: float = 100.0

# === GRAPHIC === 
var screenX := 1920
var screenY := 1080
var resolution: Vector2i = Vector2i(screenX, screenY)
var fullscreen: bool = true
var vsync: bool = true
var bloom_quality: float = 80.0
var particle_quality: float = 80.0

# === MODE === #
var campaign_goal_type := ""
var base_hurt := false
var base_wall_destroyed := false
var base_destroyed := 0
var assault_done := false

# === BOSS === #
var boss_mame := ""
var mother_right_canon_damaged := false
var mother_left_canon_damaged := false
var boss_killed := false
var state: String = "PHASE1"
var blood_mother_hp: int
var wrath_hp: int
var wrath_max_hp: int = 10000
var wrath_difficulty_for_drops := "easy"

# === ENEMY === #
var aggro_level: int = 0
var enemy_type = "enemy"
# === CHEST RARITY ===
var rarity = ['common', 'rare']

# === KEYMAP ===
var bindings = {}
var can_activate := true

# === MAP === 
var can_show_map := true
var mapX := 96.0
var mapY := 554.0
var radar_radius := 80
var radar_range := 500.0

# === GUI ===
var hp_show := true
var stm_show := true

# === PLAYER CAMERA ===
var shake_strength := 20.0
var smoothing_speed := 8.0
var lookahead_distance := 10.0
var lookahead_speed := 6.0
var shake_decay := 5.0

# === RUNS === #
var mode := ""
var dungeons := {
	'lvl_1': {'easy': false, 'normal': false, 'hard': false},
	'lvl_2': {'easy': false, 'normal': false, 'hard': false},
	'lvl_3': {'easy': false, 'normal': false, 'hard': false},
	'lvl_4': {'easy': false, 'normal': false, 'hard': false},
	'lvl_5': {'easy': false, 'normal': false, 'hard': false},
	'lvl_6': {'easy': false, 'normal': false, 'hard': false},
}


func generate_daily_missions(date_string: String):
	# Lista di possibili missioni (pool)
	var pool = [
		{
			"id": "kill_common",
			"display_name": "Hunter",
			"description": "Kill 250 enemies",
			"target": 250,
			"reward_gold": 3250
		},
		{
			"id": "dash_uses",
			"display_name": "Dasher",
			"description": "Use dash 120 times",
			"target": 120,
			"reward_gold": 1500
		},
		{
			"id": "collect_void",
			"display_name": "Collector",
			"description": "Open 25 chest",
			"target": 25,
			"reward_gold": 2500
		},
		{
			"id": "damage_done",
			"display_name": "Buller",
			"description": "Deal a total of 36,000 damage to enemies",
			"target": 36000,
			"reward_gold": 3600
		},
		{
			"id": "die_time_1",
			"display_name": "Death collector I",
			"description": "Die 50 times",
			"target": 50,
			"reward_gold": 1500
		},
		{
			"id": "die_time_2",
			"display_name": "Death collector II",
			"description": "Die 150 times",
			"target": 150,
			"reward_gold": 2500
		},
		{
			"id": "die_time_3",
			"display_name": "Death collector III",
			"description": "Die 200 times",
			"target": 200,
			"reward_gold": 3500
		},
		{
			"id": "rich_game_1",
			"display_name": "Rich Game I",
			"description": "collect 2000 gold",
			"target": 2000,
			"reward_gold": 1500
		},
		{
			"id": "rich_game_2",
			"display_name": "Rich Game II",
			"description": "collect 3500 gold",
			"target": 3500,
			"reward_gold": 2500
		},
		{
			"id": "rich_game_3",
			"display_name": "Rich Game III",
			"description": "collect 6000 gold",
			"target": 6000,
			"reward_gold": 3500
		},
		{
			"id": "resist_1",
			"display_name": "Srong fighter I",
			"description": "Reach Wave 10",
			"target": 10,
			"reward_gold": 1500
		},
		{
			"id": "resist_2",
			"display_name": "Srong fighter II",
			"description": "Reach Wave 25",
			"target": 25,
			"reward_gold": 2500
		},
		{
			"id": "resist_3",
			"display_name": "Srong fighter III",
			"description": "Reach Wave 40",
			"target": 40,
			"reward_gold": 4000
		},
		{
			"id": "perfect_waves_1",
			"display_name": "PerfectionistII",
			"description": "Reach wave 3 without taking any damage",
			"target": 3,
			"reward_gold": 1500
		},
		{
			"id": "perfect_waves_2",
			"display_name": "PerfectionistII",
			"description": "Reach wave 5 without taking any damage",
			"target": 5,
			"reward_gold": 2500
		},
		{
			"id": "boss_killer_1",
			"display_name": "Boss Killer I",
			"description": "Kill any boss 5 time's",
			"target": 5,
			"reward_gold": 2000
		},
		{
			"id": "boss_killer_2",
			"display_name": "Boss Killer II",
			"description": "Kill any medium difficulty boss 5 time's",
			"target": 5,
			"reward_gold": 4000
		},
		{
			"id": "boss_killer_3",
			"display_name": "Boss Killer III",
			"description": "Kill any hard difficulty boss 5 time's",
			"target": 5,
			"reward_gold": 8000
		},
		{
			"id": "expert_hunter_1",
			"display_name": "Expert hunter I",
			"description": "Kill any Miniboss 20 time's",
			"target": 20,
			"reward_gold": 1500
		},
		{
			"id": "expert_hunter_2",
			"display_name": "Expert hunter II",
			"description": "Kill any Miniboss 60 time's",
			"target": 60,
			"reward_gold": 2500
		},
		{
			"id": "expert_hunter_3",
			"display_name": "Expert hunter III",
			"description": "Kill any Miniboss 80 time's",
			"target": 80,
			"reward_gold": 3500
		},
	]
	
	# Seme basato sulla data + eventuale seed fisso per non replicare pattern banali
	var seed_value = hash(date_string) + GlobalStats.daily_mission_seed
	seed(seed_value)
	pool.shuffle()
	
	# Scegliamo 3 missioni (o quante vuoi)
	GlobalStats.daily_missions = pool.slice(0, 3)
	for mission in GlobalStats.daily_missions:
		mission["progress"] = 0
		mission["claimed"] = false
	
	GlobalStats.daily_last_reset_date = date_string
	GlobalStats.save_data_stats()  # salva le missioni nel file corretto

func get_daily_missions() -> Array:
	return GlobalStats.daily_missions

func claim_mission(index: int) -> String:
	if index < 0 or index >= GlobalStats.daily_missions.size():
		return "❌ Invalid mission index"
	
	var mission: Dictionary = GlobalStats.daily_missions[index]
	
	if mission.get("claimed", false):
		return "⚠ Mission already claimed"
	
	if mission.get("progress", 0) < mission.get("target", 0):
		return "⚠ Mission not yet completed"
	
	# Grant the reward
	var reward: int = mission.get("reward_gold", 0)
	GlobalStats.gold += reward
	mission["claimed"] = true
	
	# Update progress toward the special coin
	GlobalStats.special_coin_progress += 1
	var bonus_msg: String = ""
	if GlobalStats.special_coin_progress >= 3:
		GlobalStats.special_coin_progress = 0
		GlobalStats.void_coins += 1
		bonus_msg = "\n🪙 You got a Special Coin!"
	
	GlobalStats.save_data_stats()
	return "✅ Claimed %d gold!%s" % [reward, bonus_msg]
	

func update_mission_progress(mission_id: String, amount: int = 1) -> void:
	for mission in GlobalStats.daily_missions:
		if mission.get("id", "") == mission_id and not mission.get("claimed", false):
			var old_progress: int = mission.get("progress", 0)
			var target: int = mission.get("target", 0)
			mission["progress"] = min(old_progress + amount, target)
			break
	
# === ENEMY === #
var enemy_hp_multiplier = 1.0
var enemy_damage_multiplier = 1.0
var enemy_speed_multiplier = 1.0
var enemy_firerate_multiplier = 1.0
var dificulty := "easy"

# === BULLET === #
var bullet_life = 10.0

# === ARMI SBLOCCATE === #
var unlocked_weapons := {
	"common": [],
	"rare": [],
	"epic": [],
	"legendary": []
}

var equipped_weapon := {
	"name": "SOLBREAKER",
	"rarity": "common"
}

var weapons_found := {
	"common": [],
	"rare": [],
	"epic": [],
	"legendary": []
}

# === CRAFTING SYSTEM === #
var materials := {
	"VoidShard": 0,
	"MagmaShard": 0,
	"IceShard": 0,
	"LightShard": 0
}

# ========================= #
# === WEAPON DATA SYSTEM === #
# ========================= #
var weapons_data := {
	"common": {
		"SOLBREAKER": {
			"display_name": "SOLBREAKER",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_0C.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 0,
				"IceShard": 6,
				"LightShard": 0
			}
		},
		"AEGIS TEMPEST": {
			"display_name": "AEGIS TEMPEST",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_1C.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 6,
				"IceShard": 0,
				"LightShard": 6
			}
		},
		"HELLWING": {
			"display_name": "HELLWING",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_2C.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 0,
				"IceShard": 6,
				"LightShard": 0
			}
		},
		"NEBULAR STORM": {
			"display_name": "NEBULAR STORM",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_3C.png",
			"craft_materials": {
				"VoidShard": 0,
				"MagmaShard": 0,
				"IceShard": 0,
				"LightShard": 0
			}
		},
		"VOIDLANCE": {
			"display_name": "VOIDLANCE",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_4C.png",
			"craft_materials": {
				"VoidShard": 0,
				"MagmaShard": 6,
				"IceShard": 0,
				"LightShard": 6
			}
		},
		"ASTRIX REBOUND": {
			"display_name": "ASTRIX REBOUND",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_5C.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 6,
				"IceShard": 6,
				"LightShard": 0
			}
		},
		"PHANTOM SEEKER": {
			"display_name": "PHANTOM SEEKER",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_6C.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 0,
				"IceShard": 0,
				"LightShard": 6
			}
		},
		"OMNIVORE": {
			"display_name": "OMNIVORE",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_7C.png",
			"craft_materials": {
				"VoidShard": 0,
				"MagmaShard": 6,
				"IceShard": 6,
				"LightShard": 0
			}
		},
		"SUPERNOVA CORE": {
			"display_name": "SUPERNOVA CORE",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_8C.png",
			"craft_materials": {
				"VoidShard": 0,
				"MagmaShard": 6,
				"IceShard": 6,
				"LightShard": 6
			}
		},
		"ECLIPSE FRACTAL": {
			"display_name": "ECLIPSE FRACTAL",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_9C.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 0,
				"IceShard": 6,
				"LightShard": 0
			}
		},
		"VOID REAVER": {
			"display_name": "VOID REAVER",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_10C.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 6,
				"IceShard": 0,
				"LightShard": 0
			}
		},
	},
	"rare": {
		"SOLBREAKER": {
			"display_name": "SOLBREAKER",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_0R.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 8,
				"IceShard": 6,
				"LightShard": 8
			}
		},
		"AEGIS TEMPEST": {
			"display_name": "AEGIS TEMPEST",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_1R.png",
			"craft_materials": {
				"VoidShard": 8,
				"MagmaShard": 6,
				"IceShard": 6,
				"LightShard": 8
			}
		},
		"HELLWING": {
			"display_name": "HELLWING",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_2R.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 6,
				"IceShard": 8,
				"LightShard": 8
			}
		},
		"NEBULAR STORM": {
			"display_name": "NEBULAR STORM",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_3R.png",
			"craft_materials": {
				"VoidShard": 8,
				"MagmaShard": 8,
				"IceShard": 6,
				"LightShard": 6
			}
		},
		"VOIDLANCE": {
			"display_name": "VOIDLANCE",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_4R.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 6,
				"IceShard": 8,
				"LightShard": 8
			}
		},
		"ASTRIX REBOUND": {
			"display_name": "ASTRIX REBOUND",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_5R.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 8,
				"IceShard": 8,
				"LightShard": 6
			}
		},
		"PHANTOM SEEKER": {
			"display_name": "PHANTOM SEEKER",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_6R.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 8,
				"IceShard": 8,
				"LightShard": 6
			}
		},
		"OMNIVORE": {
			"display_name": "OMNIVORE",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_7R.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 6,
				"IceShard": 8,
				"LightShard": 8
			}
		},
		"SUPERNOVA CORE": {
			"display_name": "SUPERNOVA CORE",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_8R.png",
			"craft_materials": {
				"VoidShard": 6,
				"MagmaShard": 8,
				"IceShard": 8,
				"LightShard": 6
			}
		},
		"ECLIPSE FRACTAL": {
			"display_name": "ECLIPSE FRACTAL",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_9R.png",
			"craft_materials": {
				"VoidShard": 8,
				"MagmaShard": 8,
				"IceShard": 6,
				"LightShard": 6
			}
		},
		"VOID REAVER": {
			"display_name": "VOID REAVER",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_10R.png",
			"craft_materials": {
				"VoidShard": 8,
				"MagmaShard": 6,
				"IceShard": 6,
				"LightShard": 8
			}
		},
	},
	"epic": {
		"SOLBREAKER": {
			"display_name": "SOLBREAKER",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_0E.png",
			"craft_materials": {
				"VoidShard": 12,
				"MagmaShard": 12,
				"IceShard": 16,
				"LightShard": 16
			}
		},
		"AEGIS TEMPEST": {
			"display_name": "AEGIS TEMPEST",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_1E.png",
			"craft_materials": {
				"VoidShard": 12,
				"MagmaShard": 16,
				"IceShard": 12,
				"LightShard": 16
			}
		},
		"HELLWING": {
			"display_name": "HELLWING",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_2E.png",
			"craft_materials": {
				"VoidShard": 12,
				"MagmaShard": 16,
				"IceShard": 16,
				"LightShard": 12
			}
		},
		"NEBULAR STORM": {
			"display_name": "NEBULAR STORM",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_3E.png",
			"craft_materials": {
				"VoidShard": 16,
				"MagmaShard": 12,
				"IceShard": 12,
				"LightShard": 16
			}
		},
		"VOIDLANCE": {
			"display_name": "VOIDLANCE",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_4E.png",
			"craft_materials": {
				"VoidShard": 16,
				"MagmaShard": 16,
				"IceShard": 12,
				"LightShard": 12
			}
		},
		"ASTRIX REBOUND": {
			"display_name": "ASTRIX REBOUND",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_5E.png",
			"craft_materials": {
				"VoidShard": 12,
				"MagmaShard": 16,
				"IceShard": 12,
				"LightShard": 16
			}
		},
		"PHANTOM SEEKER": {
			"display_name": "PHANTOM SEEKER",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_6E.png",
			"craft_materials": {
				"VoidShard": 12,
				"MagmaShard": 12,
				"IceShard": 16,
				"LightShard": 16
			}
		},
		"OMNIVORE": {
			"display_name": "OMNIVORE",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_7E.png",
			"craft_materials": {
				"VoidShard": 16,
				"MagmaShard": 12,
				"IceShard": 16,
				"LightShard": 12
			}
		},
		"SUPERNOVA CORE": {
			"display_name": "SUPERNOVA CORE",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_8E.png",
			"craft_materials": {
				"VoidShard": 12,
				"MagmaShard": 12,
				"IceShard": 16,
				"LightShard": 16
			}
		},
		"ECLIPSE FRACTAL": {
			"display_name": "ECLIPSE FRACTAL",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_9E.png",
			"craft_materials": {
				"VoidShard": 12,
				"MagmaShard": 16,
				"IceShard": 16,
				"LightShard": 12
			}
		},
		"VOID REAVER": {
			"display_name": "VOID REAVER",
			"icon": "res://Gres/Assets/player/weapons/common/rotated/icon_gun_10E.png",
			"craft_materials": {
				"VoidShard": 16,
				"MagmaShard": 12,
				"IceShard": 12,
				"LightShard": 16
			}
		},
	},
	"legendary": {
		"GAEA CORE": {
			"display_name": "GAEA CORE",
			"icon": "res://Gres/Assets/Icons/craft/gaea_core_icon.png",
			"craft_materials": {
				"VoidShard": 20,
				"MagmaShard": 20,
				"IceShard": 20,
				"LightShard": 20
			}
		},
		"BLOOD_NEXUS": {
			"display_name": "BLOOD_NEXUS",
			"icon": "res://Gres/Assets/Icons/craft/blood_mother.png",
			"craft_materials": {
				"VoidShard": 20,
				"MagmaShard": 20,
				"IceShard": 20,
				"LightShard": 20
			}
		},
		"VULRATH IGNIS-SUNDER": {
			"display_name": "VULRATH IGNIS-SUNDER",
			"icon": "res://Gres/Assets/Icons/craft/aries.png",
			"craft_materials": {
				"VoidShard": 20,
				"MagmaShard": 20,
				"IceShard": 20,
				"LightShard": 20
			}
		},
		"GORHAL IRONBREAKER": {
			"display_name": "GORHAL IRONBREAKER",
			"icon": "res://Gres/Assets/Icons/craft/taurus.png",
			"craft_materials": {
				"VoidShard": 20,
				"MagmaShard": 20,
				"IceShard": 20,
				"LightShard": 20
			}
		},
		"SHYREL DUAL-FATE": {
			"display_name": "SHYREL DUAL-FATE",
			"icon": "res://Gres/Assets/Icons/craft/gemini.png",
			"craft_materials": {
				"VoidShard": 20,
				"MagmaShard": 20,
				"IceShard": 20,
				"LightShard": 20
			}
		},
		"ANONYMOUSE MAELKRITH": {
			"display_name": "ANONYMOUSE MAELKRITH",
			"icon": "res://Gres/Assets/Icons/craft/cancer.png",
			"craft_materials": {
				"VoidShard": 20,
				"MagmaShard": 20,
				"IceShard": 20,
				"LightShard": 20
			}
		},
	},
}

# === WEAPONS === #
func get_weapon_data(weapon_name: String, rarity: String) -> Dictionary:
	return weapons_data.get(rarity, {}).get(weapon_name, {})

func craft_weapon(weapon_name: String, rarity: String) -> String:
	var weapon_data = get_weapon_data(weapon_name, rarity)
	if weapon_data.is_empty():
		return "❌ Weapon data not found."

	var gold_costs := {
		"common": 2000,
		"rare": 5000,
		"epic": 10000,
		"legendary": 25000
	}
	var gold_cost = gold_costs.get(rarity, 0)

	if GlobalStats.gold < gold_cost:
		return "💰 Not enough gold! (%d / %d)" % [GlobalStats.gold, gold_cost]

	for mat_name in weapon_data.craft_materials.keys():
		var need = weapon_data.craft_materials[mat_name]
		var have = get_material_count(mat_name)
		if have < need:
			return "⚠️ Not enough %s! (%d / %d)" % [mat_name, have, need]

	for mat_name in weapon_data.craft_materials.keys():
		consume_material(mat_name, weapon_data.craft_materials[mat_name])

	GlobalStats.gold -= gold_cost
	print("💸 Spesi", gold_cost, "gold per craft", weapon_name)
	register_found_weapon(weapon_name, rarity)
	return "✅ Crafted %s (%s)! (-%d gold)" % [weapon_name.capitalize(), rarity.capitalize(), gold_cost]

func get_material_icon(mat_name: String) -> String:
	var icons = {
		"VoidShard": "res://Gres/Assets/Icons/craft/cryst_1.png",
		"MagmaShard": "res://Gres/Assets/Icons/craft/cryst_2.png",
		"IceShard": "res://Gres/Assets/Icons/craft/cryst_3.png",
		"LightShard": "res://Gres/Assets/Icons/craft/cryst_4.png"
	}
	return icons.get(mat_name, "res://Gres/Assets/Icons/craft/default.png")

func get_material_count(mat_name: String) -> int:
	match mat_name:
		"VoidShard":
			return GlobalStats.void_shard
		"MagmaShard":
			return GlobalStats.magma_shard
		"IceShard":
			return GlobalStats.ice_shard
		"LightShard":
			return GlobalStats.light_shard
		_:
			return 0

func add_material(mat_name: String, amount: int = 1) -> void:
	if materials.has(mat_name):
		materials[mat_name] += amount
		emit_signal("material_changed", mat_name)
		print("➕ Aggiunto materiale:", mat_name, "x", amount)
	else:
		push_warning("Materiale sconosciuto: %s" % mat_name)

func consume_material(mat_name: String, amount: int) -> void:
	match mat_name:
		"VoidShard":
			GlobalStats.void_shard = max(0, GlobalStats.void_shard - amount)
		"MagmaShard":
			GlobalStats.magma_shard = max(0, GlobalStats.magma_shard - amount)
		"IceShard":
			GlobalStats.ice_shard = max(0, GlobalStats.ice_shard - amount)
		"LightShard":
			GlobalStats.light_shard = max(0, GlobalStats.light_shard - amount)
		_:
			push_warning("Tentato di consumare materiale inesistente: %s" % mat_name)

func has_materials_for(cost: Dictionary) -> bool:
	for mat_name in cost.keys():
		if get_material_count(mat_name) < cost[mat_name]:
			return false
	return true

func apply_craft_cost(cost: Dictionary) -> void:
	for mat_name in cost.keys():
		consume_material(mat_name, cost[mat_name])

func has_found_weapon(weapon_name: String, rarity: String) -> bool:
	if not weapons_found.has(rarity):
		return false
	return weapon_name in weapons_found[rarity]

func register_found_weapon(weapon_name: String, rarity: String) -> void:
	if not weapons_found.has(rarity):
		weapons_found[rarity] = []
	if weapon_name not in weapons_found[rarity]:
		weapons_found[rarity].append(weapon_name)
		print("🧩 Arma trovata:", weapon_name, rarity)

func equip_weapon(weapon_name: String, rarity: String) -> void:
	equipped_weapon.name = weapon_name
	equipped_weapon.rarity = rarity
	emit_signal("weapon_equipped", weapon_name, rarity)

func unlock_weapon(weapon_name: String, rarity: String) -> void:
	if not unlocked_weapons.has(rarity):
		unlocked_weapons[rarity] = []
	if weapon_name not in unlocked_weapons[rarity]:
		unlocked_weapons[rarity].append(weapon_name)
		emit_signal("weapon_unlocked", weapon_name, rarity)
		print("🔓 Unlocked:", weapon_name, rarity)

func is_weapon_unlocked(weapon_name: String, rarity: String = "common") -> bool:
	return unlocked_weapons.has(rarity) and weapon_name in unlocked_weapons[rarity]

func clear_unlocked_weapons():
	for rarity in unlocked_weapons.keys():
		unlocked_weapons[rarity].clear()
	save_game()

# Chiama questa funzione una volta per inizializzare i dati di crafting
func sync_weapons_data_from_global_weapons() -> void:
	# Popola weapons_data usando GlobalWeapons.weapons
	for weapon_name in GlobalWeapons.weapons.keys():
		var rarities = GlobalWeapons.weapons[weapon_name]
		for rarity in rarities.keys():
			if not weapons_data.has(rarity):
				weapons_data[rarity] = {}
			if not weapons_data[rarity].has(weapon_name):
				weapons_data[rarity][weapon_name] = {
					"display_name": weapon_name,
					"icon": rarities[rarity].get("texture", "res://Gres/Assets/Icons/default.png"),
					"craft_materials": {
						"VoidShard": 0,
						"MagmaShard": 0,
						"IceShard": 0,
						"LightShard": 0
					}
				}
	print("✅ weapons_data sincronizzato con GlobalWeapons")

# Sblocca tutte le armi nel crafting (aggiunge a weapons_found)
func unlock_all_weapons_for_crafting() -> void:
	for rarity in weapons_data.keys():
		if not weapons_found.has(rarity):
			weapons_found[rarity] = []
		for weapon_name in weapons_data[rarity].keys():
			if weapon_name not in weapons_found[rarity]:
				weapons_found[rarity].append(weapon_name)
	print("🔓 Tutte le armi sbloccate nel crafting")
	
# ======================================
# SAVE SYSTEM - FUNZIONI PRINCIPALI (LOCALE)
# ======================================

func collect_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"save_date": Time.get_datetime_string_from_system(),
		"save_timestamp": Time.get_unix_time_from_system(),
		
		# Player Data
		"starter": starter,
		"bonus_taken": bonus_taken,
		"spin_gem": spin_gem,
		"story_line": story_line,
		
		# Textures
		"texture_body": texture_body,
		"texture_wing": texture_wing,
		"texture_prop": texture_prop,
		"texture_canon": texture_canon,
		"texture_pfp_icon": texture_pfp_icon,
		"texture_pfp_bg": texture_pfp_bg,
		"texture_pfp_cover": texture_pfp_cover,
		
		# === ICONS === #
		"wrath_icons": wrath_icons,
		# Player Stats
		"player_max_hp": player_max_hp,
		"player_hp_reg": player_hp_reg,
		"player_max_stamina": player_max_stamina,
		"chance_not_consum_stamina": chance_not_consum_stamina,
		"stamina_regen_skill": stamina_regen_skill,
		"player_max_bullets": player_max_bullets,
		"player_damage": player_damage,
		"player_bullet_speed": player_bullet_speed,
		"player_max_bullet_speed": player_max_bullet_speed,
		"shoot_freeze": shoot_freeze,
		
		# Movement
		"move_speed": move_speed,
		"dash_speed": dash_speed,
		"dash_duration": dash_duration,
		"dash_cooldown": dash_cooldown,
		
		# Bullet
		"bullet_life": bullet_life,
		"bullets_cons_percent": bullets_cons_percent,
		
		# Weapons
		"unlocked_weapons": unlocked_weapons,
		"weapons_found": weapons_found,
		"equipped_weapon": equipped_weapon,
		
		# Crafting
		"materials": materials,
		
		# Game Progress
		"dungeons": dungeons,
		"mode": mode,
		"in_tutorial": in_tutorial,
		"rarity": rarity,
		
		# Locked Items
		"LOCKED_BODIES": LOCKED_BODIES,
		"LOCKED_PROPS": LOCKED_PROPS,
		"LOCKED_WINGS": LOCKED_WINGS,
		
		# Settings
		"music_volume": music_volume,
		"effects_volume": effects_volume,
		"master_volume": master_volume,
		"screenX": screenX,
		"screenY": screenY,
		"fullscreen": fullscreen,
		"vsync": vsync,
		"bloom_quality": bloom_quality,
		"particle_quality": particle_quality,
		
		# Controls
		"bindings": bindings,
		
		# Map
		"radar_radius": radar_radius,
		"radar_range": radar_range,
		"mapX": mapX,
		"mapY": mapY,
		"hp_show": hp_show,
		"stm_show": stm_show,
		
		# Camera
		"shake_strength": shake_strength,
		"smoothing_speed": smoothing_speed,
		"lookahead_distance": lookahead_distance,
		"lookahead_speed": lookahead_speed,
		"shake_decay": shake_decay,
		
		# Color Settings
		"menu_max_offset": menu_max_offset,
		"menu_smooth_speed": menu_smooth_speed,
		"mouse_color_red": mouse_color_red,
		"mouse_color_blue": mouse_color_blue,
		"mouse_color_green": mouse_color_green,
		"body_red_factor": body_red_factor,
		"body_green_factor": body_green_factor,
		"body_blue_factor": body_blue_factor,
		"body_saturation": body_saturation,
		"body_brightness": body_brightness,
		"body_contrast": body_contrast,
		"body_hue_shift": body_hue_shift,
		"body_gamma": body_gamma,
		
		"wings_red_factor": wings_red_factor,
		"wings_green_factor": wings_green_factor,
		"wings_blue_factor": wings_blue_factor,
		"wings_saturation": wings_saturation,
		"wings_brightness": wings_brightness,
		"wings_contrast": wings_contrast,
		"wings_hue_shift": wings_hue_shift,
		"wings_gamma": wings_gamma,
		
		"prop_red_factor": prop_red_factor,
		"prop_green_factor": prop_green_factor,
		"prop_blue_factor": prop_blue_factor,
		"prop_saturation": prop_saturation,
		"prop_brightness": prop_brightness,
		"prop_contrast": prop_contrast,
		"prop_hue_shift": prop_hue_shift,
		"prop_gamma": prop_gamma,
		
		"canon_red_factor": canon_red_factor,
		"canon_green_factor": canon_green_factor,
		"canon_blue_factor": canon_blue_factor,
		"canon_saturation": canon_saturation,
		"canon_brightness": canon_brightness,
		"canon_contrast": canon_contrast,
		"canon_hue_shift": canon_hue_shift,
		"canon_gamma": canon_gamma,
		
		# GlobalStats
		"global_stats": {
			"gold": GlobalStats.gold,
			"tablet": GlobalStats.tablet,
			"total_craft": GlobalStats.total_craft,
			"achievements": GlobalStats.achievements,
			"void_shard": GlobalStats.void_shard,
			"magma_shard": GlobalStats.magma_shard,
			"ice_shard": GlobalStats.ice_shard,
			"light_shard": GlobalStats.light_shard,
			"spins": GlobalStats.spins,
			"total_gold_collected": GlobalStats.total_gold_collected,
			"skills_unlocked": GlobalStats.skills_unlocked,
			"skins_unlocked": GlobalStats.skins_unlocked,
			"died_times": GlobalStats.died_times,
			"player_damage_total": GlobalStats.player_damage_total,
			"player_hit_total": GlobalStats.player_hit_total,
			"critical": GlobalStats.critical,
			"critical_damage": GlobalStats.critical_damage,
			"critical_chest": GlobalStats.critical_chest,
			"critical_vampire": GlobalStats.critical_vampire,
			"has_free_spin": GlobalStats.has_free_spin,
			"free_spin_used_today": GlobalStats.free_spin_used_today,
			"stars": GlobalStats.stars,
			"kill_mobs_total": GlobalStats.kill_mobs_total,
			"kill_boss_total": GlobalStats.kill_boss_total,
			"kill_mini_boss_total": GlobalStats.kill_mini_boss_total,
			"total_powerups": GlobalStats.total_powerups,
			"damage_inf_mob_total": GlobalStats.damage_inf_mob_total,
			"damage_inf_miniboss_total": GlobalStats.damage_inf_miniboss_total,
			"damage_inf_boss_total": GlobalStats.damage_inf_boss_total,
			"damage_inf_total": GlobalStats.damage_inf_total,
			"damage_rec_total": GlobalStats.damage_rec_total,
			"nuclear_kill_total": GlobalStats.nuclear_kill_total,
			"bullets_shoot_total": GlobalStats.bullets_shoot_total,
			"bonus_get_total": GlobalStats.bonus_get_total,
			"boss_fight_counter": GlobalStats.boss_fight_counter,
			"play_minutes": GlobalStats.play_minutes,
			"play_seconds": GlobalStats.play_seconds,
			"play_hours": GlobalStats.play_hours,
			"heal_bonus": GlobalStats.heal_bonus,
			"shield_bonus": GlobalStats.shield_bonus,
			"stamina_bonus": GlobalStats.stamina_bonus,
			"speed_bonus": GlobalStats.speed_bonus,
			"time_slow_bonus": GlobalStats.time_slow_bonus,
			"freeze_bonus": GlobalStats.freeze_bonus,
			"weapon_collected_total": GlobalStats.weapon_collected_total,
			"drop_percent": GlobalStats.drop_percent,
			"craft_drop": GlobalStats.craft_drop,
			"double_gold_drop": GlobalStats.double_gold_drop,
			"d_g_drop_percent": GlobalStats.d_g_drop_percent,
			"gold_moltipl": GlobalStats.gold_moltipl,
			"body_lvl": GlobalStats.body_lvl,
			"wings_lvl": GlobalStats.wings_lvl,
			"canon_lvl": GlobalStats.canon_lvl,
			"prop_lvl": GlobalStats.prop_lvl,
			"owned_weapons": GlobalStats.owned_weapons,
		},
		
		# GlobalSkills
		"global_skills": {
			"zodiac": GlobalSkills.zodiac,
			"zodiac_skill_data": GlobalSkills.zodiac_skill_data,
			"zodiac_cards": GlobalSkills.zodiac_cards,
		}
	}

func apply_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	
	var version = data.get("version", 1)
	
	# Player Data
	starter = data.get("starter", starter)
	bonus_taken = data.get("bonus_taken", bonus_taken)
	spin_gem = data.get("spin_gem", spin_gem)
	story_line = data.get("story_line", story_line)
	
	# Textures
	texture_body = data.get("texture_body", texture_body)
	texture_wing = data.get("texture_wing", texture_wing)
	texture_prop = data.get("texture_prop", texture_prop)
	texture_canon = data.get("texture_canon", texture_canon)
	texture_pfp_icon = data.get("texture_pfp_icon", texture_pfp_icon)
	texture_pfp_bg = data.get("texture_pfp_bg", texture_pfp_bg)
	texture_pfp_cover = data.get("texture_pfp_cover", texture_pfp_cover)
	
	# === ICONS === #
	wrath_icons = data.get("wrath_icons", wrath_icons)
	# Player Stats
	player_max_hp = data.get("player_max_hp", player_max_hp)
	player_hp_reg = data.get("player_hp_reg", player_hp_reg)
	player_max_stamina = data.get("player_max_stamina", player_max_stamina)
	chance_not_consum_stamina = data.get("chance_not_consum_stamina", chance_not_consum_stamina)
	stamina_regen_skill = data.get("stamina_regen_skill", stamina_regen_skill)
	player_max_bullets = data.get("player_max_bullets", player_max_bullets)
	player_damage = data.get("player_damage", player_damage)
	player_bullet_speed = data.get("player_bullet_speed", player_bullet_speed)
	player_max_bullet_speed = data.get("player_max_bullet_speed", player_max_bullet_speed)
	shoot_freeze = data.get("shoot_freeze", shoot_freeze)
	
	# Movement
	move_speed = data.get("move_speed", move_speed)
	dash_speed = data.get("dash_speed", dash_speed)
	dash_duration = data.get("dash_duration", dash_duration)
	dash_cooldown = data.get("dash_cooldown", dash_cooldown)
	
	# Bullet
	bullet_life = data.get("bullet_life", bullet_life)
	bullets_cons_percent = data.get("bullets_cons_percent", bullets_cons_percent)
	
	# Weapons
	unlocked_weapons = data.get("unlocked_weapons", unlocked_weapons)
	weapons_found = data.get("weapons_found", weapons_found)
	equipped_weapon = data.get("equipped_weapon", equipped_weapon)
	
	# Crafting
	materials = data.get("materials", materials)
	
	# Game Progress
	dungeons = data.get("dungeons", dungeons)
	mode = data.get("mode", mode)
	in_tutorial = data.get("in_tutorial", in_tutorial)
	rarity = data.get("rarity", rarity)
	
	# Locked Items
	LOCKED_BODIES = data.get("LOCKED_BODIES", LOCKED_BODIES)
	LOCKED_PROPS = data.get("LOCKED_PROPS", LOCKED_PROPS)
	LOCKED_WINGS = data.get("LOCKED_WINGS", LOCKED_WINGS)
	
	# Settings
	music_volume = data.get("music_volume", music_volume)
	effects_volume = data.get("effects_volume", effects_volume)
	master_volume = data.get("master_volume", master_volume)
	screenX = data.get("screenX", screenX)
	screenY = data.get("screenY", screenY)
	fullscreen = data.get("fullscreen", fullscreen)
	vsync = data.get("vsync", vsync)
	bloom_quality = data.get("bloom_quality", bloom_quality)
	particle_quality = data.get("particle_quality", particle_quality)
	
	# Controls
	bindings = data.get("bindings", bindings)
	
	# Map
	radar_radius = data.get("radar_radius", radar_radius)
	radar_range = data.get("radar_range", radar_range)
	mapX = data.get("mapX", mapX)
	mapY = data.get("mapY", mapY)
	hp_show = data.get("hp_show", hp_show)
	stm_show = data.get("stm_show", stm_show)
	
	# Camera
	shake_strength = data.get("shake_strength", shake_strength)
	smoothing_speed = data.get("smoothing_speed", smoothing_speed)
	lookahead_distance = data.get("lookahead_distance", lookahead_distance)
	lookahead_speed = data.get("lookahead_speed", lookahead_speed)
	shake_decay = data.get("shake_decay", shake_decay)
	
	# Color Settings
	menu_max_offset = data.get("menu_max_offset", menu_max_offset)
	menu_smooth_speed = data.get("menu_smooth_speed", menu_smooth_speed)
	mouse_color_red = data.get("mouse_color_red", mouse_color_red)
	mouse_color_blue = data.get("mouse_color_blue", mouse_color_blue)
	mouse_color_green = data.get("mouse_color_green", mouse_color_green)
	body_red_factor = data.get("body_red_factor", body_red_factor)
	body_green_factor = data.get("body_green_factor", body_green_factor)
	body_blue_factor = data.get("body_blue_factor", body_blue_factor)
	body_saturation = data.get("body_saturation", body_saturation)
	body_brightness = data.get("body_brightness", body_brightness)
	body_contrast = data.get("body_contrast", body_contrast)
	body_hue_shift = data.get("body_hue_shift", body_hue_shift)
	body_gamma = data.get("body_gamma", body_gamma)
	
	wings_red_factor = data.get("wings_red_factor", wings_red_factor)
	wings_green_factor = data.get("wings_green_factor", wings_green_factor)
	wings_blue_factor = data.get("wings_blue_factor", wings_blue_factor)
	wings_saturation = data.get("wings_saturation", wings_saturation)
	wings_brightness = data.get("wings_brightness", wings_brightness)
	wings_contrast = data.get("wings_contrast", wings_contrast)
	wings_hue_shift = data.get("wings_hue_shift", wings_hue_shift)
	wings_gamma = data.get("wings_gamma", wings_gamma)
	
	prop_red_factor = data.get("prop_red_factor", prop_red_factor)
	prop_green_factor = data.get("prop_green_factor", prop_green_factor)
	prop_blue_factor = data.get("prop_blue_factor", prop_blue_factor)
	prop_saturation = data.get("prop_saturation", prop_saturation)
	prop_brightness = data.get("prop_brightness", prop_brightness)
	prop_contrast = data.get("prop_contrast", prop_contrast)
	prop_hue_shift = data.get("prop_hue_shift", prop_hue_shift)
	prop_gamma = data.get("prop_gamma", prop_gamma)
	
	canon_red_factor = data.get("canon_red_factor", canon_red_factor)
	canon_green_factor = data.get("canon_green_factor", canon_green_factor)
	canon_blue_factor = data.get("canon_blue_factor", canon_blue_factor)
	canon_saturation = data.get("canon_saturation", canon_saturation)
	canon_brightness = data.get("canon_brightness", canon_brightness)
	canon_contrast = data.get("canon_contrast", canon_contrast)
	canon_hue_shift = data.get("canon_hue_shift", canon_hue_shift)
	canon_gamma = data.get("canon_gamma", canon_gamma)
	
	# GlobalStats
	var gs = data.get("global_stats", {})
	GlobalStats.gold = gs.get("gold", GlobalStats.gold)
	GlobalStats.tablet = gs.get("tablet", GlobalStats.tablet)
	GlobalStats.total_craft = gs.get("total_craft", GlobalStats.total_craft)
	GlobalStats.achievements = gs.get("achievements", GlobalStats.achievements)
	GlobalStats.void_shard = gs.get("void_shard", GlobalStats.void_shard)
	GlobalStats.magma_shard = gs.get("magma_shard", GlobalStats.magma_shard)
	GlobalStats.ice_shard = gs.get("ice_shard", GlobalStats.ice_shard)
	GlobalStats.light_shard = gs.get("light_shard", GlobalStats.light_shard)
	GlobalStats.spins = gs.get("spins", GlobalStats.spins)
	GlobalStats.total_gold_collected = gs.get("total_gold_collected", GlobalStats.total_gold_collected)
	GlobalStats.skills_unlocked = gs.get("skills_unlocked", GlobalStats.skills_unlocked)
	GlobalStats.skins_unlocked = gs.get("skins_unlocked", GlobalStats.skins_unlocked)
	GlobalStats.died_times = gs.get("died_times", GlobalStats.died_times)
	GlobalStats.player_damage_total = gs.get("player_damage_total", GlobalStats.player_damage_total)
	GlobalStats.player_hit_total = gs.get("player_hit_total", GlobalStats.player_hit_total)
	GlobalStats.critical = gs.get("critical", GlobalStats.critical)
	GlobalStats.critical_damage = gs.get("critical_damage", GlobalStats.critical_damage)
	GlobalStats.critical_chest = gs.get("critical_chest", GlobalStats.critical_chest)
	GlobalStats.critical_vampire = gs.get("critical_vampire", GlobalStats.critical_vampire)
	GlobalStats.has_free_spin = gs.get("has_free_spin", GlobalStats.has_free_spin)
	GlobalStats.free_spin_used_today = gs.get("free_spin_used_today", GlobalStats.free_spin_used_today)
	GlobalStats.stars = gs.get("stars", GlobalStats.stars)
	GlobalStats.kill_mobs_total = gs.get("kill_mobs_total", GlobalStats.kill_mobs_total)
	GlobalStats.kill_boss_total = gs.get("kill_boss_total", GlobalStats.kill_boss_total)
	GlobalStats.kill_mini_boss_total = gs.get("kill_mini_boss_total", GlobalStats.kill_mini_boss_total)
	GlobalStats.total_powerups = gs.get("total_powerups", GlobalStats.total_powerups)
	GlobalStats.damage_inf_mob_total = gs.get("damage_inf_mob_total", GlobalStats.damage_inf_mob_total)
	GlobalStats.damage_inf_miniboss_total = gs.get("damage_inf_miniboss_total", GlobalStats.damage_inf_miniboss_total)
	GlobalStats.damage_inf_boss_total = gs.get("damage_inf_boss_total", GlobalStats.damage_inf_boss_total)
	GlobalStats.damage_inf_total = gs.get("damage_inf_total", GlobalStats.damage_inf_total)
	GlobalStats.damage_rec_total = gs.get("damage_rec_total", GlobalStats.damage_rec_total)
	GlobalStats.nuclear_kill_total = gs.get("nuclear_kill_total", GlobalStats.nuclear_kill_total)
	GlobalStats.bullets_shoot_total = gs.get("bullets_shoot_total", GlobalStats.bullets_shoot_total)
	GlobalStats.bonus_get_total = gs.get("bonus_get_total", GlobalStats.bonus_get_total)
	GlobalStats.boss_fight_counter = gs.get("boss_fight_counter", GlobalStats.boss_fight_counter)
	GlobalStats.play_minutes = gs.get("play_minutes", GlobalStats.play_minutes)
	GlobalStats.play_seconds = gs.get("play_seconds", GlobalStats.play_seconds)
	GlobalStats.play_hours = gs.get("play_hours", GlobalStats.play_hours)
	GlobalStats.heal_bonus = gs.get("heal_bonus", GlobalStats.heal_bonus)
	GlobalStats.shield_bonus = gs.get("shield_bonus", GlobalStats.shield_bonus)
	GlobalStats.stamina_bonus = gs.get("stamina_bonus", GlobalStats.stamina_bonus)
	GlobalStats.speed_bonus = gs.get("speed_bonus", GlobalStats.speed_bonus)
	GlobalStats.time_slow_bonus = gs.get("time_slow_bonus", GlobalStats.time_slow_bonus)
	GlobalStats.freeze_bonus = gs.get("freeze_bonus", GlobalStats.freeze_bonus)
	GlobalStats.weapon_collected_total = gs.get("weapon_collected_total", GlobalStats.weapon_collected_total)
	GlobalStats.drop_percent = gs.get("drop_percent", GlobalStats.drop_percent)
	GlobalStats.craft_drop = gs.get("craft_drop", GlobalStats.craft_drop)
	GlobalStats.double_gold_drop = gs.get("double_gold_drop", GlobalStats.double_gold_drop)
	GlobalStats.d_g_drop_percent = gs.get("d_g_drop_percent", GlobalStats.d_g_drop_percent)
	GlobalStats.gold_moltipl = gs.get("gold_moltipl", GlobalStats.gold_moltipl)
	GlobalStats.body_lvl = gs.get("body_lvl", GlobalStats.body_lvl)
	GlobalStats.wings_lvl = gs.get("wings_lvl", GlobalStats.wings_lvl)
	GlobalStats.canon_lvl = gs.get("canon_lvl", GlobalStats.canon_lvl)
	GlobalStats.prop_lvl = gs.get("prop_lvl", GlobalStats.prop_lvl)
	GlobalStats.owned_weapons = gs.get("owned_weapons", GlobalStats.owned_weapons)
	
	# GlobalSkills
	var gskills = data.get("global_skills", {})
	GlobalSkills.zodiac = gskills.get("zodiac", GlobalSkills.zodiac)
	GlobalSkills.zodiac_skill_data = gskills.get("zodiac_skill_data", GlobalSkills.zodiac_skill_data)
	GlobalSkills.zodiac_cards = gskills.get("zodiac_cards", GlobalSkills.zodiac_cards)
	
	return true

# ======================================
# SALVATAGGIO E CARICAMENTO (LOCALE)
# ======================================

func save_game() -> bool:
	var data = collect_save_data()
	var success = false
	
	if save_local(data):
		success = true
		print("✅ Salvataggio locale completato")
	
	last_save_time = Time.get_unix_time_from_system()
	emit_signal("save_completed", success)
	
	if success:
		print("💾 Gioco salvato con successo alle: " + Time.get_time_string_from_system())
	
	return success

func load_game() -> bool:
	var data = load_local()
	var success = false
	
	if not data.is_empty():
		print("✅ Dati caricati da salvataggio locale")
		success = true
	
	# Applica i dati
	if success and apply_save_data(data):
		print("🎮 Dati applicati correttamente")
		
		# Reset dei valori temporanei
		reset_temporary_values()
		
		emit_signal("load_completed", true)
		return true
	else:
		print("⚠ Nessun salvataggio trovato, avvio nuovo gioco")
		reset_to_default()
		emit_signal("load_completed", false)
		return false

func save_local(data: Dictionary) -> bool:
	# Crea backup prima di sovrascrivere
	create_backup()
	
	var file = FileAccess.open(LOCAL_SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_data = JSON.stringify(data, "\t", false)
		file.store_string(json_data)
		file.close()
		return true
	else:
		print("❌ Errore salvataggio locale: " + str(FileAccess.get_open_error()))
		return false

func load_local() -> Dictionary:
	if not FileAccess.file_exists(LOCAL_SAVE_PATH):
		return {}
	
	var file = FileAccess.open(LOCAL_SAVE_PATH, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_data)
		if error == OK:
			return json.data
		else:
			print("❌ Errore parsing JSON locale: " + json.get_error_message())
			print("JSON data: " + json_data.substr(0, 100) + "...")  # Debug
			return {}
	
	return {}

# ======================================
# BACKUP SYSTEM (SOLO LOCALE)
# ======================================

func create_backup():
	# Crea directory backup se non esiste
	var dir = DirAccess.open("user://")
	if dir:
		if not dir.dir_exists(BACKUP_PATH):
			var error = dir.make_dir(BACKUP_PATH)
			if error != OK:
				print("❌ Impossibile creare directory backup")
				return
	
	# Crea nome file con timestamp
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var backup_file = BACKUP_PATH + "backup_" + timestamp + ".save"
	
	# Copia il file corrente
	if FileAccess.file_exists(LOCAL_SAVE_PATH):
		var current = FileAccess.get_file_as_bytes(LOCAL_SAVE_PATH)
		var backup = FileAccess.open(backup_file, FileAccess.WRITE)
		if backup:
			backup.store_buffer(current)
			backup.close()
			
			# Mantieni solo gli ultimi 5 backup
			cleanup_old_backups(5)
			print("📦 Backup creato: " + backup_file)
		else:
			print("❌ Impossibile creare backup")

func cleanup_old_backups(max_backups: int):
	var dir = DirAccess.open(BACKUP_PATH)
	if not dir:
		return
	
	var files = []
	var error = dir.list_dir_begin()
	if error != OK:
		print("❌ Impossibile listare directory backup")
		return
	
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("backup_") and file_name.ends_with(".save"):
			var file_path = BACKUP_PATH + file_name
			if FileAccess.file_exists(file_path):
				var modified = FileAccess.get_modified_time(file_path)
				files.append({"path": file_path, "modified": modified})
		file_name = dir.get_next()
	
	# Ordina per data (più vecchi prima)
	files.sort_custom(func(a, b): return a.modified < b.modified)
	
	# Rimuovi i più vecchi se superiamo il limite
	if files.size() > max_backups:
		for i in range(files.size() - max_backups):
			var file_to_delete = files[i].path
			var remove_error = DirAccess.remove_absolute(file_to_delete)
			if remove_error == OK:
				print("🗑️ Backup rimosso: " + file_to_delete)
			else:
				print("❌ Impossibile rimuovere backup: " + file_to_delete)

func restore_from_backup(backup_path: String) -> bool:
	if not FileAccess.file_exists(backup_path):
		return false
	
	var backup_data = FileAccess.get_file_as_bytes(backup_path)
	var file = FileAccess.open(LOCAL_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_buffer(backup_data)
		file.close()
		print("🔧 Backup ripristinato: " + backup_path)
		return true
	else:
		print("❌ Impossibile ripristinare backup")
		return false

# ======================================
# RESET E UTILITY
# ======================================

func reset_temporary_values():
	# Resetta i valori temporanei che non devono essere salvati
	player_hp = player_max_hp
	player_stamina = player_max_stamina
	player_bullets = player_max_bullets
	player_dead = false
	player_immunity = false
	hurt = false
	wave = 1
	
	# Reset boss states
	boss_killed = false
	mother_right_canon_damaged = false
	mother_left_canon_damaged = false
	state = "PHASE1"
	
	# Reset mission states
	base_hurt = false
	base_wall_destroyed = false
	base_destroyed = 0
	assault_done = false

func reset_to_default():
	# Resetta tutto ai valori di default per un nuovo gioco
	starter = true
	bonus_taken = false
	in_tutorial = true
	story_line = 0
	
	# Player defaults
	player_max_hp = 100
	player_hp = 100
	player_hp_reg = 0
	player_max_stamina = 100
	player_stamina = 100
	chance_not_consum_stamina = 0.0
	stamina_regen_skill = false
	
	move_speed = 400.0
	dash_speed = 800.0
	dash_duration = 0.2
	dash_cooldown = 3.0
	
	player_max_bullets = 10
	player_bullets = 10
	player_damage = 1.0
	player_bullet_speed = 400
	player_max_bullet_speed = 400
	shoot_freeze = 0.1
	
	# Textures defaults
	texture_body = 1
	texture_wing = 1
	texture_prop = 1
	texture_canon = 0
	texture_pfp_icon = 1
	texture_pfp_bg = 1
	texture_pfp_cover = 1
	
	# Weapons defaults
	unlocked_weapons = {
		"common": ["SOLBREAKER"],
		"rare": [],
		"epic": [],
		"legendary": []
	}
	weapons_found = {
		"common": ["SOLBREAKER"],
		"rare": [],
		"epic": [],
		"legendary": []
	}
	equipped_weapon = {
		"name": "SOLBREAKER",
		"rarity": "common"
	}
	
	# Crafting defaults
	materials = {
		"VoidShard": 0,
		"MagmaShard": 0,
		"IceShard": 0,
		"LightShard": 0
	}
	
	# Locked items
	LOCKED_BODIES = [12, 13, 14, 15]
	LOCKED_PROPS = [12, 13, 14, 15]
	LOCKED_WINGS = [12, 13, 14, 15]
	
	# Settings defaults
	music_volume = 50.0
	effects_volume = 10.0
	master_volume = 100.0
	
	screenX = 1920
	screenY = 1080
	fullscreen = true
	vsync = true
	bloom_quality = 80.0
	particle_quality = 80.0
	
	# Map defaults
	radar_radius = 80
	radar_range = 500.0
	mapX = 96.0
	mapY = 554.0
	hp_show = true
	stm_show = true
	
	# Camera defaults
	shake_strength = 20.0
	smoothing_speed = 8.0
	lookahead_distance = 10.0
	lookahead_speed = 6.0
	shake_decay = 5.0
	
	# Color defaults (tutti a 1.0 o 0.0)
	body_red_factor = 1.0
	body_green_factor = 1.0
	body_blue_factor = 1.0
	body_saturation = 1.0
	body_brightness = 0.0
	body_contrast = 1.0
	body_hue_shift = 0.0
	body_gamma = 1.0
	
	wings_red_factor = 1.0
	wings_green_factor = 1.0
	wings_blue_factor = 1.0
	wings_saturation = 1.0
	wings_brightness = 0.0
	wings_contrast = 1.0
	wings_hue_shift = 0.0
	wings_gamma = 1.0
	
	prop_red_factor = 1.0
	prop_green_factor = 1.0
	prop_blue_factor = 1.0
	prop_saturation = 1.0
	prop_brightness = 0.0
	prop_contrast = 1.0
	prop_hue_shift = 0.0
	prop_gamma = 1.0
	
	canon_red_factor = 1.0
	canon_green_factor = 1.0
	canon_blue_factor = 1.0
	canon_saturation = 1.0
	canon_brightness = 0.0
	canon_contrast = 1.0
	canon_hue_shift = 0.0
	canon_gamma = 1.0
	
	# Reset valori temporanei
	reset_temporary_values()
	
	print("🔄 Gioco resettato ai valori di default")

# ======================================
# TIMERS E CALLBACKS
# ======================================

func setup_auto_save():
	autosave_timer = Timer.new()
	autosave_timer.wait_time = 60.0  # Salva ogni minuto
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave_timeout)

func setup_backup_timer():
	backup_timer = Timer.new()
	backup_timer.wait_time = 300.0  # Backup ogni 5 minuti
	backup_timer.one_shot = false
	backup_timer.autostart = true
	add_child(backup_timer)
	backup_timer.timeout.connect(_on_backup_timeout)

func _on_autosave_timeout():
	if Time.get_unix_time_from_system() - last_save_time > 30:  # Salva solo se passati 30 secondi dall'ultimo salvataggio
		save_game()

func _on_backup_timeout():
	create_backup()

# ======================================
# INIT E READY
# ======================================

func _ready() -> void:
	# Carica il gioco (solo locale)
	load_game()
	
	# Il reset giornaliero è gestito da TimeManager._ready() con call_deferred
	# per garantire che GlobalStats sia già inizializzato prima del check
		
	# Setup timer
	setup_auto_save()
	setup_backup_timer()
	
	# Aggiungi materiali di test (rimuovi in produzione)
	add_material("VoidShard", 10)
	add_material("MagmaShard", 10)
	add_material("IceShard", 10)
	add_material("LightShard", 10)
	
	sync_weapons_data_from_global_weapons()
	
	# Reset valori temporanei
	reset_temporary_values()
	
	print("🎮 Global.gd pronto!")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("⚠ Chiusura gioco rilevata, salvo dati...")
		save_game()
		get_tree().quit()

# ======================================
# UTILITY FUNCTIONS
# ======================================

func get_save_status() -> String:
	var status = "Salvataggio Locale: "
	status += "✅ ATTIVO"
	status += "\nUltimo salvataggio: "
	if last_save_time > 0:
		status += Time.get_datetime_string_from_unix_time(last_save_time)
	else:
		status += "Mai"
	return status

func force_save():
	print("💾 Salvataggio forzato...")
	return save_game()

func delete_save():
	# Elimina salvataggio locale
	if FileAccess.file_exists(LOCAL_SAVE_PATH):
		var error = DirAccess.remove_absolute(LOCAL_SAVE_PATH)
		if error == OK:
			print("🗑️ Salvataggio locale eliminato")
		else:
			print("❌ Impossibile eliminare salvataggio locale")
	
	# Elimina tutti i backup
	var dir = DirAccess.open(BACKUP_PATH)
	if dir:
		var list_error = dir.list_dir_begin()
		if list_error == OK:
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.begins_with("backup_") and file_name.ends_with(".save"):
					var remove_error = DirAccess.remove_absolute(BACKUP_PATH + file_name)
					if remove_error == OK:
						print("🗑️ Backup rimosso: " + file_name)
				file_name = dir.get_next()
	
	reset_to_default()
	print("🗑️ Tutti i salvataggi eliminati, gioco resettato")

func export_save_data() -> String:
	var data = collect_save_data()
	return JSON.stringify(data, "\t", false)

func import_save_data(json_string: String) -> bool:
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data = json.data
		if apply_save_data(data):
			save_game()
			print("✅ Salvataggio importato con successo")
			return true
		else:
			print("❌ Errore nell'applicare i dati importati")
			return false
	else:
		print("❌ JSON non valido: " + json.get_error_message())
		return false

# Funzione per test rapido del salvataggio
func quick_save_test():
	print("🧪 Test rapido salvataggio...")
	var original_gold = GlobalStats.gold
	GlobalStats.gold += 100
	
	if save_game():
		print("✅ Salvataggio test completato")
		# Ripristina valore
		GlobalStats.gold = original_gold
		save_game()
		return true
	else:
		print("❌ Salvataggio test fallito")
		return false
