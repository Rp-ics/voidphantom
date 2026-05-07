extends Control

var bgs = [
	"res://Gres/Assets/BGame/galaxy1.png",
	"res://Gres/Assets/BGame/galaxy2.png",
	"res://Gres/Assets/BGame/galaxy6.png",
	"res://Gres/Assets/BGame/galaxy7.png",
	"res://Gres/Assets/BGame/galaxy9.png",
	"res://Gres/Assets/BGame/galaxy10.png",
	"res://Gres/Assets/Background/bgstar_9.png",
	"res://Gres/Assets/Background/bgstar_10.png",
	"res://Gres/Assets/Background/bgstar_1.png",
]

var paralax = [
	"res://Gres/Assets/BGame/galaxy11.png",
	"res://Gres/Assets/BGame/galaxy12.png",
	"res://Gres/Assets/BGame/galaxy13.png",
	"res://Gres/Assets/BGame/galaxy14.png",
	"res://Gres/Assets/BGame/galaxy15.png",
]

# Struttura dati per le armi del negozio
var shop_weapons = {
	# ============================================
	# TIER S (le più forti) - VC molto alti
	# ============================================
	"gun1": {
		"weapon_name": "NULLBORN SOVEREIGN",
		"price_wave": 50,
		"price_coin": 2500,
		"price_mob_kills": 45000,
		"save_key": "vg1"
	},
	"gun2": {
		"weapon_name": "OBLIVION HERALD",
		"price_wave": 40,
		"price_coin": 1800,
		"price_mob_kills": 35000,
		"save_key": "vg2"
	},
	"gun3": {
		"weapon_name": "VOIDFATHER'S ECLIPSE",
		"price_wave": 65,
		"price_coin": 3000,
		"price_mob_kills": 100000,
		"save_key": "vg3"
	},

	# ============================================
	# TIER A (molto forti)
	# ============================================
	"gun15": {
		"weapon_name": "STORM CALLER",
		"price_wave": 60,
		"price_coin": 3000,
		"price_mob_kills": 65000,
		"save_key": "vg15"
	},
	"gun10": {
		"weapon_name": "CHRONO RIPPER",
		"price_wave": 40,
		"price_coin": 1500,
		"price_mob_kills": 45000,
		"save_key": "vg10"
	},

	# ============================================
	# TIER B (forti, situazionali)
	# ============================================
	"gun9": {
		"weapon_name": "PHANTOM ECHO",
		"price_wave": 45,
		"price_coin": 1200,
		"price_mob_kills": 55000,
		"save_key": "vg9"
	},
	"gun12": {
		"weapon_name": "ENTROPY CANNON",
		"price_wave": 36,
		"price_coin": 500,
		"price_mob_kills": 10000,
		"save_key": "vg12"
	},
	"gun14": {
		"weapon_name": "RIFT BLADE",
		"price_wave": 36,
		"price_coin": 550,
		"price_mob_kills": 15000,
		"save_key": "vg14"
	},
	"gun8": {
		"weapon_name": "GRAVITON PULSE",
		"price_wave": 45,
		"price_coin": 900,
		"price_mob_kills": 45000,
		"save_key": "vg8"
	},

	# ============================================
	# TIER C (solidi, ruolo specifico)
	# ============================================
	"gun4": {
		"weapon_name": "AEGIS STORM",
		"price_wave": 50,
		"price_coin": 1700,
		"price_mob_kills": 40000,
		"save_key": "vg4"
	},
	"gun5": {
		"weapon_name": "MIND FRACTURE",
		"price_wave": 55,
		"price_coin": 1700,
		"price_mob_kills": 40000,
		"save_key": "vg5"
	},
	"gun13": {
		"weapon_name": "NECRO PULSE",
		"price_wave": 75,
		"price_coin": 3600,
		"price_mob_kills": 88000,
		"save_key": "vg13"
	},
	"gun11": {
		"weapon_name": "SOUL LEECH",
		"price_wave": 75,
		"price_coin": 3600,
		"price_mob_kills": 90000,
		"save_key": "vg11"
	},

	# ============================================
	# TIER D (utility / nicchia)
	# ============================================
	"gun7": {
		"weapon_name": "PROXIMITY MINE",
		"price_wave": 45,
		"price_coin": 500,
		"price_mob_kills": 32000,
		"save_key": "vg7"
	},
	"gun6": {
		"weapon_name": "WALL CASTER",
		"price_wave": 24,
		"price_coin": 450,
		"price_mob_kills": 30000,
		"save_key": "vg6"
	},
	"gun16": {
		"weapon_name": "DIMENSIONAL SWAP",
		"price_wave": 35,
		"price_coin": 799,
		"price_mob_kills": 34000,
		"save_key": "vg16"
	}
}

