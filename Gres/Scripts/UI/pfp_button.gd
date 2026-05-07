extends TextureRect

@export var pfp_index: int = 1

func _ready() -> void:
	if pfp_index == 15 and !Global.unque_achieve: $Equip.disabled = true
	if pfp_index == 9 and !GlobalStats.achievements['Frost-Bound Epoch']: $Equip.disabled = true
	if pfp_index == 1 and !GlobalStats.achievements['Arcane Ascendancy']: $Equip.disabled = true
	if pfp_index == 16 and !GlobalStats.achievements['Forge of the Shattered Moon']: $Equip.disabled = true
	if pfp_index == 19 and !Global.wrath_icons['easy']: $Equip.disabled = true
	if pfp_index == 20 and !Global.wrath_icons['normal']: $Equip.disabled = true
	if pfp_index == 21 and !Global.wrath_icons['hard']: $Equip.disabled = true
		
	var img = "res://Gres/Assets/Icons/pfp/pfp_%s.png" % pfp_index
	$icon.texture = load(img)


func _on_equip_pressed() -> void:
	Global.texture_pfp_icon = pfp_index
