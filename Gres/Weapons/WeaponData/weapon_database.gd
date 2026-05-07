# Weapons/WeaponData/weapon_database.gd
const WEAPONS = {
	"common": [
		preload("res://Gres/Weapons/Common/scene/blaster_c1.tscn"),
	],
	"rare": [
		preload("res://Gres/Weapons/Common/scene/blaster_c1.tscn"),
	],
	"epic": [
		preload("res://Gres/Weapons/Common/scene/blaster_c1.tscn"),
	]
}

func get_random_weapon(rarity: String) -> PackedScene:
	if rarity in WEAPONS:
		return WEAPONS[rarity].pick_random()
	return null
