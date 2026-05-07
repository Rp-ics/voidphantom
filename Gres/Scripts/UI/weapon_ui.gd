extends Control

signal weapon_selected(weapon_name, rarity)
signal weapon_hovered(weapon_name, rarity)

@export var weapon_name: String
@export var rarity: String = "common"

@onready var icon: TextureRect = $icon
@onready var button: Button = $GunButton

func _ready():
	update_icon()

func update_icon() -> void:
	if weapon_name == "":
		icon.texture = null
		return

	var weapon_data = GlobalWeapons.get_weapon(weapon_name, rarity)
	if weapon_data and weapon_data.has("texture"):
		icon.texture = load(weapon_data["texture"])
	else:
		icon.texture = null

func _on_Button_pressed() -> void:
	# ✅ Aggiorna Global e segnala l’equip
	Global.equip_weapon(weapon_name, rarity)
	emit_signal("weapon_selected", weapon_name, rarity)
	print("✅ Equip weapon:", weapon_name, "[%s]" % rarity)

func _on_Button_mouse_entered() -> void:
	emit_signal("weapon_hovered", weapon_name, rarity)
