extends GridContainer

var inventory: Array = []

func all():
	add_weapon("SOLBREAKER", "common")
	add_weapon("SOLBREAKER", "rare")
	add_weapon("SOLBREAKER", "epic")
	
	add_weapon("AEGIS TEMPEST", "common")
	add_weapon("AEGIS TEMPEST", "rare")
	add_weapon("AEGIS TEMPEST", "epic")
	
	add_weapon("HELLWING", "common")
	add_weapon("HELLWING", "rare")
	add_weapon("HELLWING", "epic")
	
	add_weapon("NEBULAR STORM", "common")
	add_weapon("NEBULAR STORM", "rare")
	add_weapon("NEBULAR STORM", "epic")
	
	add_weapon("VOIDLANCE", "common")
	add_weapon("VOIDLANCE", "rare")
	add_weapon("VOIDLANCE", "epic")
	
	add_weapon("ASTRIX REBOUND", "common")
	add_weapon("ASTRIX REBOUND", "rare")
	add_weapon("ASTRIX REBOUND", "epic")
	
	add_weapon("PHANTOM SEEKER", "common")
	add_weapon("PHANTOM SEEKER", "rare")
	add_weapon("PHANTOM SEEKER", "epic")
	
	add_weapon("OMNIVORE", "common")
	add_weapon("OMNIVORE", "rare")
	add_weapon("OMNIVORE", "epic")
	
	add_weapon("SUPERNOVA CORE", "common")
	add_weapon("SUPERNOVA CORE", "rare")
	add_weapon("SUPERNOVA CORE", "epic")
	
	add_weapon("ECLIPSE FRACTAL", "common")
	add_weapon("ECLIPSE FRACTAL", "rare")
	add_weapon("ECLIPSE FRACTAL", "epic")
	
	add_weapon("VOID REAVER", "common")
	add_weapon("VOID REAVER", "rare")
	add_weapon("VOID REAVER", "epic")
	
	# === CONSTELLATIONS === #
	add_weapon("VULRATH IGNIS-SUNDER", "legendary")
	add_weapon("GORHAL IRONBREAKER", "legendary")
	add_weapon("SHYREL DUAL-FATE", "legendary")
	add_weapon("ANONYMOUSE MAELKRITH", "legendary")
	
	# === BOSS === #
	add_weapon("GAEA CORE", "legendary")
	add_weapon("BLOOD_NEXUS", "legendary")
	
	# === VOID === #
	add_weapon("NULLBORN SOVEREIGN", "legendary")
	add_weapon("OBLIVION HERALD", "legendary")
	add_weapon("VOIDFATHER'S ECLIPSE", "legendary")
	add_weapon("AEGIS STORM", "legendary")
	add_weapon("MIND FRACTURE", "legendary")
	add_weapon("WALL CASTER", "legendary")
	add_weapon("PROXIMITY MINE", "legendary")
	add_weapon("GRAVITON PULSE", "legendary")
	add_weapon("PHANTOM ECHO", "legendary")
	add_weapon("CHRONO RIPPER", "legendary")
	add_weapon("SOUL LEECH", "legendary")
	add_weapon("ENTROPY CANNON", "legendary")
	add_weapon("NECRO PULSE", "legendary")
	add_weapon("RIFT BLADE", "legendary")
	add_weapon("STORM CALLER", "legendary")
	add_weapon("DIMENSIONAL SWAP", "legendary")
	
func commons():
	add_weapon("SOLBREAKER", "common")
	add_weapon("AEGIS TEMPEST", "common")
	add_weapon("HELLWING", "common")
	add_weapon("NEBULAR STORM", "common")
	add_weapon("VOIDLANCE", "common")
	add_weapon("ASTRIX REBOUND", "common")
	add_weapon("PHANTOM SEEKER", "common")
	add_weapon("OMNIVORE", "common")
	add_weapon("SUPERNOVA CORE", "common")
	add_weapon("ECLIPSE FRACTAL", "common")
	add_weapon("VOID REAVER", "common")

