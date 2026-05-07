extends Node

var autosave_timer: Timer
# -----------------------------
# COSTELLAZIONI COMPLETATE
# -----------------------------
var zodiac := {
	'aries': false, 'taurus': false,
	'gemini': false, 'cancer': false,
	'leo': false, 'virgo': false,
	'libra': false, 'scorpio': false,
	'sagitarius': false, 'copricorn': false,
	'aquarius': false, 'pisces': false
}

var zodiac_cards := {
	'aries': {"card_1": false, "card_2": false, "card_3": false},
	'taurus': {"card_1": false, "card_2": false, "card_3": false},
	'gemini': {"card_1": false, "card_2": false, "card_3": false},
	'cancer': {"card_1": false, "card_2": false, "card_3": false},
	'leo': {"card_1": false, "card_2": false, "card_3": false},
	'virgo': {"card_1": false, "card_2": false, "card_3": false},
	'libra': {"card_1": false, "card_2": false, "card_3": false},
	'scorpio': {"card_1": false, "card_2": false, "card_3": false},
	'sagitarius': {"card_1": false, "card_2": false, "card_3": false},
	'copricorn': {"card_1": false, "card_2": false, "card_3": false},
	'aquarius': {"card_1": false, "card_2": false, "card_3": false},
	'pisces': {"card_1": false, "card_2": false, "card_3": false}
}

