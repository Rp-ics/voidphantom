extends Node2D

signal weapon_equipped(weapon_name: String, rarity: String, weapon_data: Dictionary)

@export var default_weapon: String = "PVP_RAZOR"
@export var default_rarity: String = "common"

var current_weapon: Dictionary = {}
var current_rarity: String = ""
var shoot_timer: float = 0.0

@onready var bullet_scene: PackedScene = preload("res://Gres/Multiplayer/scene/bullets/mu_bullet.tscn")
@onready var owner_ref: Node = null

func _ready() -> void:
	owner_ref = get_parent()
	
	# In arena multiplayer carichiamo SEMPRE l'arma PvP equipaggiata.
	# Non controlliamo is_in_lobby perché la lobby Steam potrebbe già essere
	# stata lasciata (es. match vs bot) quando questo nodo viene instanziato.
	var pvp_weapon = GlobalStats.pvp_equipped_weapon
	if pvp_weapon != "" and GlobalStats.has_pvp_weapon(pvp_weapon) and GlobalWeapons.weapons.has(pvp_weapon):
		equip_weapon(pvp_weapon, "common")
		print("[Canon] Arma PvP equipaggiata: ", pvp_weapon)
	else:
		equip_weapon("PVP_RAZOR", "common")
		print("[Canon] Fallback su PVP_RAZOR")

func _process(delta: float) -> void:
	if not owner_ref or (not owner_ref.is_multiplayer_authority() and not owner_ref.bot_controlled):
		return

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

func _on_weapon_selected(weapon_name: String, rarity: String) -> void:
	equip_weapon(weapon_name, rarity)
	Global.equip_weapon(weapon_name, rarity)

func equip_weapon(weapon_name: String, rarity: String = "common") -> void:
	# EXCLUSIVE: OBEY_THE_FIST is offline only
	if weapon_name == "OBEY_THE_FIST" and GlobalSteamScript.is_in_lobby:
		push_warning("OBEY_THE_FIST is offline-only. Cannot equip in multiplayer.")
		return

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

	# Aggiorna Global e GlobalWeapons SOLO per il player locale.
	if owner_ref == null or owner_ref.is_multiplayer_authority():
		Global.equipped_weapon.name   = weapon_name
		Global.equipped_weapon.rarity = rarity
		GlobalWeapons.current_weapon  = current_weapon
		Global.shoot_freeze = current_weapon.get("fire_rate", 0.38)

	# Reset shoot_timer così la prima pallottola non è bloccata
	shoot_timer = 0.0

	# Aggiorna texture arma
	if has_node("CanonSprite") and current_weapon.has("texture"):
		var tex_path = current_weapon["texture"]
		if tex_path != "":
			$CanonSprite.texture = load(tex_path)

	emit_signal("weapon_equipped", weapon_name, current_rarity, current_weapon.duplicate(true))

func shoot(force: bool = false) -> void:
	if not force and not owner_ref.is_multiplayer_authority():
		return
	if shoot_timer > 0.0:
		return
	if current_weapon.is_empty():
		if has_node("../Audio/reload"):
			$"../Audio/reload".play()
		return

	var shoot_dir: Vector2
	if force:
		shoot_dir = Vector2.RIGHT.rotated(owner_ref.rotation)
	else:
		shoot_dir = (get_global_mouse_position() - global_position).normalized()

	if Global.bullets > 0:
		if randi() % 100 >= Global.bullets_cons_percent:
			Global.bullets = max(Global.bullets - current_weapon.get("bullet_consume", 1), 0)

	var muzzle = $Muzzle
	var spawn_pos = muzzle.global_position if muzzle else global_position + Vector2(20, 0).rotated(rotation)

	var weapon_data = current_weapon.duplicate(true)
	if owner_ref.has_buff("pvp_damage_boost"):
		var mult = owner_ref.get_buff_param("pvp_damage_boost", "mult", 1.0)
		weapon_data["damage"] = weapon_data.get("damage", 10.0) * mult
	if owner_ref.has_buff("pvp_speed_boost"):
		var mult = owner_ref.get_buff_param("pvp_speed_boost", "mult", 1.0)
		weapon_data["speed"] = weapon_data.get("speed", 300.0) * mult
	if owner_ref.has_meta("pvp_homing_mark"):
		weapon_data["homing_marked"] = true

	# Calcola fire_rate con eventuali modificatori e applica shoot_timer PRIMA dello spawn
	var fire_rate = current_weapon.get("fire_rate", 0.25)
	if owner_ref.has_buff("pvp_fire_rate_boost"):
		var mult = owner_ref.get_buff_param("pvp_fire_rate_boost", "mult", 1.0)
		fire_rate *= mult
	shoot_timer = fire_rate

	# Per i bot chiama locale (gli RPC non funzionano con peer ID negativi)
	if force:
		_spawn_bullet_local(owner_ref.get_multiplayer_authority(), spawn_pos, shoot_dir, weapon_data)
	else:
		_spawn_bullet.rpc(owner_ref.get_multiplayer_authority(), spawn_pos, shoot_dir, weapon_data)

func _spawn_bullet_local(shooter_id: int, spawn_pos: Vector2, direction: Vector2, weapon_data: Dictionary):
	var proj := bullet_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = spawn_pos
	proj.init_from_weapon(weapon_data, direction, null)
	proj.shooter_peer_id = shooter_id
	proj.set_multiplayer_authority(1)
	
	if not GlobalSteamScript.current_lobby_is_pve:
		if shooter_id == multiplayer.get_unique_id():
			proj.modulate = Color(1, 1, 1, 0.35)
		else:
			proj.modulate = Color(1.35, 1.35, 1.35, 1.0)

	if current_weapon.has("sound"):
		var sfx = AudioStreamPlayer.new()
		sfx.stream = load(current_weapon["sound"])
		get_tree().current_scene.add_child(sfx)
		sfx.pitch_scale = 1.0 if randi() % 100 < 50 else 0.9
		sfx.volume_db   = Global.effects_volume
		sfx.play()
		sfx.connect("finished", Callable(sfx, "queue_free"))

@rpc("reliable", "call_local")
func _spawn_bullet(shooter_id: int, spawn_pos: Vector2, direction: Vector2, weapon_data: Dictionary):
	var proj := bullet_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position  = spawn_pos
	proj.init_from_weapon(weapon_data, direction, null)
	proj.shooter_peer_id  = shooter_id
	proj.set_multiplayer_authority(1)
	
	if not GlobalSteamScript.current_lobby_is_pve:
		if shooter_id == multiplayer.get_unique_id():
			proj.modulate = Color(1, 1, 1, 0.35)
		else:
			proj.modulate = Color(1.35, 1.35, 1.35, 1.0)

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
