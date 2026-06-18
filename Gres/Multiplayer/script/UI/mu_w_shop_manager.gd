extends Node2D

@onready var w_button_1 = $Scroll/Weapons/W1/Button if has_node("Scroll/Weapons/W1/Button") else null
@onready var w_button_2 = $Scroll/Weapons/W2/Button if has_node("Scroll/Weapons/W2/Button") else null
@onready var w_button_3 = $Scroll/Weapons/W3/Button if has_node("Scroll/Weapons/W3/Button") else null
@onready var w_button_4 = $Scroll/Weapons/W4/Button if has_node("Scroll/Weapons/W4/Button") else null
@onready var w_button_5 = $Scroll/Weapons/W5/Button if has_node("Scroll/Weapons/W5/Button") else null
@onready var w_button_6 = $Scroll/Weapons/W6/Button if has_node("Scroll/Weapons/W6/Button") else null
@onready var w_button_7 = $Scroll/Weapons/W7/Button if has_node("Scroll/Weapons/W6/Button") else null
@onready var w_button_8 = $Scroll/Weapons/W8/Button if has_node("Scroll/Weapons/W6/Button") else null
@onready var w_button_9 = $Scroll/Weapons/W9/Button if has_node("Scroll/Weapons/W6/Button") else null
@onready var w_button_10 = $Scroll/Weapons/W10/Button if has_node("Scroll/Weapons/W6/Button") else null
@onready var action_btn = $BuyGun if has_node("BuyGun") else null

@onready var w_info = $info if has_node("info") else null
@onready var w_price_l = $price if has_node("price") else null
@onready var w_name_label = $WeaponName if has_node("WeaponName") else null
@onready var pvp_coins_label = $PVPCoins if has_node("PVPCoins") else null

# Lista delle armi PvP disponibili
var pvp_weapons = [
	"PVP_RAZOR",
	"PVP_BOLT",
	"PVP_SPLITTER",
	"PVP_BOUNCE",
	"PVP_PIERCE",
	"PVP_HOMING",
	"PVP_EXPLODE",
	"PVP_FREEZE",
	"PVP_MAGNET",
	"PVP_SHOTGUN",
]

var current_weapon_index = 0
var current_weapon_name = ""
var current_weapon_data = {}
var current_weapon_price = 0

# Mappa dei prezzi per ogni arma
var weapon_prices = {
	"PVP_RAZOR": 0,
	"PVP_BOLT": 150,
	"PVP_SPLITTER": 200,
	"PVP_BOUNCE": 265,
	"PVP_PIERCE": 342,
	"PVP_HOMING": 360,
	"PVP_EXPLODE": 450,
	"PVP_FREEZE": 500,
	"PVP_MAGNET": 620,
	"PVP_SHOTGUN": 750,
}

func _ready() -> void:
	# Verifica che i nodi esistano prima di usarli
	_check_nodes()
	
	# Connetti pulsanti armi
	if w_button_1: w_button_1.connect("pressed", _on_w_btn_pressed.bind(0))
	if w_button_2: w_button_2.connect("pressed", _on_w_btn_pressed.bind(1))
	if w_button_3: w_button_3.connect("pressed", _on_w_btn_pressed.bind(2))
	if w_button_4: w_button_4.connect("pressed", _on_w_btn_pressed.bind(3))
	if w_button_5: w_button_5.connect("pressed", _on_w_btn_pressed.bind(4))
	if w_button_6: w_button_6.connect("pressed", _on_w_btn_pressed.bind(5))
	if w_button_7: w_button_7.connect("pressed", _on_w_btn_pressed.bind(6))
	if w_button_8: w_button_8.connect("pressed", _on_w_btn_pressed.bind(7))
	if w_button_9: w_button_9.connect("pressed", _on_w_btn_pressed.bind(8))
	if w_button_10: w_button_10.connect("pressed", _on_w_btn_pressed.bind(9))
	
	# Connetti pulsante azione
	if action_btn: action_btn.connect("pressed", _on_action_pressed)
	
	# Aggiorna UI PvP coins
	_update_pvp_coins_display()
	
	# Carica la prima arma di default
	current_weapon_index = 0
	_load_weapon(current_weapon_index)