var current_gun_key = ""
@onready var buy_button = $Manager/BuyGun

@onready var void_g_button1 = $Manager/Scroll/Weapons/W1/Button
@onready var void_g_button2 = $Manager/Scroll/Weapons/W2/Button
@onready var void_g_button3 = $Manager/Scroll/Weapons/W3/Button
@onready var void_g_button4 = $Manager/Scroll/Weapons/W4/Button
@onready var void_g_button5 = $Manager/Scroll/Weapons/W5/Button
@onready var void_g_button6 = $Manager/Scroll/Weapons/W6/Button
@onready var void_g_button7 = $Manager/Scroll/Weapons/W7/Button
@onready var void_g_button8 = $Manager/Scroll/Weapons/W8/Button
@onready var void_g_button9 = $Manager/Scroll/Weapons/W9/Button
@onready var void_g_button10 = $Manager/Scroll/Weapons/W10/Button
@onready var void_g_button11 = $Manager/Scroll/Weapons/W11/Button
@onready var void_g_button12 = $Manager/Scroll/Weapons/W12/Button
@onready var void_g_button13 = $Manager/Scroll/Weapons/W13/Button
@onready var void_g_button14 = $Manager/Scroll/Weapons/W14/Button

@onready var camera = $Camera

func _ready():
	$MaxOffset.value = Global.menu_max_offset
	$SmoothSpeed.value = Global.menu_smooth_speed
	$MaxOffset/Label.text = str("Max Offset: ", Global.menu_max_offset)
	$SmoothSpeed/Label.text = str("Smooth Speed: ", Global.menu_smooth_speed)
	
	void_g_button1.connect("pressed", func(): on_weapon_selected("gun1"))
	void_g_button2.connect("pressed", func(): on_weapon_selected("gun2"))
	#void_g_button3.connect("pressed", func(): on_weapon_selected("gun3")) # armi deprecati PER ADESSO (IN FASE DI SVILUPPO E TEST)
	void_g_button4.connect("pressed", func(): on_weapon_selected("gun4"))
	void_g_button5.connect("pressed", func(): on_weapon_selected("gun5"))
	void_g_button6.connect("pressed", func(): on_weapon_selected("gun6"))
	void_g_button7.connect("pressed", func(): on_weapon_selected("gun7"))
	void_g_button8.connect("pressed", func(): on_weapon_selected("gun8"))
	void_g_button9.connect("pressed", func(): on_weapon_selected("gun9"))
	void_g_button10.connect("pressed", func(): on_weapon_selected("gun10"))
	void_g_button11.connect("pressed", func(): on_weapon_selected("gun11"))
	void_g_button12.connect("pressed", func(): on_weapon_selected("gun12"))
	#void_g_button13.connect("pressed", func(): on_weapon_selected("gun13")) # armi deprecati PER ADESSO (IN FASE DI SVILUPPO E TEST)
	void_g_button14.connect("pressed", func(): on_weapon_selected("gun14"))
	
func _process(delta: float) -> void:
	$Manager/Value.text = str("[color=#fc0356][img=50]res://Gres/Assets/Icons/black_hole_bonus.png[/img] ", GlobalStats.void_coins, "[/color]")
	
	var screen_center = get_viewport_rect().size / 2
	var mouse_pos = get_global_mouse_position()
	var offset = (mouse_pos - screen_center)
	
	if offset.length() > Global.menu_max_offset:
		offset = offset.normalized() * Global.menu_max_offset
	
	camera.position = camera.position.move_toward(screen_center + offset, Global.menu_smooth_speed * delta)
	$Particles.position = mouse_pos

func _on_leave_animation_finished(anim_name: StringName) -> void:
	var what = NOTIFICATION_WM_CLOSE_REQUEST
	Global.notification(what)

func _on_smooth_speed_value_changed(value: float) -> void:
	Global.menu_smooth_speed = value
	$SmoothSpeed/Label.text = str("Smooth Speed: ", Global.menu_smooth_speed)

func _on_max_offset_value_changed(value: float) -> void:
	Global.menu_max_offset = value
	$MaxOffset/Label.text = str("Max Offset: ", Global.menu_max_offset)

