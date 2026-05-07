extends Node

# ========================
# STATS PLAYER
# ========================
var autosave_timer : Timer
var gold := 0
var tablet := 0
var void_shard := 0
var magma_shard := 0
var ice_shard := 0
var light_shard := 0
var spins := 0
var total_gold_collected := 0
var max_wave := 0
var max_game_wave := 0
var skills_unlocked: int = 0 # how many skills are unlocked G
var skins_unlocked: int = 0 # how many skins are unloked G
var died_times: int = 0 # dead count G
var critical: = 0.0
var critical_damage: = 1.2
var critical_chest: = false
var critical_vampire: = false
# Damage
var player_damage_lvl: int = 0 # danni ricevuti in questo livello NG
var player_hit_lvl: int = 0 # danni inflitti in questo livello NG
var player_min_hp_lvl: int = 80 # hp minimo raggiunto nel livello NG
var total_hp_bossfight_lvl: int = 80 # hp durante bossfight NG
var player_damage_total: int = 0 # danni ricevuti totali G
var player_hit_total: int = 0 # danni inflitti totali G

# === GRAPH === #
var graphic = "normale"
var show_fps = false
# ========================
# === MISSIONS === #
var daily_missions: Array = []            # missioni attive oggi (lista dizionari)
var daily_mission_seed: int = 0           # seme per la generazione casuale
var daily_last_reset_date: String = ""    # "YYYY-MM-DD"
var special_coin_progress: int = 0        # missioni completate verso la moneta speciale (persiste)

# Valute aggiuntive
var void_coins: int = 0               # la moneta speciale accumulata (se non esiste già in GlobalStats)

# === SKILLS === #
# DAMAGE & DPS
var damage_percent: float = 0
var fire_rate_percent: float = 0
var crit_chance: float = 0
var projectile_speed_percent: float = 0
var boss_damage_percent: float = 0

var stars := 0

# MOBILITY / MOVIMENTO
var move_speed_percent: float = 0
var dash_distance_percent: float = 0
var acceleration_percent: float = 0
var dash_iframes: int = 0
var deceleration_control_percent: float = 0

# SOSTEGNO / DEFENSE
var hp_max_plus: int = 0
var hp_regen_per_10s: int = 0
var damage_reduction_percent: float = 0
var low_hp_shield: int = 0
var knockback_resistance_percent: float = 0

# ABILITIES / COOLDOWNS
var cooldown_percent: float = 0
var active_lockout_percent: float = 0
var ability_energy_regen_percent: float = 0
var ability_cross_reduction_sec: float = 0
var first_cast_damage_boost: float = 0

# CONTROL / AOE / STATUS
var aoe_percent: float = 0
var slow_on_hit_percent: float = 0
var status_duration_percent: float = 0
var ability_aoe_percent: float = 0
var disarm_chance_percent: float = 0

# ========================
var kill_mobs_lvl := 0 # NG
var kill_mini_boss_lvl := 0 # NG
var kill_mini_boss_total := 0 # G
var kill_mobs_total := 0 # G
var kill_boss_total := 0 # G

# ========================
# DAMAGE INFLITTO
# ========================
var damage_inf_mob_lvl: int = 0 # Danni inflitti per livello NG
var damage_inf_miniboss_lvl: int = 0 # Danni inflitti per livello NG
var damage_inf_boss_lvl: int = 0 # Danni inflitti per livello NG
var damage_inf_total_lvl: int = 0 # Danni inflitti per livello NG

var damage_inf_mob_total: int = 0 # G
var damage_inf_miniboss_total: int = 0 # G
var damage_inf_boss_total: int = 0 # G
var damage_inf_total: int = 0 # G

# ========================
# DAMAGE RICEVUTO
# ========================
var damage_rec_lvl: int = 0 # NG
var damage_rec_boss_lvl: int = 0 # NG
var damage_rec_miniboss_lvl: int = 0 # NG
var damage_rec_total: int = 0 # G

# ========================
# NUCLEAR
# ========================
var nuclear_kill_lvl: int = 0 # NG
var nuclear_kill_total: int = 0 # G
var nuclear_boss_dmg_lvl: int = 0 # NG
var nuclear_destroyed_lvl: int = 0 # NG
var nuclear_active: bool = false # NG