func _check_nodes() -> void:
	if not w_name_label:
		print("ERRORE: WeaponName node non trovato! Verifica il percorso.")
	if not w_info:
		print("ERRORE: info node non trovato! Verifica il percorso.")
	if not w_price_l:
		print("ERRORE: price node non trovato! Verifica il percorso.")
	if not action_btn:
		print("ERRORE: BuyGun node non trovato! Verifica il percorso.")

func _update_pvp_coins_display() -> void:
	if pvp_coins_label:
		pvp_coins_label.text = "[center][img=40]res://Gres/Assets/Icons/exotic.png[/img] [color=#fc0356]%d[/color][/center]" % GlobalStats.pvp_coin

func _load_weapon(index: int) -> void:
	if index < 0 or index >= pvp_weapons.size():
		return
	
	current_weapon_index = index
	current_weapon_name = pvp_weapons[index]
	
	# Cerca l'arma nel dizionario GlobalWeapons.weapons
	if GlobalWeapons.weapons.has(current_weapon_name):
		if GlobalWeapons.weapons[current_weapon_name].has("common"):
			current_weapon_data = GlobalWeapons.weapons[current_weapon_name]["common"]
		elif GlobalWeapons.weapons[current_weapon_name].has("legendary"):
			current_weapon_data = GlobalWeapons.weapons[current_weapon_name]["legendary"]
		else:
			var first_rarity = GlobalWeapons.weapons[current_weapon_name].keys()[0]
			current_weapon_data = GlobalWeapons.weapons[current_weapon_name][first_rarity]
	else:
		push_error("Arma non trovata: ", current_weapon_name)
		return
	
	current_weapon_price = weapon_prices.get(current_weapon_name, 0)
	
	# Aggiorna UI con l'arma selezionata
	_update_weapon_display()
	_update_action_button()

func _update_weapon_display() -> void:
	# Nome arma formattato
	var display_name = current_weapon_name.replace("PVP_", "").replace("_", " ")
	if w_name_label:
		w_name_label.text = "[center][color=#d4af37]%s[/color][/center]" % display_name
	
	# Info descrittiva dell'arma
	if w_info:
		w_info.bbcode_text = _get_weapon_info_text(current_weapon_name, current_weapon_data)
	
	# Prezzo/stato nel label price
	var is_owned = GlobalStats.has_pvp_weapon(current_weapon_name)
	var is_equipped = (GlobalStats.pvp_equipped_weapon == current_weapon_name)
	
	if w_price_l:
		if is_equipped:
			w_price_l.text = "[center][color=#2ecc71]✓ EQUIPPED[/color][/center]"
		elif is_owned:
			w_price_l.text = "[center][color=#f1c40f]★ OWNED[/color][/center]"
		elif current_weapon_price == 0:
			w_price_l.text = "[center][color=#2ecc71]FREE[/color][/center]"
		else:
			w_price_l.text = "[center][img=40]res://Gres/Assets/Icons/exotic.png[/img] [color=#fc0356]%d[/color][/center]" % current_weapon_price

func _update_action_button() -> void:
	if not action_btn:
		return
	
	var is_owned = GlobalStats.has_pvp_weapon(current_weapon_name)
	var is_equipped = (GlobalStats.pvp_equipped_weapon == current_weapon_name)
	
	if is_equipped:
		action_btn.text = "EQUIPPED"
		action_btn.disabled = true
	elif is_owned:
		action_btn.text = "EQUIP"
		action_btn.disabled = false
	else:
		action_btn.text = "BUY (%d)" % current_weapon_price
		action_btn.disabled = (GlobalStats.pvp_coin < current_weapon_price)