func rares():
	add_weapon("SOLBREAKER", "rare")
	add_weapon("AEGIS TEMPEST", "rare")
	add_weapon("HELLWING", "rare")
	add_weapon("NEBULAR STORM", "rare")
	add_weapon("VOIDLANCE", "rare")
	add_weapon("ASTRIX REBOUND", "rare")
	add_weapon("PHANTOM SEEKER", "rare")
	add_weapon("OMNIVORE", "rare")
	add_weapon("SUPERNOVA CORE", "rare")
	add_weapon("ECLIPSE FRACTAL", "rare")
	add_weapon("VOID REAVER", "rare")

func epics():
	add_weapon("SOLBREAKER", "epic")
	add_weapon("AEGIS TEMPEST", "epic")
	add_weapon("HELLWING", "epic")
	add_weapon("NEBULAR STORM", "epic")
	add_weapon("VOIDLANCE", "epic")
	add_weapon("ASTRIX REBOUND", "epic")
	add_weapon("PHANTOM SEEKER", "epic")
	add_weapon("OMNIVORE", "epic")
	add_weapon("SUPERNOVA CORE", "epic")
	add_weapon("ECLIPSE FRACTAL", "epic")
	add_weapon("VOID REAVER", "epic")

func bosses():
	add_weapon("GAEA CORE", "legendary")
	add_weapon("BLOOD_NEXUS", "legendary")

func constel():
	add_weapon("VULRATH IGNIS-SUNDER", "legendary")
	add_weapon("GORHAL IRONBREAKER", "legendary")
	add_weapon("SHYREL DUAL-FATE", "legendary")
	add_weapon("ANONYMOUSE MAELKRITH", "legendary")

func voids():
	add_weapon("NULLBORN SOVEREIGN", "legendary")
	add_weapon("OBLIVION HERALD", "legendary")
	add_weapon("VOIDFATHER'S ECLIPSE", "legendary")
	add_weapon("AEGIS STORM", "legendary")
	add_weapon("MIND FRACTURE", "legendary")
	add_weapon("WALL CASTER", "legendary")
	add_weapon("PROXIMITY MINE", "legendary")
	add_weapon("GRAVITON PULSE", "legendary")
	add_weapon("PHANTOM ECHO", "legendary")
	add_weapon("CHRONO RIPPER", "legendary")
	add_weapon("SOUL LEECH", "legendary")
	add_weapon("ENTROPY CANNON", "legendary")
	add_weapon("NECRO PULSE", "legendary")
	add_weapon("RIFT BLADE", "legendary")
	add_weapon("STORM CALLER", "legendary")
	add_weapon("DIMENSIONAL SWAP", "legendary")

# =========================
# RARITY COLORS
# =========================
func _get_rarity_color(rarity: String) -> String:
	match rarity:
		"common":    return "#aaaaaa"
		"rare":      return "#0099ff"
		"epic":      return "#aa00ff"
		"legendary": return "#ff9900"
	return "#ffffff"

func _get_rarity_label(rarity: String) -> String:
	match rarity:
		"common":    return "◆ COMMON"
		"rare":      return "◆◆ RARE"
		"epic":      return "◆◆◆ EPIC"
		"legendary": return "★ LEGENDARY"
	return rarity.to_upper()

# =========================
# FILTER
# =========================
func filter_inventory(rarity_filter: String) -> void:
	for weapon_ui in inventory:
		if rarity_filter == "all":
			weapon_ui.visible = true
		else:
			weapon_ui.visible = weapon_ui.rarity == rarity_filter

func _on_filter_toggled(pressed: bool, button_name: String) -> void:
	if button_name == "All" and pressed:
		$"../../Common".button_pressed = false
		$"../../Rare".button_pressed = false
		$"../../Epic".button_pressed = false
		$"../../Legendary".button_pressed = false
		filter_inventory("all")
		return

	if button_name != "All" and pressed:
		$"../../All".button_pressed = false

	var active_filters = []
	if $"../../Common".button_pressed:    active_filters.append("common")
	if $"../../Rare".button_pressed:      active_filters.append("rare")
	if $"../../Epic".button_pressed:      active_filters.append("epic")
	if $"../../Legendary".button_pressed: active_filters.append("legendary")

	if active_filters.size() == 0:
		$"../../All".button_pressed = true
		filter_inventory("all")
		return

	for weapon_ui in inventory:
		weapon_ui.visible = weapon_ui.rarity in active_filters