# ========================
# BULLETS & BONUS
# ========================
var bullets_shoot_lvl: int = 0 # NG
var bullets_shoot_total: int = 0 # G

var bonus_get_lvl: int = 0 # NG
var bonus_get_total: int = 0 # G

var total_powerups := 0
var powerups_lvl := 0
var weapon_collected_total := 0
var weapon_collected_lvl := 0
# ========================
# ABILITIES USED
# ========================
var skill_used_shield: bool = false # NG
var skill_used_time: bool = false # NG
var skill_used_spawn: bool = false # NG
var skill_used_drone: bool = false # NG

# ========================
# GAME STATE
# ========================
var boss_fight_active: bool = false # NG
var boss_fight_counter: int = 0 # G

var mob_damaged: bool = false # NG
var miniboss_damaged: bool = false # NG
var boss_damaged: bool = false # NG

# ========================
# TIME
# ========================
var play_minutes: int = 0 # G
var play_seconds: int = 0 # G
var play_hours: int = 0 # G
@onready var play_timer: Timer = Timer.new()

#-bonus lvl-#
var heal_bonus := 3 # G
var shield_bonus := 3 # G
var stamina_bonus := 3 # G
var speed_bonus := 3 # G
var time_slow_bonus := 3 # G
var freeze_bonus := 3 # G

var time_slow := false
var time_slow_time := 4.0

var drop_percent := 2.0 # G
var craft_drop := 5.0 # G
var d_g_drop_percent := 10.0 # G
var gold_moltipl := 2.0 # G
var respawn := 0.0
var huge_dmg := 0.0
var respawn_god := false
var double_gold_drop := false
# ========================
# SHIP LEVELS
# ========================
var body_lvl := 0
var wings_lvl := 0
var canon_lvl := 0
var prop_lvl := 0

# === CRAFT === #
var total_craft := 0

var owned_weapons := {}

var has_free_spin: bool = false
var free_spin_used_today: bool = false
var total_spin: int = 0
# ============================
# === ACHIEVEMENTS SYSTEM ====
# ============================

#G Achievement unlocked flags
var achievements := {
	"Test": true,
	# Tutorial #
	"Was Easy": false,                    #G
	# Survival / Resilience
	"Ascent of the Unbroken": false,      #G
	"Tempest Sovereign": false,           #G
	"Walker of the Abyss": false,         #G
	"Solar Tide Immortal": false,         #G
	"Final Breath Victory": false,        #G
	"Defile the Fate": false,             #G
	"Aegis of the Fallen Star": false,    #G
	"Wave-Master I": false,               #G

	# Combat / Slaughter
	"Void-King’s Triumph": false,         #G
	"Leviathan’s Hunger": false,          #G
	"Celestial Onslaught": false,         #G
	"Godslayer Marksman": false,          #G
	"Nuclear Oblivion": false,            #G
	"Frozen Catastrophe": false,          #G
	"Arcane Ascendancy": false,           #G
	"Galactic Destruction": false,        #G

	# Bullets / Barrage
	"Mirage of Million Shots": false,     #G
	"Abyssal Deadshot": false,            #G

	# Progression / Time
	"Phantom of the Twentieth Dawn": false,  #G
	"Frost-Bound Epoch": false,              #G

	# Collection
	"Harvest of Power": false,            #G
	"Astral Collector": false,            #G

	# Crafting
	"Forge of the Common Star": false,    #G
	"Forge of the Shattered Moon": false, #G
	"Forge of the Void-Titan": false,     #G

	# Skill Tree / Stars
	"Starborn Awakening": false,          #G
	"Cosmic Armory": false,               #G
	"Celestial Ascendancy": false,        #G
	"Stellar Omnipotence": false,         #G

	# Customization
	"Nebula-Forged Form": false,          #G

	# Special
	"Herald of the First Light": false,   #G
	
	# Unique
	"FIRST LIGHT PIONEER": false,
	
	# VOID 
	"God of NULLBORN": false,
	"God of OBLIVION": false,
	"God of MIND": false,
	"God of AEGIS": false,
	"God of PROXIMITY": false,
	"God if WALL": false,
}