func _on_action_pressed() -> void:
	var is_owned = GlobalStats.has_pvp_weapon(current_weapon_name)
	var is_equipped = (GlobalStats.pvp_equipped_weapon == current_weapon_name)
	
	if is_equipped:
		return
	elif is_owned:
		# Equipaggia l'arma posseduta
		GlobalStats.equip_pvp_weapon(current_weapon_name)
		print("[PvP Shop] Equipaggiato: ", current_weapon_name)
	else:
		# Compra l'arma
		if GlobalStats.pvp_coin >= current_weapon_price:
			GlobalStats.pvp_coin -= current_weapon_price
			GlobalStats.add_pvp_weapon(current_weapon_name)
			GlobalStats.save_data_stats()
			print("[PvP Shop] Acquistato: ", current_weapon_name)
		else:
			print("[PvP Shop] Monete insufficienti! Hai %d, serve %d" % [GlobalStats.pvp_coin, current_weapon_price])
			return
	
	# Aggiorna tutta l'UI
	_update_pvp_coins_display()
	_update_weapon_display()
	_update_action_button()
	GlobalStats.save_data_stats()
	Global.save_game()

func _on_w_btn_pressed(index: int) -> void:
	# Questo pulsante serve solo per selezionare l'arma
	_load_weapon(index)

func _get_weapon_info_text(weapon_name: String, data: Dictionary) -> String:
	var color_gold = "#d4af37"
	var color_purple = "#b87cff"
	var color_orange = "#ff6b35"
	var color_red = "#ff3860"
	var color_white = "#f5f5f5"
	var color_gray = "#7f8c8d"
	
	var display_name = weapon_name.replace("PVP_", "").replace("_", " ")
	
	var text = """
[center][color=%s]═════════════════════════════════[/color]
[color=%s]◤[/color] [color=%s]%s[/color] [color=%s]◢[/color]
[color=%s]═════════════════════════════════[/color]

[color=%s]✦ DAMAGE:[/color] [color=%s]%.1f[/color]
[color=%s]✦ FIRE RATE:[/color] [color=%s]%.2fs[/color]

[color=%s]━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━[/color]
""" % [
		color_purple, color_gold, "#b87cff", display_name, color_gold,
		color_purple,
		color_orange, color_red, data.get("damage", 0),
		color_orange, color_red, data.get("fire_rate", 0),
		color_gray
	]
	
	# Suffix
	if data.has("suffix") and data["suffix"] != "":
		text += "[color=%s]%s[/color]\n\n" % [color_white, data["suffix"]]
	
	# Info descrittiva
	if data.has("info") and data["info"] != "":
		text += "[color=%s]%s[/color]\n" % [color_white, data["info"]]
	
	# Effetti speciali per alcune armi
	match weapon_name:
		"PVP_SPLITTER":
			text += "\n[color=#a8e6cf]✦ SPLITS INTO 2 BULLETS AFTER 400px[/color]\n"
		"PVP_BOUNCE":
			text += "\n[color=#a8e6cf]✦ BOUNCES OFF WALLS ONCE[/color]\n"
		"PVP_PIERCE":
			text += "\n[color=#a8e6cf]✦ PIERCES THROUGH FIRST TARGET[/color]\n"
		"PVP_HOMING":
			text += "\n[color=#a8e6cf]✦ BULLETS TRACK THE NEAREST OPPONENT[/color]\n"
		"PVP_EXPLODE":
			text += "\n[color=#a8e6cf]✦ DELAYED EXPLOSION ON HIT (120px RADIUS)[/color]\n"
		"PVP_FREEZE":
			text += "\n[color=#a8e6cf]✦ 25% CHANCE TO FREEZE TARGET FOR 1.2s[/color]\n"
		"PVP_MAGNET":
			text += "\n[color=#a8e6cf]✦ PULLS TARGET TOWARD YOU ON HIT[/color]\n"
		"PVP_SHOTGUN":
			text += "\n[color=#a8e6cf]✦ FIRES 5 PELLETS IN A SPREAD[/color]\n"
	
	text += "[/center]"
	return text