# =========================
# READY
# =========================
func _ready():
	$"../../All".toggled.connect(Callable(self, "_on_filter_toggled").bind("All"))
	$"../../Common".toggled.connect(Callable(self, "_on_filter_toggled").bind("Common"))
	$"../../Rare".toggled.connect(Callable(self, "_on_filter_toggled").bind("Rare"))
	$"../../Epic".toggled.connect(Callable(self, "_on_filter_toggled").bind("Epic"))
	$"../../Legendary".toggled.connect(Callable(self, "_on_filter_toggled").bind("Legendary"))
	
	GlobalWeapons.connect("gun_found", Callable(self, "_on_global_weapon_found"))
	_load_inventory()
	await get_tree().create_timer(0.1).timeout
	add_weapon("SOLBREAKER", "common")
	if Global.in_tutorial: all()
	_fix_scroll()
	
func _fix_scroll():
	await get_tree().process_frame
	queue_sort()

# =========================
# INVENTORY LOAD
# =========================
func _load_inventory():
	for child in get_children():
		child.queue_free()
	inventory.clear()

	for w in GlobalInventory.weapons:
		add_weapon(w.weapon_name, w.rarity)

	for rarity in Global.unlocked_weapons.keys():
		for weapon_name in Global.unlocked_weapons[rarity]:
			add_weapon(weapon_name, rarity)

func _on_global_weapon_found(weapon_name: String, rarity: String) -> void:
	add_weapon(weapon_name, rarity)
	GlobalInventory.add_weapon(weapon_name, rarity)
	if rarity == "legendary":
		Global.unlock_weapon(weapon_name, rarity)

# =========================
# ADD WEAPON TO UI
# =========================
func add_weapon(weapon_name: String, rarity: String = "common") -> void:
	for slot in inventory:
		if slot.weapon_name == weapon_name and slot.rarity == rarity:
			return

	var weapon_ui_scene = preload("res://Gres/Scenes/UI/WeaponUI.tscn")
	var weapon_ui = weapon_ui_scene.instantiate()

	weapon_ui.weapon_name = weapon_name
	weapon_ui.rarity = rarity

	weapon_ui.weapon_hovered.connect(_on_weapon_hovered)
	weapon_ui.weapon_selected.connect(_on_weapon_selected)

	add_child(weapon_ui)
	inventory.append(weapon_ui)