var void_weapons := {
	"vg1": false, "vg2": false, "vg3": false, "vg4": false,
	"vg5": false, "vg6": false, "vg7": false, "vg8": false,
	"vg9": false, "vg10": false, "vg11": false, "vg12": false,
	"vg13": false, "vg14": false, "vg15": false, "vg16": false,
}

#G Achievement descriptions
var achievement_desc := {
	"Ascent of the Unbroken": "Survive 5 waves while taking less than 20 damage.",
	"Tempest Sovereign": "Eliminate 40 enemies without dropping below 60 HP.",
	"Walker of the Abyss": "Defeat a miniboss while taking under 10 damage.",
	"Solar Tide Immortal": "Survive 10 waves without being hit.",
	"Final Breath Victory": "Defeat a boss with less than 10 health.",
	"Defile the Fate": "Kill a first boss without taking damage.",
	"Aegis of the Fallen Star": "Beat any boss while staying under 30 HP.",

	"Void-King’s Triumph": "Reach wave 20.",
	"Leviathan’s Hunger": "Eliminate 30 enemies without being hit.",
	"Celestial Onslaught": "Kill 250 enemies in a single game.",
	"Godslayer Marksman": "Kill 1000 enemies in one game.",
	"Nuclear Oblivion": "Defeat 30 enemies with a nuclear bomb.",
	"Frozen Catastrophe": "Accumulate 50 enemies on the field.",
	"Arcane Ascendancy": "Defeat 4 bosses.",
	"Galactic Destruction": "Deal 1,000,000 total damage.",

	"Mirage of Million Shots": "Fire 1,000,000 bullets in one run.",
	"Abyssal Deadshot": "Shoot 10,000,000 bullets and kill 500 enemies and 50 minibosses.",

	"Phantom of the Twentieth Dawn": "Reach wave 20.",
	"Frost-Bound Epoch": "Play for a total of 168 hours.",

	"Harvest of Power": "Collect 25 power-ups in a single match.",
	"Astral Collector": "Collect 10 weapons.",

	"Forge of the Common Star": "Craft 10 Common weapons.",
	"Forge of the Shattered Moon": "Craft 10 Rare weapons.",
	"Forge of the Void-Titan": "Craft 10 Epic weapons.",

	"Starborn Awakening": "Unlock your first star.",
	"Cosmic Armory": "Unlock 4 different stars.",
	"Celestial Ascendancy": "Unlock 10 stars.",
	"Stellar Omnipotence": "Unlock every available star.",

	"Nebula-Forged Form": "Edit your ship.",
	"Herald of the First Light": "Reach wave 50, kill a miniboss without damage, and defeat 1500 enemies.",
	}


#================================================#
func add_owned_weapon(weapon_name: String, rarity: String) -> void:
	if not owned_weapons.has(rarity):
		owned_weapons[rarity] = []
	if weapon_name not in owned_weapons[rarity]:
		owned_weapons[rarity].append(weapon_name)

func has_weapon(weapon_name: String, rarity: String) -> bool:
	return owned_weapons.has(rarity) and weapon_name in owned_weapons[rarity]

func apply_passives_to_player():
	# RESET variabili
	damage_percent = 0
	fire_rate_percent = 0
	crit_chance = 0
	projectile_speed_percent = 0
	boss_damage_percent = 0

	move_speed_percent = 0
	dash_distance_percent = 0
	acceleration_percent = 0
	dash_iframes = 0
	deceleration_control_percent = 0

	hp_max_plus = 0
	hp_regen_per_10s = 0
	damage_reduction_percent = 0
	low_hp_shield = 0
	knockback_resistance_percent = 0

	cooldown_percent = 0
	active_lockout_percent = 0
	ability_energy_regen_percent = 0
	ability_cross_reduction_sec = 0
	first_cast_damage_boost = 0

	aoe_percent = 0
	slow_on_hit_percent = 0
	status_duration_percent = 0
	ability_aoe_percent = 0
	disarm_chance_percent = 0

	# Applica passive sbloccate
	for skill_id in GlobalSkills.unlocked_skills:
		var info = GlobalSkills._get_skill_info(skill_id)
		if info == null:
			continue
		if info.type != "passive":
			continue

		for key in info.effect.keys():
			self.set(key, self.get(key) + info.effect[key])

	# Applica bonus costellazioni completate
	for const_key in GlobalSkills.completed_constellations:
		var bonus = GlobalSkills.SKILLS[const_key].bonus
		for key in bonus.effect.keys():
			self.set(key, self.get(key) + bonus.effect[key])

