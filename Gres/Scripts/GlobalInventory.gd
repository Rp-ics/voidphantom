# GlobalInventory.gd
extends Node

var weapons := []                # Armi temporanee (reset ogni run)
var boss_weapons := []           # Armi permanenti (sbloccate una volta per tutte)

func add_weapon(weapon_name: String, rarity: String):
	# Boss weapons (permanenti)
	if rarity == "legendary":
		for w in boss_weapons:
			if w.weapon_name == weapon_name:
				return # già sbloccata
		boss_weapons.append({"weapon_name": weapon_name, "rarity": rarity})
	else:
		# Armi normali (temporanee)
		for w in weapons:
			if w.weapon_name == weapon_name and w.rarity == rarity:
				return
		weapons.append({"weapon_name": weapon_name, "rarity": rarity})

func has_weapon(weapon_name: String, rarity: String) -> bool:
	if rarity == "legendary":
		for w in boss_weapons:
			if w.weapon_name == weapon_name:
				return true
	else:
		for w in weapons:
			if w.weapon_name == weapon_name and w.rarity == rarity:
				return true
	return false

func clear():
	weapons.clear()
	# Le boss_weapons restano — permanenti