func on_weapon_selected(gun_key: String) -> void:
	current_gun_key = gun_key
	var weapon_data = shop_weapons[gun_key]
	
	# Verifica se l'arma è già stata comprata
	if GlobalStats.void_weapons[weapon_data["save_key"]]:
		# Già posseduta → mostra OWNED e disabilita il pulsante
		$Manager/price.text = "[color=#2ecc71][img=75]res://Gres/Assets/UI/Buttons/check_2.png[/img][font_size=60]OWNED[/font_size][/color]"
		$Manager/BuyGun.disabled = true
		$Manager/BuyGun.modulate = Color(0.5, 0.5, 0.5, 0.5)  # opzionale, per grigiare
	else:
		# Non posseduta → mostra prezzo e abilita
		update_price_display(weapon_data)
		$Manager/BuyGun.disabled = false
		$Manager/BuyGun.modulate = Color.WHITE
	
	# Aggiorna info arma (invariato)
	update_weapon_info(weapon_data["weapon_name"])

func update_price_display(weapon_data: Dictionary) -> void:
	var price_text = str(
		"[color=#fc0356]", weapon_data["price_coin"], 
		"[img=20]res://Gres/Assets/Icons/black_hole_bonus.png[/img][/color] + ",
		"[color=red]", weapon_data["price_mob_kills"], 
		" Kills [/color]+ [color=#fc5a03]", weapon_data["price_wave"], 
		" Max Wave[/color]"
	)
	$Manager/price.text = price_text

func update_weapon_info(weapon_name: String) -> void:
	# Prendi i dati dell'arma dal GlobalWeapons
	var weapon_data = GlobalWeapons.weapons[weapon_name]["legendary"]
	
	# Costruisci la stringa info dinamicamente
	var info_text = build_weapon_info_text(weapon_name, weapon_data)
	$Manager/info.text = info_text

func build_weapon_info_text(weapon_name: String, data: Dictionary) -> String:
	# Colori tema
	var color_gold = "#d4af37"
	var color_purple = "#b87cff"
	var color_orange = "#ff6b35"
	var color_red = "#ff3860"
	var color_green = "#2ecc71"
	var color_green_light = "#a8e6cf"
	var color_active = "#e74c3c"
	var color_active_light = "#ff9999"
	var color_yellow = "#f1c40f"
	var color_white = "#f5f5f5"
	var color_gray = "#7f8c8d"
	
	var text = """
[center][color=%s]═════════════════════════════════[/color]
[color=%s]◤[/color] [color=%s]%s[/color] [color=%s]◢[/color]
[color=%s]═════════════════════════════════[/color]

[color=%s]✦ DAMAGE:[/color] [color=%s]%.1f[/color]
[color=%s]✦ FIRE RATE:[/color] [color=%s]%.2fs[/color]

[color=%s]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]
""" % [
		color_purple, color_gold, "#b87cff", weapon_name, color_gold,
		color_purple,
		color_orange, color_red, data["damage"],
		color_orange, color_red, data["fire_rate"],
		color_gray
	]
	
	# Aggiungi info base
	text += "[color=%s]%s[/color]\n\n" % [color_white, data["suffix"]]
	text += "[color=%s]%s[/color]\n\n" % [color_white, data["info"]]
	
	# Aggiungi parametri speciali se presenti
	if data.has("special_power"):
		var special = data["special_power"]
		if special.has("passive"):
			text += "[color=%s]✦ PASSIVE:[/color] [color=%s]%s[/color]\n" % [color_green, color_green_light, special["passive"]]
		if special.has("active"):
			text += "[color=%s]✦ ACTIVE:[/color] [color=%s]%s[/color]\n" % [color_active, color_active_light, special["active"]]
	
	# Aggiungi parametri specifici dell'arma se presenti
	text += format_specific_params(data)
	
	text += "[/center]"
	return text