func trigger_active(skill_id: String, player):
	var info = GlobalSkills._get_skill_info(skill_id)
	if info == null:
		return false
	if info.type != "active":
		return false

	var effect_name = info.effect

	if not player.has_method(effect_name):
		printerr("Player non ha metodo attivo: ", effect_name)
		return false

	player.call(effect_name)
	return true

var SAVE_PATH := "user://save_data.stats"

# === CLOUD === #
func save_player_data_cloud():
	var SAVE_PATH := "user://player_data.save"
	if not GlobalSteamScript.steam_run:
		return
	
	var save_data = {
		"gold": gold,
		"tablet": tablet,
		"total_craft": total_craft,
		"achievements": achievements,
		"void_shard": void_shard,
		"magma_shard": magma_shard,
		"ice_shard": ice_shard,
		"light_shard": light_shard,
		"spins": spins,
		"total_gold_collected": total_gold_collected,
		"skills_unlocked": skills_unlocked,
		"skins_unlocked": skins_unlocked,
		"died_times": died_times,
		"player_damage_total": player_damage_total,
		"player_hit_total": player_hit_total,
		"critical": critical,
		"critical_damage": critical_damage,
		"critical_chest": critical_chest,
		"critical_vampire": critical_vampire,
		"has_free_spin": has_free_spin,
		"free_spin_used_today": free_spin_used_today,
		"max_wave": max_wave,
		"max_game_wave": max_game_wave,
		#-kill-#
		"stars": stars,
		"kill_mobs_total": kill_mobs_total,
		"kill_boss_total": kill_boss_total,
		"kill_mini_boss_total": kill_mini_boss_total,
		"total_powerups": total_powerups,
		"damage_inf_mob_total": damage_inf_mob_total,
		"damage_inf_miniboss_total": damage_inf_miniboss_total,
		"damage_inf_boss_total": damage_inf_boss_total,
		"damage_inf_total": damage_inf_total,
		"damage_rec_total": damage_rec_total,
		"nuclear_kill_total": nuclear_kill_total,
		"bullets_shoot_total": bullets_shoot_total,
		"bonus_get_total": bonus_get_total,
		"boss_fight_counter": boss_fight_counter,
		"play_minutes": play_minutes,
		"play_seconds": play_seconds,
		"play_hours": play_hours,
		
		"heal_bonus": heal_bonus,
		"shield_bonus": shield_bonus,
		"stamina_bonus": stamina_bonus,
		"speed_bonus": speed_bonus,
		"time_slow_bonus": time_slow_bonus,
		"freeze_bonus": freeze_bonus,
		"weapon_collected_total": weapon_collected_total,
		"drop_percent": drop_percent,
		"craft_drop": craft_drop,
		"double_gold_drop": double_gold_drop,
		"d_g_drop_percent": d_g_drop_percent,
		"gold_moltipl": gold_moltipl,
		"respawn": respawn,
		"huge_dmg": huge_dmg,
		"respawn_god": respawn_god,
		
		"body_lvl": body_lvl,
		"wings_lvl": wings_lvl,
		"canon_lvl": canon_lvl,
		"prop_lvl": prop_lvl,
		"owned_weapons": owned_weapons,
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_player_data_cloud():
	var SAVE_PATH := "user://player_data.save"

	if not FileAccess.file_exists(SAVE_PATH):
		print("No save found in Cloud (user://)")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("Failed to open save")
		return

	var save_data = file.get_var()
	file.close()
	
	# Carica i dati con fallback
	gold = save_data.get("gold", gold)
	tablet = save_data.get("tablet", tablet)
	total_craft = save_data.get("total_craft", total_craft)
	achievements = save_data.get("achievements", achievements)
	void_shard = save_data.get("void_shard", void_shard)
	magma_shard = save_data.get("magma_shard", magma_shard)
	ice_shard = save_data.get("ice_shard", ice_shard)
	light_shard = save_data.get("light_shard", light_shard)
	spins = save_data.get("spins", spins)
	stars = save_data.get("stars", stars)
	total_gold_collected = save_data.get("total_gold_collected", total_gold_collected)
	skills_unlocked = save_data.get("skills_unlocked", skills_unlocked)
	skins_unlocked = save_data.get("skins_unlocked", skins_unlocked)
	died_times = save_data.get("died_times", died_times)
	player_damage_total = save_data.get("player_damage_total", player_damage_total)
	player_hit_total = save_data.get("player_hit_total", player_hit_total)
	critical = save_data.get("critical", critical)
	critical_damage = save_data.get("critical_damage", critical_damage)
	critical_chest = save_data.get("critical_chest", critical_chest)
	critical_vampire = save_data.get("critical_vampire", critical_vampire)
	has_free_spin = save_data.get("has_free_spin", has_free_spin)
	free_spin_used_today = save_data.get("free_spin_used_today", free_spin_used_today)
	max_wave = save_data.get("max_wave", max_wave)
	max_game_wave = save_data.get("max_game_wave", max_game_wave)
	
	#-kill-#
	kill_mobs_total = save_data.get("kill_mobs_total", kill_mobs_total)
	kill_boss_total = save_data.get("kill_boss_total", kill_boss_total)
	kill_mini_boss_total = save_data.get("kill_mini_boss_total", kill_mini_boss_total)
	total_powerups = save_data.get("total_powerups", total_powerups)
	damage_inf_mob_total = save_data.get("damage_inf_mob_total", damage_inf_mob_total)
	damage_inf_miniboss_total = save_data.get("damage_inf_miniboss_total", damage_inf_miniboss_total)
	damage_inf_boss_total = save_data.get("damage_inf_boss_total", damage_inf_boss_total)
	damage_inf_total = save_data.get("damage_inf_total", damage_inf_total)
	damage_rec_total = save_data.get("damage_rec_total", damage_rec_total)
	nuclear_kill_total = save_data.get("nuclear_kill_total", nuclear_kill_total)
	bullets_shoot_total = save_data.get("bullets_shoot_total", bullets_shoot_total)
	bonus_get_total = save_data.get("bonus_get_total", bonus_get_total)
	boss_fight_counter = save_data.get("boss_fight_counter", boss_fight_counter)
	play_minutes = save_data.get("play_minutes", play_minutes)
	play_seconds = save_data.get("play_seconds", play_seconds)
	play_hours = save_data.get("play_hours", play_hours)
	
	#-bonus drop lvl-#
	heal_bonus = save_data.get("heal_bonus", heal_bonus)
	shield_bonus = save_data.get("shield_bonus", shield_bonus)
	stamina_bonus = save_data.get("stamina_bonus", stamina_bonus)
	speed_bonus = save_data.get("speed_bonus", speed_bonus)
	time_slow_bonus = save_data.get("time_slow_bonus", time_slow_bonus)
	freeze_bonus = save_data.get("freeze_bonus", freeze_bonus)
	
	drop_percent = save_data.get("drop_percent", drop_percent)
	weapon_collected_total = save_data.get("weapon_collected_total", weapon_collected_total)
	craft_drop = save_data.get("craft_drop", craft_drop)
	double_gold_drop = save_data.get("double_gold_drop", double_gold_drop)
	d_g_drop_percent = save_data.get("d_g_drop_percent", d_g_drop_percent)
	gold_moltipl = save_data.get("gold_moltipl", gold_moltipl)
	respawn = save_data.get("respawn", respawn)
	huge_dmg = save_data.get("huge_dmg", huge_dmg)
	respawn_god = save_data.get("respawn_god", respawn_god)
	
	body_lvl = save_data.get("body_lvl", body_lvl)
	wings_lvl = save_data.get("wings_lvl", wings_lvl)
	canon_lvl = save_data.get("canon_lvl", canon_lvl)
	prop_lvl = save_data.get("prop_lvl", prop_lvl)
	owned_weapons = save_data.get("owned_weapons", owned_weapons)

# --- Salvataggio dati ---
func save_data_stats():
	var save_data = {
		"gold": gold,
		"graphic": graphic,
		"show_fps": show_fps,
		"daily_missions": daily_missions,
		"daily_mission_seed": daily_mission_seed,
		"daily_last_reset_date": daily_last_reset_date,
		"special_coin_progress": special_coin_progress,
		"void_coins": void_coins,
		"tablet": tablet,
		"total_craft": total_craft,
		"achievements": achievements,
		"void_shard": void_shard,
		"magma_shard": magma_shard,
		"ice_shard": ice_shard,
		"light_shard": light_shard,
		"spins": spins,
		"total_gold_collected": total_gold_collected,
		"skills_unlocked": skills_unlocked,
		"skins_unlocked": skins_unlocked,
		"died_times": died_times,
		"player_damage_total": player_damage_total,
		"player_hit_total": player_hit_total,
		"critical": critical,
		"critical_damage": critical_damage,
		"critical_chest": critical_chest,
		"critical_vampire": critical_vampire,
		"has_free_spin": has_free_spin,
		"free_spin_used_today": free_spin_used_today,
		"void_weapons": void_weapons,
		#-kill-#
		"stars": stars,
		"kill_mobs_total": kill_mobs_total,
		"kill_boss_total": kill_boss_total,
		"kill_mini_boss_total": kill_mini_boss_total,
		"total_powerups": total_powerups,
		"damage_inf_mob_total": damage_inf_mob_total,
		"damage_inf_miniboss_total": damage_inf_miniboss_total,
		"damage_inf_boss_total": damage_inf_boss_total,
		"damage_inf_total": damage_inf_total,
		"damage_rec_total": damage_rec_total,
		"nuclear_kill_total": nuclear_kill_total,
		"bullets_shoot_total": bullets_shoot_total,
		"bonus_get_total": bonus_get_total,
		"boss_fight_counter": boss_fight_counter,
		"play_minutes": play_minutes,
		"play_seconds": play_seconds,
		"play_hours": play_hours,
		
		"heal_bonus": heal_bonus,
		"shield_bonus": shield_bonus,
		"stamina_bonus": stamina_bonus,
		"speed_bonus": speed_bonus,
		"time_slow_bonus": time_slow_bonus,
		"freeze_bonus": freeze_bonus,
		"weapon_collected_total": weapon_collected_total,
		"drop_percent": drop_percent,
		"craft_drop": craft_drop,
		"double_gold_drop": double_gold_drop,
		"d_g_drop_percent": d_g_drop_percent,
		"gold_moltipl": gold_moltipl,
		
		"body_lvl": body_lvl,
		"wings_lvl": wings_lvl,
		"canon_lvl": canon_lvl,
		"prop_lvl": prop_lvl,
		"owned_weapons": owned_weapons,
	}

	var file = FileAccess.open("user://save_data_stats.save", FileAccess.WRITE)
	if file:
		file.store_var(save_data)  # BINARIO
		file.close()

# --- Caricamento dati ---
func load_data_stats():
	if not FileAccess.file_exists("user://save_data_stats.save"):
		return

	var file = FileAccess.open("user://save_data_stats.save", FileAccess.READ)
	if not file:
		return

	var save_data = file.get_var()  # LEGGE BINARIO
	file.close()
	#---------------------------------------------------------------------------------------#
	# Carica i dati con fallback
	gold = save_data.get("gold", gold)
	graphic = save_data.get("graphic", graphic)
	show_fps = save_data.get("show_fps", show_fps)
	daily_missions = save_data.get("daily_missions", daily_missions)
	daily_mission_seed = save_data.get("daily_mission_seed", daily_mission_seed)
	daily_last_reset_date = save_data.get("daily_last_reset_date", daily_last_reset_date)
	special_coin_progress = save_data.get("special_coin_progress", special_coin_progress)
	void_coins = save_data.get("void_coins", void_coins)
	tablet = save_data.get("tablet", tablet)
	total_craft = save_data.get("total_craft", total_craft)
	achievements = save_data.get("achievements", achievements)
	void_shard = save_data.get("void_shard", void_shard)
	magma_shard = save_data.get("magma_shard", magma_shard)
	ice_shard = save_data.get("ice_shard", ice_shard)
	light_shard = save_data.get("light_shard", light_shard)
	spins = save_data.get("spins", spins)
	stars = save_data.get("stars", stars)
	total_gold_collected = save_data.get("total_gold_collected", total_gold_collected)
	skills_unlocked = save_data.get("skills_unlocked", skills_unlocked)
	skins_unlocked = save_data.get("skins_unlocked", skins_unlocked)
	died_times = save_data.get("died_times", died_times)
	player_damage_total = save_data.get("player_damage_total", player_damage_total)
	player_hit_total = save_data.get("player_hit_total", player_hit_total)
	critical = save_data.get("critical", critical)
	critical_damage = save_data.get("critical_damage", critical_damage)
	critical_chest = save_data.get("critical_chest", critical_chest)
	critical_vampire = save_data.get("critical_vampire", critical_vampire)
	has_free_spin = save_data.get("has_free_spin", has_free_spin)
	free_spin_used_today = save_data.get("free_spin_used_today", free_spin_used_today)
	void_weapons = save_data.get("void_weapons", void_weapons)
	
	#-kill-#
	kill_mobs_total = save_data.get("kill_mobs_total", kill_mobs_total)
	kill_boss_total = save_data.get("kill_boss_total", kill_boss_total)
	kill_mini_boss_total = save_data.get("kill_mini_boss_total", kill_mini_boss_total)
	total_powerups = save_data.get("total_powerups", total_powerups)
	damage_inf_mob_total = save_data.get("damage_inf_mob_total", damage_inf_mob_total)
	damage_inf_miniboss_total = save_data.get("damage_inf_miniboss_total", damage_inf_miniboss_total)
	damage_inf_boss_total = save_data.get("damage_inf_boss_total", damage_inf_boss_total)
	damage_inf_total = save_data.get("damage_inf_total", damage_inf_total)
	damage_rec_total = save_data.get("damage_rec_total", damage_rec_total)
	nuclear_kill_total = save_data.get("nuclear_kill_total", nuclear_kill_total)
	bullets_shoot_total = save_data.get("bullets_shoot_total", bullets_shoot_total)
	bonus_get_total = save_data.get("bonus_get_total", bonus_get_total)
	boss_fight_counter = save_data.get("boss_fight_counter", boss_fight_counter)
	play_minutes = save_data.get("play_minutes", play_minutes)
	play_seconds = save_data.get("play_seconds", play_seconds)
	play_hours = save_data.get("play_hours", play_hours)
	
	#-bonus drop lvl-#
	heal_bonus = save_data.get("heal_bonus", heal_bonus)
	shield_bonus = save_data.get("shield_bonus", shield_bonus)
	stamina_bonus = save_data.get("stamina_bonus", stamina_bonus)
	speed_bonus = save_data.get("speed_bonus", speed_bonus)
	time_slow_bonus = save_data.get("time_slow_bonus", time_slow_bonus)
	freeze_bonus = save_data.get("freeze_bonus", freeze_bonus)
	
	drop_percent = save_data.get("drop_percent", drop_percent)
	weapon_collected_total = save_data.get("weapon_collected_total", weapon_collected_total)
	craft_drop = save_data.get("craft_drop", craft_drop)
	double_gold_drop = save_data.get("double_gold_drop", double_gold_drop)
	d_g_drop_percent = save_data.get("d_g_drop_percent", d_g_drop_percent)
	gold_moltipl = save_data.get("gold_moltipl", gold_moltipl)
	
	body_lvl = save_data.get("body_lvl", body_lvl)
	wings_lvl = save_data.get("wings_lvl", wings_lvl)
	canon_lvl = save_data.get("canon_lvl", canon_lvl)
	prop_lvl = save_data.get("prop_lvl", prop_lvl)
	owned_weapons = save_data.get("owned_weapons", owned_weapons)

func _ready() -> void:
	autosave_timer = Timer.new()
	autosave_timer.wait_time = 2.0
	autosave_timer.one_shot = false
	add_child(autosave_timer)
	autosave_timer.timeout.connect(_on_autosave)
	autosave_timer.start()
	
	# Configura il timer
	play_timer.wait_time = 1.0
	play_timer.one_shot = false
	play_timer.autostart = true
	add_child(play_timer)
	play_timer.timeout.connect(_on_play_timer_timeout)

func _on_play_timer_timeout() -> void:
	play_seconds += 1
	if play_seconds >= 60:
		play_seconds = 0
		play_minutes += 1
	
	if play_minutes >= 60:
		play_minutes = 0
		play_hours += 1
		
func _on_autosave():
	return
	autosave_timer.start()