# =========================
# HOVER — INFO PANEL COMPLETO
# =========================
func _on_weapon_hovered(weapon_name: String, rarity: String) -> void:
	var data = GlobalWeapons.get_weapon(weapon_name, rarity)
	if not data:
		GlobalWeapons.gun_info = ""
		return

	var suffix       : String = data.get("suffix", "")
	var damage       : float  = data.get("damage", 0.0)
	var fire_rate    : float  = data.get("fire_rate", 0.0)
	var speed        : float  = data.get("speed", 0.0)
	var proj_type    : String = data.get("projectile_type", "?")
	var bullet_cons  : int    = data.get("bullet_consume", 1)
	var description  : String = data.get("info", "")
	var special      : Dictionary = data.get("special_power", {})

	var rc : String = _get_rarity_color(rarity)
	var rl : String = _get_rarity_label(rarity)

	# ── HEADER ──────────────────────────────────────────────
	var out := ""

	# Nome arma
	out += "[center][font_size=60][color='%s']%s[/color][/font_size][/center]\n" % [rc, weapon_name]

	# Suffix / sottotitolo
	if suffix != "":
		out += "[center][font_size=80][color='#03ecfc'][i]%s[/i][/color][/font_size][/center]\n" % suffix

	# Rarity badge
	out += "[center][color='%s']%s[/color][/center]\n" % [rc, rl]

	out += "\n"

	# ── STATS ───────────────────────────────────────────────
	out += "[color='#555555'][center]━━━━━━━━━━━━━━━━━━━━[/center][/color]\n"
	out += "STATS\n"

	# Damage — arrotondato e leggibile
	var dmg_display := "%.0f" % damage
	out += "  [color='#888888']Damage[/color]       [color='#ff4444']%s[/color]\n" % dmg_display

	# DPS approssimativo (damage / fire_rate)
	if fire_rate > 0.0:
		var dps := damage / fire_rate
		out += "  [color='#888888']DPS (approx)[/color] [color='#ff6600']%.0f[/color]\n" % dps

	# Fire Rate — più basso = più veloce, mostriamolo chiaramente
	var fr_display := "%.2f s" % fire_rate
	var fr_label : String
	if fire_rate <= 0.20:
		fr_label = "[color='#00ff88']INSANE[/color]"
	elif fire_rate <= 0.30:
		fr_label = "[color='#88ff00']FAST[/color]"
	elif fire_rate <= 0.45:
		fr_label = "[color='#ffff00']MEDIUM[/color]"
	else:
		fr_label = "[color='#ff8800']SLOW[/color]"
	out += "  [color='#888888']Fire Rate[/color]    %s  %s\n" % [fr_display, fr_label]

	# Bullet consume
	if bullet_cons > 1:
		out += "  [color='#888888']Ammo / Shot[/color]  [color='#ff2200']%d[/color]  ⚠ Heavy consumption\n" % bullet_cons
	else:
		out += "  [color='#888888']Ammo / Shot[/color]  [color='#44ff44']%d[/color]\n" % bullet_cons

	# Bullet type — traduzione leggibile
	var type_label := _humanize_proj_type(proj_type)
	out += "  [color='#888888']Bullet Type[/color]  [color='#00ccff']%s[/color]\n" % type_label

	out += "[color='#555555'][center]━━━━━━━━━━━━━━━━━━━━[/center][/color]\n"

	# ── SPECIAL POWERS (solo legendary) ─────────────────────
	if special.size() > 0:
		out += "\n[color='%s']⚡ SPECIAL POWERS[/color]\n" % rc

		var passive_txt : String = special.get("passive", "")
		var active_txt  : String = special.get("active", "")

		if passive_txt != "":
			out += "\n[color='#aaffaa']PASSIVE[/color]\n"
			out += "[color='#cccccc']%s[/color]\n" % passive_txt

		if active_txt != "":
			out += "\n[color='#ffcc00']ACTIVE[/color]\n"
			out += "[color='#cccccc']%s[/color]\n" % active_txt

		out += "[color='#555555'][center]━━━━━━━━━━━━━━━━━━━━[/center][/color]\n"

	# ── DESCRIPTION / LORE ──────────────────────────────────
	if description != "":
		out += "\n[color='#999999'][font_size=50][i]%s[/i][/font_size][/color]\n" % description

	GlobalWeapons.gun_info = out

# Traduce il projectile_type in testo comprensibile per il player
func _humanize_proj_type(proj_type: String) -> String:
	match proj_type:
		"line":                    return "Single Shot"
		"cone_3":                  return "3-Way Spread"
		"cone_5":                  return "5-Way Spread"
		"homing":                  return "Homing"
		"tide_homing":             return "Tide Homing"
		"follow_stop":             return "Lunge & Stop"
		"bounce":                  return "Bouncing"
		"seismic_bounce":          return "Seismic Bounce"
		"boomerang":               return "Boomerang"
		"wave_split":              return "Wave Split"
		"explode_after":           return "Delayed Explosion"
		"ImplosionBurst":          return "Implosion Burst"
		"VoidRift":                return "Void Rift"
		"zigzag":                  return "Zigzag Chain"
		"chain_lightning":         return "Chain Lightning"
		"dual_beam":               return "Dual Beam"
		"piercing_burn":           return "Piercing + Burn Trail"
		"MeteorShower":            return "Meteor Shower"
		"Orbitals":                return "Orbital Blades"
		"DeadLine":                return "DeadLine Phoenix"
		"gaea_core_main":          return "Gaea Singularity"
		"blood_nexus_main":        return "Blood Nexus Link"
		"nullborn_sovereign_shot": return "Singularity Freeze"
		"oblivion_herald_shot":    return "Black Hole Vortex"
		"voidfather_eclipse_shot": return "Dimensional Collapse"
	return proj_type

# =========================
# SELECTION
# =========================
func _on_weapon_selected(weapon_name: String, rarity: String) -> void:
	$"../../EquippL".text = str("EQUIPPED: [color='yellow']", rarity, " [/color]", weapon_name)
	$"../../EquippL/show".call_deferred("play", "show")

	if Global.canon:
		Global.canon.equip_weapon(weapon_name, rarity)
	else:
		print("Canon non trovato in Global!")

# =========================
# RESET
# =========================
func reset_inventory():
	GlobalInventory.clear()
	_load_inventory()
