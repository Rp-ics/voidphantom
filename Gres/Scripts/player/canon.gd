extends Node2D

@export var default_weapon: String ="SOLBREAKER" # key esatta in GlobalWeapons.weapons
@export var default_rarity: String = "common" # rarità iniziale

var current_weapon: Dictionary = {}
var current_rarity: String = ""
var shoot_timer: float = 0.0

@onready var bullet_scene: PackedScene = preload("res://Gres/Scenes/weapons/bullet/player_bullet.tscn")
@onready var owner_ref: Node = null

func _ready() -> void:
	owner_ref = get_parent()

	# 🔥 Leggi l'arma salvata in Global
	if Global.equipped_weapon and Global.equipped_weapon.name != "":
		equip_weapon(Global.equipped_weapon.name, Global.equipped_weapon.rarity)
	else:
		equip_weapon(default_weapon, default_rarity)

	# Ascolta eventuali cambi di equip anche a runtime
	Global.connect("weapon_equipped", Callable(self, "_on_global_weapon_equipped"))

func _process(delta: float) -> void:
	if Global.player_hp > 0:
		if shoot_timer > 0.0:
			shoot_timer -= delta
		
		if Input.is_action_just_pressed("reload"):
			$ReloadT.wait_time = 0.1
			$ReloadT.start()

func _on_global_weapon_equipped(weapon_name: String, rarity: String) -> void:
	equip_weapon(weapon_name, rarity)

# === GESTIONE SEGNALI ===
func connect_inventory_signals() -> void:
	for ui in get_tree().get_nodes_in_group("weapon_ui"):
		ui.connect("weapon_selected", Callable(self, "_on_weapon_selected"))

func _on_weapon_selected(weapon_name: String, rarity: String) -> void:
	equip_weapon(weapon_name, rarity)
	Global.equip_weapon(weapon_name, rarity)


# =========================
# EQUIP WEAPON
# =========================
func equip_weapon(weapon_name: String, rarity: String = "common") -> void:
	# === TROVA L’ARMA IN MODO SICURO ===
	var w := _find_weapon(weapon_name, rarity)

	if w.is_empty():
		push_warning("Arma non trovata: %s [%s]. Fallback al primo disponibile." % [weapon_name, rarity])
		for k in GlobalWeapons.weapons.keys():
			current_weapon = GlobalWeapons.weapons[k].values()[0]  # prima rarità disponibile
			current_rarity = GlobalWeapons.weapons[k].keys()[0]
			break
	else:
		current_weapon = w
		current_rarity = rarity

	# === SALVA GLOBALMENTE PER PERSISTENZA ===
	Global.equipped_weapon.name = weapon_name
	Global.equipped_weapon.rarity = rarity
	GlobalWeapons.current_weapon = current_weapon

	# === AGGIORNA SPRITE DEL CANON ===
	if has_node("CanonSprite") and current_weapon.has("texture"):
		var tex_path = current_weapon["texture"]
		if tex_path != "":
			$CanonSprite.texture = load(tex_path)

	# === LOG DEBUG ===
	#rint("✅ Arma equipaggiata: %s [%s]" % [weapon_name, rarity])

# =========================
# SHOOT
# =========================
func shoot() -> void:
	if shoot_timer > 0.0:
		return
	if current_weapon.is_empty():
		$"../Audio/reload".play()
		return
	
	# Direzione verso il mouse
	var mouse_dir := (get_global_mouse_position() - global_position).normalized()
	
	if Global.bullets > 0:
		# Probabilità che il colpo NON consumi munizioni
		if randi() % 100 >= Global.bullets_cons_percent:
			Global.bullets = max(Global.bullets - GlobalWeapons.current_weapon['bullet_consume'], 0)

		# Istanzia bullet
		var proj := bullet_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = $Muzzle.global_position

		# Inizializza il proiettile con i dati dell’arma e rarità
		proj.init_from_weapon(current_weapon, mouse_dir, owner_ref)

		# ✅ Salva il danno dentro al proiettile (così ogni colpo ha il suo)
		var dmg_value = current_weapon.get("damage", 10.0)
		proj.set_meta("damage", dmg_value)

		# === DEBUG === #
		#print("Bullet fired with damage:", dmg_value)

		# Audio arma
		if current_weapon.has("sound"):
			var sfx := AudioStreamPlayer.new()
			sfx.stream = load(current_weapon["sound"])
			get_tree().current_scene.add_child(sfx)
			sfx.pitch_scale = 1.0 if randi() % 100 < 50 else 0.9
			sfx.volume_db = Global.effects_volume
			sfx.play()
			sfx.connect("finished", Callable(sfx, "queue_free"))
		
		# Cooldown
		shoot_timer = float(current_weapon.get("fire_rate", 0.25))

# =========================
# FIND WEAPON (con rarità)
# =========================
func _find_weapon(name: String, rarity: String = "common") -> Dictionary:
	# Controllo diretto
	if GlobalWeapons.weapons.has(name):
		if GlobalWeapons.weapons[name].has(rarity):
			return GlobalWeapons.weapons[name][rarity]
		# fallback alla prima rarità disponibile
		return GlobalWeapons.weapons[name].values()[0]

	# Case-insensitive
	for k in GlobalWeapons.weapons.keys():
		if k.to_lower() == name.to_lower():
			if GlobalWeapons.weapons[k].has(rarity):
				return GlobalWeapons.weapons[k][rarity]
			return GlobalWeapons.weapons[k].values()[0]
	
	# fallback globale: blaster common
	return GlobalWeapons.weapons["SOLBREAKER"]["common"]

func _on_reload_t_timeout() -> void:
	Global.bullets += 1
	if Global.bullets < Global.max_bullets:
		$ReloadT.start()
	elif Global.bullets >= Global.max_bullets:
		Global.bullets = Global.max_bullets