# -----------------------------
# SKILL DELLE COSTELLAZIONI
# -----------------------------
var zodiac_skills = {
	"aries_1": { "crit": 2.0, "crit_dmg": 0.2, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Critical Hit [/color][color=#ff8400]+2%\n[color=#c4f9ff]Critical Damage [/color][color=#ff8400]+0.4[/color]"
	},
	"aries_2": { "crit": 10.0, "crit_dmg": 0.4, "tablet": 4, "gold": 4000,
		"text": "[color=#c4f9ff]Critical Hit [/color][color=#ff8400]+10%\n[color=#c4f9ff]Critical Damage [/color][color=#ff8400]+1.0[/color]\n[color=#a3afff]Chance of opening chest first hit[/color][color=#ff4d00] +50%[/color]"
	},
	"aries_3": { "crit": 2.0, "crit_dmg": 0.2, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Critical Hit [/color][color=#ff8400]+4%\n[color=#c4f9ff]Critical Damage [/color][color=#ff8400]+0.6[/color]"
	},
	"aries_4": { "crit": 2.0, "crit_dmg": 0.2, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Critical Hit [/color][color=#ff8400]+4%\n[color=#c4f9ff]Critical Damage [/color][color=#ff8400]+0.8[/color]"
	},
	# === TAURUS ==== #
	"taurus_1": { "player_max_hp": 2, "player_max_stamina": 4, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+2\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+4[/color]"
	},
	"taurus_2": { "player_max_hp": 2, "player_max_stamina": 4, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+2\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+4[/color]"
	},
	"taurus_3": { "player_max_hp": 10, "player_max_stamina": 10, "tablet": 4, "gold": 4000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+10\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+10[/color]\n[color=#a3afff]Chance of not consuming stamina[/color][color=#ff4d00] +2%[/color]"
	},
	"taurus_4": { "player_max_hp": 2, "player_max_stamina": 4, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+2\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+4[/color]"
	},
	"taurus_5": { "player_max_hp": 2, "player_max_stamina": 4, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+2\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+4[/color]"
	},
	"taurus_6": { "player_max_hp": 2, "player_max_stamina": 4, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+2\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+4[/color]"
	},
	"taurus_7": { "player_max_hp": 10, "player_max_stamina": 10, "tablet": 4, "gold": 4000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+10\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+10[/color]\n[color=#a3afff]Chance of not consuming stamina[/color][color=#ff4d00] +2%[/color]"
	},
	"taurus_8": { "player_max_hp": 2, "player_max_stamina": 4, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+2\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+4[/color]"
	},
	"taurus_9": { "player_max_hp": 4, "player_max_stamina": 4, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+4\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+4[/color]"
	},
	"taurus_10": { "player_max_hp": 10, "player_max_stamina": 12, "tablet": 4, "gold": 4000,
		"text": "[color=#c4f9ff]Max HP [/color][color=#ff8400]+12\n[color=#c4f9ff]Max Stamina [/color][color=#ff8400]+10[/color]\n[color=#a3afff]Chance of not consuming stamina[/color][color=#ff4d00] +2%[/color]"
	},
	# === GEMINI ==== #
	"gemini_1": { "bullet_consum": 0.5, "bullet_speed": 5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+0.5%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+5[/color]"
	},
	"gemini_2": { "bullet_consum": 0.5, "bullet_speed": 5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+0.5%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+5[/color]"
	},
	"gemini_3": { "bullet_consum": 1.0, "bullet_speed": 5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+0.5%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+5[/color]"
	},
	"gemini_4": { "bullet_consum": 0.5, "bullet_speed": 5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+0.5%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+5[/color]"
	},
	"gemini_5": { "bullet_consum": 1.0, "bullet_speed": 10, "tablet": 4, "gold": 4000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+1%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+10[/color]\n[color=#a3afff]Damage[/color][color=#ff4d00] +0.2%[/color]"
	},
	"gemini_6": { "bullet_consum": 0.5, "bullet_speed": 5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+0.5%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+5[/color]"
	},
	"gemini_7": { "bullet_consum": 1.0, "bullet_speed": 10, "tablet": 4, "gold": 4000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+1%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+10[/color]\n[color=#a3afff]Damage[/color][color=#ff4d00] +0.2%[/color]"
	},
	"gemini_8": { "bullet_consum": 0.5, "bullet_speed": 5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+0.5%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+5[/color]"
	},
	"gemini_9": { "bullet_consum": 0.5, "bullet_speed": 5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+0.5%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+5[/color]"
	},
	"gemini_10": { "bullet_consum": 0.5, "bullet_speed": 5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bullets Save [/color][color=#ff8400]+0.5%\n[color=#c4f9ff]Bullets Speed [/color][color=#ff8400]+5[/color]"
	},
	# === CANCER ==== #
	"cancer_1": { "b_drop": 2.0, "c_drop": 1, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bonus Drop Chance [/color][color=#ff8400]+2%\n[color=#c4f9ff]Shard Drop Chance [/color][color=#ff8400]+1%[/color]"
	},
	"cancer_2": { "b_drop": 2.0, "c_drop": 1, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bonus Drop Chance [/color][color=#ff8400]+2%\n[color=#c4f9ff]Shard Drop Chance [/color][color=#ff8400]+1%[/color]"
	},
	"cancer_3": { "b_drop": 10.0, "c_drop": 3, "tablet": 4, "gold": 4000,
		"text": "[color=#c4f9ff]Bonus Drop Chance [/color][color=#ff8400]+10%\n[color=#c4f9ff]Shard Drop Chance [/color][color=#ff8400]+3%[/color]\n[color=#a3afff]Add a chance to double the gold drop by[/color][color=#ff4d00] 10%[/color]"
	},
	"cancer_4": { "b_drop": 2.0, "c_drop": 1, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bonus Drop Chance [/color][color=#ff8400]+2%\n[color=#c4f9ff]Shard Drop Chance [/color][color=#ff8400]+1%[/color]"
	},
	"cancer_5": { "b_drop": 2.0, "c_drop": 1, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Bonus Drop Chance [/color][color=#ff8400]+2%\n[color=#c4f9ff]Shard Drop Chance [/color][color=#ff8400]+1%[/color]"
	},
	# === LEO ==== #
	"leo_1": { "respawn": 0.2, "huge_dmg": 0.5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Respawn chance [/color][color=#ff8400]+0.2%\n[/color][color=#c4f9ff]Drain 50% non-boss enemy HP [/color][color=#ff8400]+0.5%[/color]"
	},
	"leo_2": { "respawn": 0.2, "huge_dmg": 0.5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Respawn chance [/color][color=#ff8400]+0.2%\n[/color][color=#c4f9ff]Drain 50% non-boss enemy HP [/color][color=#ff8400]+0.5%[/color]"
	},
	"leo_3": { "respawn": 1.2, "huge_dmg": 3, "tablet": 4, "gold": 4000,
		"text": "[color=#c4f9ff]Respawn chance [/color][color=#ff8400]+0.6%\n[/color][color=#c4f9ff]Drain 50% non-boss enemy HP [/color][color=#ff8400]+1.5%[/color]\n[color=#a3afff]Now you can find Epic weapons in the chest[/color]"
	},
	"leo_4": { "respawn": 0.2, "huge_dmg": 0.5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Respawn chance [/color][color=#ff8400]+0.2%\n[/color][color=#c4f9ff]Drain 50% non-boss enemy HP [/color][color=#ff8400]+0.5%[/color]"
	},
	"leo_5": { "respawn": 0.2, "huge_dmg": 0.5, "tablet": 2, "gold": 2000,
		"text": "[color=#c4f9ff]Respawn chance [/color][color=#ff8400]+0.2%\n[/color][color=#c4f9ff]Drain 50% non-boss enemy HP [/color][color=#ff8400]+0.5%[/color]"
	},
}

# -----------------------------
# NUOVI DATI DA SALVARE
# -----------------------------
var zodiac_skill_data = {
	"aries_1": { "unlocked": false, "progress": 0 },
	"aries_2": { "unlocked": false, "progress": 0 },
	"aries_3": { "unlocked": false, "progress": 0 },
	"aries_4": { "unlocked": false, "progress": 0 },
	
	"taurus_1": { "unlocked": false, "progress": 0 },
	"taurus_2": { "unlocked": false, "progress": 0 },
	"taurus_3": { "unlocked": false, "progress": 0 },
	"taurus_4": { "unlocked": false, "progress": 0 },
	"taurus_5": { "unlocked": false, "progress": 0 },
	"taurus_6": { "unlocked": false, "progress": 0 },
	"taurus_7": { "unlocked": false, "progress": 0 },
	"taurus_8": { "unlocked": false, "progress": 0 },
	"taurus_9": { "unlocked": false, "progress": 0 },
	"taurus_10": { "unlocked": false, "progress": 0 },
	
	"gemini_1": { "unlocked": false, "progress": 0 },
	"gemini_2": { "unlocked": false, "progress": 0 },
	"gemini_3": { "unlocked": false, "progress": 0 },
	"gemini_4": { "unlocked": false, "progress": 0 },
	"gemini_5": { "unlocked": false, "progress": 0 },
	"gemini_6": { "unlocked": false, "progress": 0 },
	"gemini_7": { "unlocked": false, "progress": 0 },
	"gemini_8": { "unlocked": false, "progress": 0 },
	"gemini_9": { "unlocked": false, "progress": 0 },
	"gemini_10": { "unlocked": false, "progress": 0 },
	
	# === CANCER === #
	"cancer_1": { "unlocked": false, "progress": 0 },
	"cancer_2": { "unlocked": false, "progress": 0 },
	"cancer_3": { "unlocked": false, "progress": 0 },
	"cancer_4": { "unlocked": false, "progress": 0 },
	"cancer_5": { "unlocked": false, "progress": 0 },
	
	# === LEO === #
	"leo_1": { "unlocked": false, "progress": 0 },
	"leo_2": { "unlocked": false, "progress": 0 },
	"leo_3": { "unlocked": false, "progress": 0 },
	"leo_4": { "unlocked": false, "progress": 0 },
	"leo_5": { "unlocked": false, "progress": 0 },
}

var zodiac_skill_graph = {
	"aries_1": ["aries_2"],
	"aries_2": ["aries_3"],
	"aries_3": ["aries_4"],
	"aries_4": [],
	
	# === TAURUS === #
	"taurus_1": ["taurus_2"],
	"taurus_2": ["taurus_3"],
	"taurus_3": ["taurus_4"],
	"taurus_4": ["taurus_5", "taurus_8"],
	"taurus_5": ["taurus_6"],
	"taurus_6": ["taurus_7"],
	"taurus_7": [],
	"taurus_8": ["taurus_9"],
	"taurus_9": ["taurus_10"],
	"taurus_10": [],
	
	# === GEMINI === #
	"gemini_1": ["gemini_2"],
	"gemini_2": ["gemini_3", "gemini_6"],
	"gemini_3": ["gemini_4"],
	"gemini_4": ["gemini_5"],
	"gemini_5": [],
	"gemini_6": ["gemini_7"],
	"gemini_7": ["gemini_8", "gemini_9"],
	"gemini_8": [],
	"gemini_9": ["gemini_10"],
	"gemini_10": [],
	# === CANCER === #
	"cancer_1": ["cancer_2"],
	"cancer_2": ["cancer_3"],
	"cancer_3": ["cancer_4", "cancer_5"],
	"cancer_4": [],
	"cancer_5": [],
	# === LEO === #
	"leo_1": ["leo_2"],
	"leo_2": ["leo_3"],
	"leo_3": ["leo_4", "leo_5"],
	"leo_4": [],
	"leo_5": [],
}

var SAVE_PATH := "user://skills_data.save"

# === CLOUD === #
func save_player_data_cloud():
	var SAVE_PATH := "user://player_data.save"
	if not GlobalSteamScript.steam_run:
		return
	
	var data = {
		"zodiac": zodiac,
		"zodiac_skill_data": zodiac_skill_data,
		"zodiac_cards": zodiac_cards,
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
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

	var data = file.get_var()
	file.close()
	
	zodiac = data.get("zodiac", zodiac)
	zodiac_skill_data = data.get("zodiac_skill_data", zodiac_skill_data)
	zodiac_cards = data.get("zodiac_cards", zodiac_cards)

# ======================================================
# =============== SALVATAGGIO ==========================
# ======================================================
func save_all():
	var data = {
		"zodiac": zodiac,
		"zodiac_skill_data": zodiac_skill_data,
		"zodiac_cards": zodiac_cards,
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)
		file.close()
	
# ======================================================
# =============== CARICAMENTO ==========================
# ======================================================
func load_all():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	file.close()

	# --- CORRETTO ---
	zodiac = data.get("zodiac", zodiac)
	zodiac_skill_data = data.get("zodiac_skill_data", zodiac_skill_data)
	zodiac_cards = data.get("zodiac_cards", zodiac_cards)
