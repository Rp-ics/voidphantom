extends Node2D

@export var default_weapon: String = "SOLBREAKER"
@export var default_rarity: String = "common"

var current_weapon: Dictionary = {}
var current_rarity: String = ""
var shoot_timer: float = 0.0

@onready var bullet_scene: PackedScene = preload("res://Gres/Scenes/weapons/bullet/player_bullet.tscn")
@onready var owner_ref: Node = null

# Riferimento allo spawner dei proiettili (trovato nella scena arena)
var bullet_spawner: MultiplayerSpawner = null

func _ready() -> void:
	owner_ref = get_parent()

	# Cerca lo spawner dei proiettili nella scena corrente
	bullet_spawner = get_tree().get_first_node_in_group("bullet_spawner")
	if not bullet_spawner:
		print("[Canon] Attenzione: nessun bullet_spawner trovato. I proiettili non saranno replicati.")

	# Carica l'arma equipaggiata
	if Global.equipped_weapon and Global.equipped_weapon.name != "":
		equip_weapon(Global.equipped_weapon.name, Global.equipped_weapon.rarity)
	else:
		equip_weapon(default_weapon, default_rarity)

	Global.connect("weapon_equipped", Callable(self, "_on_global_weapon_equipped"))

func _process(delta: float) -> void:
	if Global.player_hp > 0:
		if shoot_timer > 0.0:
			shoot_timer -= delta
		
		if Input.is_action_just_pressed("reload"):
			if has_node("../Audio/reload"): 
				$"../Audio/reload".play()
			$ReloadT.wait_time = 0.1
			$ReloadT.start()

func _on_global_weapon_equipped(weapon_name: String, rarity: String) -> void:
	equip_weapon(weapon_name, rarity)

func connect_inventory_signals() -> void:
	for ui in get_tree().get_nodes_in_group("weapon_ui"):
		ui.connect("weapon_selected", Callable(self, "_on_weapon_selected"))

func _on_weapon_selected(weapon_name: String, rarity: String) -> void:
	equip_weapon(weapon_name, rarity)
	Global.equip_weapon(weapon_name, rarity)

func equip_weapon(weapon_name: String, rarity: String = "common") -> void:
	var w := _find_weapon(weapon_name, rarity)
	if w.is_empty():
		push_warning("Arma non trovata: %s [%s]. Fallback al primo disponibile." % [weapon_name, rarity])
		for k in GlobalWeapons.weapons.keys():
			current_weapon = GlobalWeapons.weapons[k].values()[0]
			current_rarity = GlobalWeapons.weapons[k].keys()[0]
			break
	else:
		current_weapon = w
		current_rarity = rarity

	Global.equipped_weapon.name = weapon_name
	Global.equipped_weapon.rarity = rarity
	GlobalWeapons.current_weapon = current_weapon

	if has_node("CanonSprite") and current_weapon.has("texture"):
		var tex_path = current_weapon["texture"]
		if tex_path != "":
			$CanonSprite.texture = load(tex_path)

# =========================
# SHOOT – VERSIONE MULTIPLAYER
# =========================
func shoot() -> void:
	# Solo il peer che possiede il player può sparare
	if not owner_ref.is_multiplayer_authority():
		return

	if shoot_timer > 0.0:
		return
	if current_weapon.is_empty():
		if has_node("../Audio/reload"):
			$"../Audio/reload".play()
		return

	var mouse_dir := (get_global_mouse_position() - global_position).normalized()

	# Controllo munizioni (se usi il sistema di munizioni)
	if Global.bullets > 0:
		if randi() % 100 >= Global.bullets_cons_percent:
			Global.bullets = max(Global.bullets - current_weapon.get("bullet_consume", 1), 0)

		# Spawn del proiettile tramite MultiplayerSpawner (replica su tutti i client)
		if bullet_spawner:
			bullet_spawner.spawn([owner_ref.get_multiplayer_authority(), mouse_dir, current_weapon])
		else:
			# Fallback locale (non replicato)
			var proj := bullet_scene.instantiate()
			get_tree().current_scene.add_child(proj)
			proj.global_position = $Muzzle.global_position
			proj.init_from_weapon(current_weapon, mouse_dir, owner_ref)

		# Effetti audio e cooldown
		if current_weapon.has("sound"):
			var sfx := AudioStreamPlayer.new()
			sfx.stream = load(current_weapon["sound"])
			get_tree().current_scene.add_child(sfx)
			sfx.pitch_scale = 1.0 if randi() % 100 < 50 else 0.9
			sfx.volume_db = Global.effects_volume
			sfx.play()
			sfx.connect("finished", Callable(sfx, "queue_free"))

		shoot_timer = float(current_weapon.get("fire_rate", 0.25))

func _find_weapon(name: String, rarity: String = "common") -> Dictionary:
	if GlobalWeapons.weapons.has(name):
		if GlobalWeapons.weapons[name].has(rarity):
			return GlobalWeapons.weapons[name][rarity]
		return GlobalWeapons.weapons[name].values()[0]
	for k in GlobalWeapons.weapons.keys():
		if k.to_lower() == name.to_lower():
			if GlobalWeapons.weapons[k].has(rarity):
				return GlobalWeapons.weapons[k][rarity]
			return GlobalWeapons.weapons[k].values()[0]
	return GlobalWeapons.weapons["SOLBREAKER"]["common"]

func _on_reload_t_timeout() -> void:
	Global.bullets += 1
	if Global.bullets < Global.max_bullets:
		$ReloadT.start()
	elif Global.bullets >= Global.max_bullets:
		Global.bullets = Global.max_bullets