func format_specific_params(data: Dictionary) -> String:
	var text = ""
	
	# Mappa dei parametri con le loro descrizioni
	var param_descriptions = {
		"shield_deflect_chance": "✦ SHIELD DEFLECT: %d%% chance to deflect enemy projectiles",
		"wall_chance": "✦ WALL CHANCE: %d%% chance to create void wall",
		"wall_duration": "✦ WALL DURATION: %.1f seconds",
		"wall_width": "✦ WALL WIDTH: %.0f pixels",
		"mine_trigger_radius": "✦ MINE TRIGGER RADIUS: %.0f pixels",
		"mine_explosion_radius": "✦ MINE EXPLOSION RADIUS: %.0f pixels",
		"magnet_pull_force": "✦ MAGNET PULL FORCE: %.0f",
		"magnet_tick_damage": "✦ MAGNET TICK DAMAGE: %.1f every %.1fs",
		"magnet_duration": "✦ MAGNET DURATION: %.1f seconds",
		"magnet_radius": "✦ MAGNET RADIUS: %.0f pixels",
		"echo_delay": "✦ ECHO DELAY: %.1f seconds",
		"echo_damage_mult": "✦ ECHO DAMAGE: %.0f%%",
		"echo_count": "✦ ECHO COUNT: %d phantoms",
		"slow_amount": "✦ SLOW AMOUNT: %.0f%% speed reduction",
		"slow_duration": "✦ SLOW DURATION: %.1f seconds",
		"leech_percent": "✦ LEECH: %.0f%% damage as HP",
		"min_range_bonus": "✦ MIN RANGE DAMAGE: %.0f%%",
		"max_range_bonus": "✦ MAX RANGE DAMAGE: %.0f%%",
		"revive_chance": "✦ REVIVE CHANCE: %d%%",
		"revive_duration": "✦ REVIVE DURATION: %.1f seconds",
	}
	
	# Controlla e formatta ogni parametro
	for param in param_descriptions:
		if data.has(param):
			var value = data[param]
			var description = param_descriptions[param]
			
			# Gestisci casi speciali come magnet_tick_damage che usa anche magnet_tick_rate
			if param == "magnet_tick_damage" and data.has("magnet_tick_rate"):
				text += "[color=#a8e6cf]" + description % [value, data["magnet_tick_rate"]] + "[/color]\n"
			else:
				text += "[color=#a8e6cf]" + description % value + "[/color]\n"
	
	return text

func _on_buy_gun_pressed() -> void:
	if current_gun_key == "":
		return
		
	var weapon_data = shop_weapons[current_gun_key]
	
	# Verifica requisiti
	if can_buy_weapon(weapon_data):
		purchase_weapon(weapon_data)
	else:
		show_purchase_error()

func can_buy_weapon(weapon_data: Dictionary) -> bool:
	return (
		!GlobalStats.void_weapons[weapon_data["save_key"]] and 
		GlobalStats.max_game_wave >= weapon_data["price_wave"] and 
		GlobalStats.void_coins >= weapon_data["price_coin"] and 
		GlobalStats.kill_mobs_total >= weapon_data["price_mob_kills"]
	)

func purchase_weapon(weapon_data: Dictionary) -> void:
	GlobalStats.void_coins -= weapon_data["price_coin"]
	GlobalStats.save_data_stats()
	
	GlobalStats.void_weapons[weapon_data["save_key"]] = true
	GlobalStats.add_owned_weapon(weapon_data["weapon_name"], "legendary")
	Global.unlock_weapon(weapon_data["weapon_name"], "legendary")
	
	$Purchased/anim.play("show")
	
	# Forza l'aggiornamento della UI con l'arma corrente
	on_weapon_selected(current_gun_key)
	
	match GlobalStats.void_weapons:
		"vg1": GlobalStats.achievements["God of NULLBORN"] = true
		"vg2": GlobalStats.achievements["God of OBLIVION"] = true
		#"vg3": GlobalStats.achievements[""] = true
		"vg4": GlobalStats.achievements["God of AEGIS"] = true
		"vg5": GlobalStats.achievements["God of MIND"] = true
		"vg6": GlobalStats.achievements["God if WALL"] = true
		"vg7": GlobalStats.achievements["God of PROXIMITY"] = true
		#"vg8": GlobalStats.achievements[""] = true
		#"vg9": GlobalStats.achievements[""] = true
		#"vg10": GlobalStats.achievements[""] = true
		#"vg11": GlobalStats.achievements[""] = true
		#"vg12": GlobalStats.achievements[""] = true
		#"vg13": GlobalStats.achievements[""] = true
		#"vg14": GlobalStats.achievements[""] = true
		#"vg15": GlobalStats.achievements[""] = true
		#"vg16": GlobalStats.achievements[""] = true
			
	
func show_purchase_error() -> void:
	$Error.play()
	GlobalTweens.color_flash($Manager/price, Color.RED, 0.3)
	$Manager/BuyGun.modulate = Color.RED
	await get_tree().create_timer(0.3).timeout
	$Manager/BuyGun.modulate = Color.WHITE

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/craft_edit_ui.tscn")
