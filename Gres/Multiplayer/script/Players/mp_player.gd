extends CharacterBody2D

signal player_died
signal progression_weapon_changed(peer_id: int, weapon_name: String, weapon_index: int, weapon_count: int)

# ==============================================================
# MULTIPLAYER LAYER
# ==============================================================

var is_local_player: bool = false

var mp_synced_hp:      float  = 100.0
var mp_max_hp:         float  = 100.0
var mp_max_stamina:    float  = 100.0
var mp_stamina:        float  = 100.0
var mp_peer_id:        int    = 1
var mp_player_name:    String = "Player"
var bot_controlled:    bool   = false
var is_bot:            bool   = false
var mp_is_dead:        bool   = false
var texture_pfp_icon:  int    = 1

# ==============================================================
# FLAGS DI CONTROLLO
# ==============================================================
@export var can_move:       bool = true
@export var can_shoot:      bool = true
@export var can_dash:       bool = true
@export var can_rotate:     bool = true
@export var can_be_damaged: bool = true
@export var can_interact:   bool = true
@export var can_immune:     bool = true
@export var can_time_slow:  bool = true
@export var can_zoom:       bool = true
@export var current_weapon: String = "Pulse Blaster"
@export var progression_weapon_index: int = 0
var progression_hp: float = 50.0

@export var acceleration: float = 18.0
@export var friction:     float = 12.0

# ==============================================================
# NODI
# ==============================================================
@onready var body_p    = $BodySprite
@onready var wing_p    = $Wings/WingsSprite
@onready var prop_p    = $Propulsor/PropulsorSprite
@onready var canon_p   = $Canon/CanonSprite
@onready var canon     = $Canon
@onready var propulsor = $Propulsor
@onready var wings     = $Wings
@onready var body      = $BodySprite
@onready var camera_ring = $CameraRing

# ==============================================================
# INPUT / STATO
# ==============================================================
var input_direction:      Vector2 = Vector2.ZERO
var last_input_direction: Vector2 = Vector2.DOWN
var is_moving:   bool = false
var is_shooting: bool = false
var is_dashing:  bool = false

# ==============================================================
# AEGIS STORM
# ==============================================================
var aeg_shield = preload("res://Gres/Scenes/Effects/shield_aeg.tscn")
var _aegis_charging:      bool   = false
var _aegis_charge_time:   float  = 0.0
var _aegis_max_charge:    float  = 5.0
var _aegis_shield_active: bool   = false
var _aegis_shield_node:   Node2D = null
var deflect_percent := 100

# ==============================================================
# SKILL ATTIVA — COOLDOWN
# ==============================================================
var _skill_ready:        bool  = true
var _skill_cooldown:     float = 0.0
var _skill_cooldown_max: float = 20.0
var _cd_hud_node: Node2D = null

# ==============================================================
# ANIMAZIONI — NODI AURA PERSISTENTI
# ==============================================================
var _aura_node:      Node2D = null
var _burn_fx_node:   Node2D = null
var _inv_tween:      Tween  = null
var _overheal_tween: Tween  = null
var _pre_eclipse_modulate: Color = Color.WHITE
var _death_tweens: Array[Tween] = []

# ==============================================================
# SISTEMA BUFF / DEBUFF
# ==============================================================
var active_buffs: Array = []
var void_stacks = 0
var max_stacks = 50
var pulse_scale = 1.0
var rotation_angle = 0.0
var pulse_timer : Timer

var is_eclipse_active : bool = false
var eclipse_timer : float = 0.0
var eclipse_rotation : float = 0.0

# ==============================================================
# RPC - DAMAGE
# ==============================================================
@rpc("any_peer", "call_local", "reliable")
func take_pvp_damage(amount: float) -> void:
	print("[MP_Player] RPC take_pvp_damage ricevuto per ", name, " danno: ", amount, " from peer: ", multiplayer.get_remote_sender_id())
	print("  -> is_multiplayer_authority: ", is_multiplayer_authority())
	print("  -> mp_is_dead: ", mp_is_dead)
	
	if not is_multiplayer_authority():
		print("  -> NON sono l'autorità, ignoro il danno!")
		return
	if mp_is_dead:
		print("  -> già morto, ignoro")
		return
	take_damage(amount)


func take_pvp_damage_direct(amount: float) -> void:
	print("[MP_Player] DIRECT take_pvp_damage_direct per ", name, " danno: ", amount)
	if mp_is_dead:
		print("  -> già morto, ignoro")
		return
	if not can_be_damaged:
		print("  -> can_be_damaged false, ignoro")
		return
	
	mp_synced_hp -= amount
	print("  -> mp_synced_hp ora: ", mp_synced_hp)
	
	if mp_synced_hp <= 0:
		mp_synced_hp = 0
		print("  -> MUORE! Chiamo on_player_dead()")
		on_player_dead()

@rpc("any_peer", "reliable")
func report_pve_damage(enemy_id: int, damage_amount: float) -> void:
	if not multiplayer.is_server():
		return
	var wave_manager = get_node("/root/Arena/PVEWaveManager") if get_node("/root/Arena") else null
	if not wave_manager:
		wave_manager = get_tree().current_scene.get_node_or_null("PVEWaveManager")
	if wave_manager:
		var enemy_node = wave_manager.get_node_or_null("Enemy_%d" % enemy_id)
		if is_instance_valid(enemy_node) and enemy_node.has_method("take_damage"):
			var sender_id = multiplayer.get_remote_sender_id()
			enemy_node.take_damage(damage_amount, sender_id)

# ==============================================================
# RPC - NOTIFICA MORTE
# ==============================================================
@rpc("authority", "call_local", "reliable")
func rpc_notify_death() -> void:
	mp_is_dead       = true
	can_be_damaged   = false   # FIX: invincibile immediatamente
	can_dash         = false
	can_move         = false
	can_rotate       = false
	can_shoot        = false
	if has_node("Audio/die"):
		$Audio/die.play()
	emit_signal("player_died")
	_mp_death_fx()

@rpc("any_peer", "reliable", "call_local")
func notify_player_dead(dead_peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	print("[Player] Notifica morte ricevuta per peer: ", dead_peer_id)
	_on_player_dead_confirmed.rpc(dead_peer_id)

@rpc("any_peer", "reliable", "call_local")
func _on_player_dead_confirmed(dead_peer_id: int) -> void:
	print("[Player] Player confermato morto: ", dead_peer_id)

# ==============================================================
# RPC - RESET VISUALE PER TUTTI (FIX invisibilità avversario)
# Chiamato dall'Arena in broadcast su TUTTI i peer.
# Ripristina sprite position e alpha del player con peer_id dato.
# ==============================================================
@rpc("any_peer", "call_local", "reliable")
func rpc_reset_visuals() -> void:
	# Killa tween attivi
	if is_instance_valid(_inv_tween):
		_inv_tween.kill()
		_inv_tween = null
	if is_instance_valid(_overheal_tween):
		_overheal_tween.kill()
		_overheal_tween = null
		
	for tw in _death_tweens:
		if is_instance_valid(tw):
			tw.kill()
	_death_tweens.clear()

	# Reset sprite: position locale (0,0) e alpha 1
	var sprite_paths := [
		"BodySprite",
		"Wings/WingsSprite",
		"Propulsor/PropulsorSprite",
		"Canon/CanonSprite",
	]
	for path in sprite_paths:
		var node := get_node_or_null(path)
		if is_instance_valid(node):
			node.position = Vector2.ZERO
			node.modulate = Color(1, 1, 1, 1)
			node.visible = true

	# Reset modulate globale del CharacterBody2D
	modulate = Color.WHITE
	visible = true

# ==============================================================
# RPC - RESET COMPLETO PER RESPAWN (solo player proprietario)
# Chiamato dall'Arena con rpc_id(peer_id).
# ==============================================================
@rpc("any_peer", "call_local", "reliable")
func rpc_set_player_name(p_name: String) -> void:
	mp_player_name = p_name

@rpc("any_peer", "call_local", "reliable")
func rpc_do_respawn(new_pos: Vector2) -> void:
	# Killa tween
	if is_instance_valid(_inv_tween):
		_inv_tween.kill()
		_inv_tween = null
	if is_instance_valid(_overheal_tween):
		_overheal_tween.kill()
		_overheal_tween = null

	# Reset flag
	mp_is_dead         = false
	
	var respawn_hp = progression_hp if GameModes.is_progression_mode() else mp_max_hp
	
	if is_local_player:
		Global.player_dead = false
		Global.player_hp = respawn_hp
		
	mp_synced_hp     = respawn_hp

	# Clear buffs (riabilita can_move, can_shoot, etc.)
	clear_buffs()

	# Posizione e velocity
	global_position = new_pos
	velocity        = Vector2.ZERO

	# Invincibilità post-spawn: 2 secondi con lampeggio
	apply_buff("invincible", 2.0)

	print("[Player] Respawn completato. HP=", Global.player_hp, " pos=", global_position)

# ==============================================================
# FUNZIONI BUFF / DEBUFF
# ==============================================================
func apply_buff(buff_name: String, duration: float, params: Dictionary = {}) -> void:
	for b in active_buffs:
		if b.name == buff_name:
			b.duration = max(b.duration, duration)
			b.timer    = 0.0
			return
	var buff = { "name": buff_name, "duration": duration,
		"timer": 0.0, "params": params, "tick_timer": 0.0 }
	active_buffs.append(buff)
	_buff_on_apply(buff)

func remove_buff(buff_name: String) -> void:
	for i in range(active_buffs.size()):
		if active_buffs[i].name == buff_name:
			_buff_on_remove(active_buffs[i])
			active_buffs.remove_at(i)
			break

func has_buff(buff_name: String) -> bool:
	for b in active_buffs:
		if b.name == buff_name: return true
	return false

func get_buff_param(buff_name: String, param_key: String, default_value=null):
	for b in active_buffs:
		if b.name == buff_name:
			return b.params.get(param_key, default_value)
	return default_value

func _update_buffs(delta: float) -> void:
	for i in range(active_buffs.size() - 1, -1, -1):
		var buff = active_buffs[i]
		buff.timer += delta
		if buff.params.has("dps"):
			buff.tick_timer += delta
			if buff.tick_timer >= buff.params.get("interval", 1.0):
				buff.tick_timer = 0.0
				take_damage(buff.params.dps * buff.params.get("interval", 1.0))
		if buff.timer >= buff.duration:
			_buff_on_remove(buff)
			active_buffs.remove_at(i)

func _buff_on_apply(buff: Dictionary) -> void:
	match buff.name:
		"frozen":
			can_move   = false
			can_rotate = false
			_fx_tween_modulate(Color(0.4, 0.85, 1.0, 1.0), 0.2)
			_fx_crystal_burst(Color(0.7, 0.95, 1.0, 0.8))
		"invincible":
			can_be_damaged = false
			if is_instance_valid(_inv_tween): _inv_tween.kill()
			_inv_tween = create_tween().set_loops()
			_inv_tween.tween_property(self, "modulate:a", 0.2, 0.07)
			_inv_tween.tween_property(self, "modulate:a", 1.0, 0.07)
		"burn":
			if not is_instance_valid(_burn_fx_node):
				_burn_fx_node = _BurnFX.new()
				add_child(_burn_fx_node)
		"aegis_shield":
			_aegis_shield_active = true
			_spawn_aegis_shield_visual()
		"soul_overheal":
			if is_instance_valid(_overheal_tween): _overheal_tween.kill()
			_overheal_tween = create_tween().set_loops()
			_overheal_tween.tween_property(self, "modulate", Color(1.5, 1.2, 0.2, 1.0), 0.4)
			_overheal_tween.tween_property(self, "modulate", Color(1.0, 0.8, 0.1, 1.0), 0.4)
		"chrono_speed":
			pass
		"sovereign_active":
			_replace_aura(_SovereignAura.new())
			_fx_ring_burst(Color(0.5, 0.9, 1.0, 0.8), 600.0, 0.6)
			_fx_screen_flash(Color(0.5, 0.9, 1.0, 0.25))
			if camera_ring: camera_ring.shake(0.8)
		"herald_judgment":
			_replace_aura(_HeraldAura.new())
			_fx_ring_burst(Color(0.5, 0.0, 1.0, 0.7), 500.0, 0.55)
			_fx_screen_flash(Color(0.3, 0.0, 0.6, 0.2))
			if camera_ring: camera_ring.shake(0.65)
		"eclipse_active":
			_pre_eclipse_modulate = modulate
			_fx_tween_modulate(Color(0.05, 0.0, 0.15, 1.0), 0.4)
			_replace_aura(_EclipseAura.new())
			_fx_screen_flash(Color(0.0, 0.0, 0.0, 0.7))
			if camera_ring: camera_ring.shake(1.2)
		"chrono_burst_active":
			_fx_ring_burst(Color(0.0, 1.0, 0.85, 0.75), 800.0, 0.5)
			_fx_screen_flash(Color(0.0, 0.7, 1.0, 0.2))
			if camera_ring: camera_ring.shake(0.55)
		"storm_apex_active":
			_fx_ring_burst(Color(1.0, 1.0, 0.2, 0.7), 400.0, 0.45)
			_fx_screen_flash(Color(1.0, 1.0, 0.0, 0.15))
			if camera_ring: camera_ring.shake(0.6)
		"gaia_pulse_active":
			_fx_ring_burst(Color(0.2, 1.0, 0.3, 0.85), 900.0, 0.7)
			_fx_screen_flash(Color(0.0, 0.8, 0.2, 0.3))
			if camera_ring: camera_ring.shake(1.0)
		"echo_storm_active":
			_fx_ring_burst(Color(0.5, 0.5, 1.0, 0.65), 300.0, 0.4)
		"necro_surge_active":
			_fx_ring_burst(Color(0.0, 1.0, 0.4, 0.65), 300.0, 0.5)
		"mass_swap_active":
			_fx_screen_flash(Color(0.6, 0.2, 1.0, 0.3))
			if camera_ring: camera_ring.shake(0.7)

func _buff_on_remove(buff: Dictionary) -> void:
	match buff.name:
		"frozen":
			can_move   = true
			can_rotate = true
			_fx_tween_modulate(Color.WHITE, 0.3)
		"invincible":
			can_be_damaged = true
			if is_instance_valid(_inv_tween): _inv_tween.kill()
			modulate.a = 1.0
		"burn":
			if is_instance_valid(_burn_fx_node):
				_burn_fx_node.queue_free()
				_burn_fx_node = null
		"aegis_shield":
			_aegis_shield_active = false
			_destroy_aegis_shield_visual()
		"soul_overheal":
			if is_instance_valid(_overheal_tween): _overheal_tween.kill()
			_fx_tween_modulate(Color.WHITE, 0.4)
		"chrono_speed":
			pass
		"sovereign_active", "herald_judgment", "echo_storm_active", \
		"storm_apex_active", "necro_surge_active", "mass_swap_active", \
		"gaia_pulse_active", "chrono_burst_active":
			_remove_aura()
		"eclipse_active":
			_remove_aura()
			_fx_tween_modulate(_pre_eclipse_modulate, 0.5)
			_fx_ring_burst(Color(0.7, 0.0, 1.0, 0.6), 300.0, 0.4)
			remove_meta("eclipse_no_hp_cost") if has_meta("eclipse_no_hp_cost") else null

func clear_buffs() -> void:
	active_buffs.clear()
	can_move       = true
	can_shoot      = true
	can_dash       = true
	can_rotate     = true
	can_be_damaged = true
	can_immune     = true
	can_time_slow  = true
	modulate       = Color.WHITE

	if is_instance_valid(_burn_fx_node):
		_burn_fx_node.queue_free()
		_burn_fx_node = null
	if is_instance_valid(_inv_tween):
		_inv_tween.kill()
		_inv_tween = null

func _spawn_aegis_shield_visual() -> void:
	if not ResourceLoader.exists("res://Gres/Scenes/Effects/shield_aeg.tscn"): return
	if is_instance_valid(_aegis_shield_node): return
	_aegis_shield_node = load("res://Gres/Scenes/Effects/shield_aeg.tscn").instantiate()
	add_child(_aegis_shield_node)

func _destroy_aegis_shield_visual() -> void:
	if is_instance_valid(_aegis_shield_node):
		_aegis_shield_node.queue_free()
		_aegis_shield_node = null

func _on_aegis_deflect(enemy_bullet: Node) -> void:
	if not _aegis_shield_active: return
	if enemy_bullet.has_meta("already_deflected"): return
	var deflect_chance: int = GlobalWeapons.current_weapon.get("shield_deflect_chance", deflect_percent)
	var success: bool = randi() % 100 < deflect_chance
	if success:
		Global.is_deflected = true
		enemy_bullet.set_meta("already_deflected", true)
		if "direction" in enemy_bullet:
			enemy_bullet.direction = -enemy_bullet.direction
		if "group" in enemy_bullet:
			enemy_bullet.group = "p_bullet"
		if is_instance_valid(_aegis_shield_node):
			var tw = create_tween()
			tw.tween_property(_aegis_shield_node, "modulate", Color(2.5, 2.5, 2.5, 1.0), 0.03)
			tw.tween_property(_aegis_shield_node, "modulate", Color.WHITE, 0.18)

func _trigger_active_skill() -> void:
	if not _skill_ready: return
	var weapon := GlobalWeapons.current_weapon
	var ptype  = weapon.get("projectile_type", "")
	match ptype:
		"nullborn_sovereign_shot":  _skill_sovereign_decree()
		"oblivion_herald_shot":     _skill_herald_judgment()
		"voidfather_eclipse_shot":  _skill_the_eclipse()
		"chrono_ripper_shot":       _skill_chrono_burst()
		"soul_leech_shot":          _skill_soul_drain()
		"dimensional_swap_shot":    _skill_mass_swap()
		"storm_caller_shot":        _skill_storm_apex()
		"graviton_pulse_shot":      _skill_graviton_collapse()
		"proximity_mine_shot":      _skill_detonate_all_mines()
		"necro_pulse_shot":         _skill_necro_surge()
		"rift_blade_shot":          _skill_rift_cascade()
		"mind_fracture_shot":       _skill_mass_control()
		"gaea_core_main":           _skill_gaia_pulse()
		"blood_nexus_main":         _skill_red_convergence()
		"wall_caster_shot":         _skill_manual_wall()
		"phantom_echo_shot":        _skill_echo_storm()
		"aegis_storm_shot":         pass
		"line":                     _skill_pvp_line_burst()
		"wave_split":               _skill_pvp_splitter_surge()
		"bounce":                   _skill_pvp_bounce_chain()
		"homing":                   _skill_pvp_homing_swarm()
		"explode_after":            _skill_pvp_detonate()
		"cone_5":                   _skill_pvp_full_salvo()
		_:
			_fx_ring_burst(Color(1.0, 0.8, 0.3, 0.6), 200.0, 0.35)
	_skill_ready        = false
	_skill_cooldown     = _skill_cooldown_max
	_spawn_cd_hud()

func _process_skill_cooldown(delta: float) -> void:
	if not _skill_ready:
		_skill_cooldown -= delta
		if _skill_cooldown <= 0.0:
			_skill_ready    = true
			_skill_cooldown = 0.0
			var tw = create_tween().set_parallel(true)
			tw.tween_property(self, "modulate", Color(0.3, 1.0, 0.5, 1.0), 0.08)
			tw.tween_property(self, "modulate", Color.WHITE, 0.4).set_delay(0.08)
			_fx_ring_burst(Color(0.3, 1.0, 0.5, 0.5), 120.0, 0.3)

func _skill_sovereign_decree() -> void:
	_skill_cooldown_max = 20.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("apply_buff"): e.apply_buff("frozen", 4.0)
	apply_buff("sovereign_active", 4.0)
	apply_buff("invincible", 4.0)
	set_meta("sovereign_active", true)
	get_tree().create_timer(4.0).timeout.connect(func():
		if has_meta("sovereign_active"): remove_meta("sovereign_active"))

func _skill_herald_judgment() -> void:
	_skill_cooldown_max = 18.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("apply_buff"): e.apply_buff("marked", 10.0)
	apply_buff("herald_judgment", 10.0)
	set_meta("herald_judgment_active", true)
	get_tree().create_timer(10.0).timeout.connect(func():
		if has_meta("herald_judgment_active"): remove_meta("herald_judgment_active"))

func _skill_the_eclipse() -> void:
	_skill_cooldown_max = 40.0
	apply_buff("eclipse_active", 8.0)
	apply_buff("invincible", 8.0)
	set_meta("eclipse_no_hp_cost", true)

func _skill_chrono_burst() -> void:
	_skill_cooldown_max = 25.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("apply_buff"): e.apply_buff("frozen", 2.0)
	apply_buff("chrono_burst_active", 2.0)
	set_meta("chrono_burst_active", true)
	get_tree().create_timer(2.0).timeout.connect(func():
		if has_meta("chrono_burst_active"): remove_meta("chrono_burst_active"))

func _skill_soul_drain() -> void:
	_skill_cooldown_max = 18.0
	var target := _find_nearest_enemy()
	if not is_instance_valid(target): return
	_fx_beam_to_target(target.global_position, Color(0.8, 0.0, 0.1))
	if camera_ring: camera_ring.shake(0.35)
	for _i in range(3):
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(target) or not is_instance_valid(self): break
		var drain = target.get("hp") if target.get("hp") != null else 0.0
		drain *= 0.08
		if target.has_method("take_damage"): target.take_damage(drain, self)
		Global.player_hp = min(Global.player_hp + drain, Global.player_max_hp)

func _skill_mass_swap() -> void:
	_skill_cooldown_max = 20.0
	apply_buff("mass_swap_active", 0.1)
	var enemies := get_tree().get_nodes_in_group("enemy")
	var positions: Array[Vector2] = []
	for e in enemies:
		if e is Node2D: positions.append(e.global_position)
	positions.shuffle()
	for i in range(min(enemies.size(), positions.size())):
		if not (enemies[i] is Node2D): continue
		_spawn_swap_portal_fx(enemies[i].global_position)
		enemies[i].global_position = positions[i]
		if enemies[i].has_method("apply_buff"): enemies[i].apply_buff("frozen", 1.2)

func _skill_storm_apex() -> void:
	_skill_cooldown_max = 22.0
	apply_buff("storm_apex_active", 6.0)
	set_meta("storm_apex_active", true)
	get_tree().create_timer(6.0).timeout.connect(func():
		if has_meta("storm_apex_active"): remove_meta("storm_apex_active"))

func _skill_graviton_collapse() -> void:
	_skill_cooldown_max = 25.0
	set_meta("graviton_collapse_next", true)
	_fx_ring_burst(Color(0.3, 0.0, 0.8, 0.7), 200.0, 0.4)
	if camera_ring: camera_ring.shake(0.5)

func _skill_detonate_all_mines() -> void:
	_skill_cooldown_max = 15.0
	if camera_ring: camera_ring.shake(0.9)
	_fx_screen_flash(Color(1.0, 0.5, 0.0, 0.25))
	for b in get_tree().get_nodes_in_group("p_bullet"):
		if b.get("projectile_type") == "proximity_mine_shot" and b.get("_is_mine"):
			if b.has_method("_mine_explode"): b._mine_explode()

func _skill_necro_surge() -> void:
	_skill_cooldown_max = 30.0
	apply_buff("necro_surge_active", 3.0)
	set_meta("necro_surge_active", true)
	get_tree().create_timer(3.0).timeout.connect(func():
		if has_meta("necro_surge_active"): remove_meta("necro_surge_active"))

func _skill_rift_cascade() -> void:
	_skill_cooldown_max = 10.0
	if camera_ring: camera_ring.shake(0.75)
	_fx_screen_flash(Color(0.4, 0.0, 0.9, 0.2))
	var base_dir := Vector2(cos(rotation), sin(rotation))
	var bullet_scene = load("res://Gres/Scenes/weapons/bullet/player_bullet.tscn")
	for i in range(5):
		var angle := deg_to_rad(-40.0 + 20.0 * float(i))
		var dir   := base_dir.rotated(angle)
		var b      = bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = canon.global_position
		b.init_from_weapon(GlobalWeapons.current_weapon.duplicate(true), dir, self, false)

func _skill_mass_control() -> void:
	_skill_cooldown_max = 30.0
	_fx_screen_flash(Color(0.5, 0.0, 1.0, 0.2))
	if camera_ring: camera_ring.shake(0.6)
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("_become_ally"): e._become_ally(5.0)

func _skill_gaia_pulse() -> void:
	_skill_cooldown_max = 25.0
	apply_buff("gaia_pulse_active", 0.1)
	var pulse_dmg: float = GlobalWeapons.current_weapon.get("pulse_damage", 120.0 * Global.player_damage)
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("take_damage"): e.take_damage(pulse_dmg, self)

func _skill_red_convergence() -> void:
	_skill_cooldown_max = 20.0
	if camera_ring: camera_ring.shake(0.85)
	_fx_screen_flash(Color(0.8, 0.0, 0.0, 0.3))
	var pull_force: float = GlobalWeapons.current_weapon.get("convergence_pull_force", 900.0)
	var dps:        float = GlobalWeapons.current_weapon.get("convergence_dps", 40.0)
	var duration:   float = GlobalWeapons.current_weapon.get("convergence_duration", 2.0)
	var center := global_position
	var ticks   := int(duration / 0.1)
	for _tick in range(ticks):
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(self): break
		for e in get_tree().get_nodes_in_group("enemy"):
			if not (e is Node2D and is_instance_valid(e)): continue
			if not e.get("is_blood_linked"): continue
			if "velocity" in e: e.velocity += (center - e.global_position).normalized() * pull_force * 0.1
			if e.has_method("take_damage"): e.take_damage(dps * 0.1, self)

func _skill_manual_wall() -> void:
	_skill_cooldown_max = 15.0
	if Global.player_stamina < 30: return
	Global.player_stamina -= 30
	var dur: float = GlobalWeapons.current_weapon.get("wall_duration", 4.0) * 2.0
	_fx_ring_burst(Color(0.6, 0.8, 1.0, 0.5), 180.0, 0.35)
	var wall = load("res://Gres/Scenes/Effects/void_wall.tscn").instantiate()
	get_tree().current_scene.add_child(wall)
	wall.global_position = global_position + transform.x * 80.0
	wall.rotation = rotation
	get_tree().create_timer(dur).timeout.connect(func(): if is_instance_valid(wall): wall.queue_free())

func _skill_echo_storm() -> void:
	_skill_cooldown_max = 18.0
	apply_buff("echo_storm_active", 4.0)
	set_meta("echo_storm_active", true)
	get_tree().create_timer(4.0).timeout.connect(func():
		if has_meta("echo_storm_active"): remove_meta("echo_storm_active"))

func _skill_pvp_line_burst() -> void:
	_skill_cooldown_max = 12.0
	apply_buff("pvp_fire_rate_boost", 3.0, {"mult": 0.5})
	_fx_ring_burst(Color(1.0, 0.8, 0.2, 0.6), 150.0, 0.3)

func _skill_pvp_splitter_surge() -> void:
	_skill_cooldown_max = 10.0
	apply_buff("pvp_damage_boost", 5.0, {"mult": 1.3})
	_fx_ring_burst(Color(0.2, 0.8, 1.0, 0.6), 150.0, 0.3)

func _skill_pvp_bounce_chain() -> void:
	_skill_cooldown_max = 10.0
	apply_buff("pvp_speed_boost", 4.0, {"mult": 1.4})
	_fx_ring_burst(Color(0.8, 0.4, 1.0, 0.6), 150.0, 0.3)

func _skill_pvp_homing_swarm() -> void:
	_skill_cooldown_max = 14.0
	apply_buff("pvp_homing_mark", 6.0)
	set_meta("pvp_homing_mark", true)
	get_tree().create_timer(6.0).timeout.connect(func():
		if has_meta("pvp_homing_mark"): remove_meta("pvp_homing_mark"))
	_fx_ring_burst(Color(0.2, 1.0, 0.6, 0.6), 180.0, 0.35)

func _skill_pvp_detonate() -> void:
	_skill_cooldown_max = 8.0
	_fx_ring_burst(Color(1.0, 0.3, 0.1, 0.7), 200.0, 0.4)
	var blast_radius := 120.0
	var blast_damage := 40.0
	for body in get_tree().get_nodes_in_group("mp_player"):
		if body == self or body.get("mp_is_dead") == true:
			continue
		var dist = global_position.distance_to(body.global_position)
		if dist < blast_radius:
			body.rpc_id(body.get_multiplayer_authority(), "take_pvp_damage", blast_damage * (1.0 - dist / blast_radius))

func _skill_pvp_full_salvo() -> void:
	_skill_cooldown_max = 14.0
	apply_buff("pvp_damage_boost", 3.0, {"mult": 1.5})
	_fx_ring_burst(Color(1.0, 0.5, 0.0, 0.6), 200.0, 0.3)

func _process_passives(delta: float) -> void:
	var ptype = GlobalWeapons.current_weapon.get("projectile_type", "")
	match ptype:
		"nullborn_sovereign_shot":  _passive_nullborn()
		"soul_leech_shot":          _passive_soul_leech()
		"chrono_ripper_shot":       _passive_chrono()
		"storm_caller_shot":        _passive_storm()
		"voidfather_eclipse_shot":  _passive_voidfather()
		"vulrath_ignis":            _passive_vulrath()

func _passive_nullborn() -> void:
	var any_frozen := false
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("has_buff") and e.has_buff("frozen"):
			any_frozen = true; break
	if any_frozen and not has_buff("chrono_speed"):
		apply_buff("chrono_speed", 0.5)

func _passive_soul_leech() -> void:
	if Global.player_hp > Global.player_max_hp and not has_buff("soul_overheal"):
		apply_buff("soul_overheal", 999.0)
	elif Global.player_hp <= Global.player_max_hp and has_buff("soul_overheal"):
		remove_buff("soul_overheal")

func _passive_chrono() -> void:
	var any_slowed := false
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("has_buff") and e.has_buff("slowed"):
			any_slowed = true; break
	if any_slowed and not has_buff("chrono_speed"):
		apply_buff("chrono_speed", 0.3)

func _passive_storm() -> void: pass

func _passive_voidfather() -> void:
	var stacks = get_meta("void_empowerment_stacks", 0)
	void_stacks = clamp(stacks, 0, max_stacks)
	queue_redraw()

func _draw():
	var center = Vector2.ZERO
	if void_stacks > 0:
		var max_radius_stack = 150.0
		var intensity = void_stacks / float(max_stacks)
		for i in range(5):
			var r = max_radius_stack * (0.7 + i * 0.1) * (0.8 + intensity * 0.4)
			var color = Color(0.05, 0.0, 0.1, 0.4 - i * 0.07)
			draw_circle(center, r, color)
		var ring_radius = max_radius_stack * (0.9 + sin(Time.get_ticks_msec() * 0.008) * 0.05) * pulse_scale
		draw_arc(center, ring_radius, 0, TAU, 64, Color(0.6, 0.0, 0.8, 0.9), 3.0, true)
	if is_eclipse_active:
		var max_radius_eclipse = 220.0
		var prog = min(eclipse_timer / 0.5, 1.0)
		for i in range(8):
			var r = max_radius_eclipse * (0.5 + i * 0.1) * (0.8 + sin(Time.get_ticks_msec() * 0.01) * 0.2)
			draw_circle(center, r, Color(0.0, 0.0, 0.0, 0.6 * (1.0 - i / 8.0) * prog))
		var core_radius = max_radius_eclipse * (0.2 + sin(eclipse_timer * 12) * 0.05) * prog
		draw_circle(center, core_radius, Color(0.0, 0.0, 0.0, 1.0))
		draw_circle(center, core_radius * 1.4, Color(0.3, 0.0, 0.6, 0.8))

func _passive_vulrath() -> void:
	if Global.player_hp < Global.player_max_hp * 0.4:
		if not has_meta("vulrath_boost"):
			set_meta("vulrath_boost", true)
			Global.shoot_freeze = GlobalWeapons.current_weapon.get("fire_rate", 0.38) * 0.82
	else:
		if has_meta("vulrath_boost"):
			remove_meta("vulrath_boost")
			Global.shoot_freeze = GlobalWeapons.current_weapon.get("fire_rate", 0.38)

func _fx_tween_modulate(col: Color, dur: float) -> void:
	create_tween().tween_property(self, "modulate", col, dur)

func _fx_ring_burst(col: Color, radius: float, dur: float) -> void:
	var ring := _RingBurst.new()
	ring.global_position = global_position
	ring.ring_color = col
	ring.max_radius = radius
	ring.duration = dur
	get_parent().add_child(ring)

func _fx_screen_flash(col: Color) -> void:
	if not has_node("../FlashOverlay"): return
	var flash = get_node("../FlashOverlay")
	flash.modulate = col
	create_tween().tween_property(flash, "modulate:a", 0.0, 0.35)
	if has_node("FX_Bullets"):
		$FX_Bullets.play("eclipse")

func _fx_shoot(rarity: String) -> void:
	var shake_map := {"common": 0.12, "rare": 0.25, "epic": 0.42, "legendary": 0.65}
	if camera_ring: camera_ring.shake(shake_map.get(rarity, 0.12))
	var tw = create_tween()
	tw.tween_property(canon, "position", Vector2(-7, 0), 0.04).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(canon, "position", Vector2.ZERO, 0.14).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	if is_instance_valid(canon_p):
		var tw2 = create_tween()
		tw2.tween_property(canon_p, "modulate", Color(2.5, 2.5, 1.5, 1.0), 0.03)
		tw2.tween_property(canon_p, "modulate", Color.WHITE, 0.12)
	var tw3 = create_tween()
	tw3.tween_property(body_p, "scale", Vector2(0.87, 1.16), 0.04)
	tw3.tween_property(body_p, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SPRING)

func _fx_dash() -> void:
	is_dashing = true
	var dash_col := _get_dash_color()
	if camera_ring: camera_ring.shake(0.9)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(2.4, 0.1), 0.04).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	var tw2 = create_tween().set_parallel(true)
	for p in [body_p, wing_p, prop_p]:
		if not is_instance_valid(p): continue
		tw2.tween_property(p, "modulate", dash_col * 4.2, 0.02)
		tw2.tween_property(p, "modulate", Color.WHITE, 0.3).set_delay(0.02)
	_fx_plasma_ghost_burst(dash_col, 10, 0.5)
	_spawn_dash_trail(dash_col, 8, 0.02, 0.4)
	for i in range(5):
		await get_tree().process_frame
		_spawn_dash_ghost(dash_col, 0.35, 1.0 + i * 0.05)
	await get_tree().create_timer(0.3).timeout
	is_dashing = false

func _get_dash_color() -> Color:
	return Color(0.2, 0.8, 1.0, 1.0)

func _spawn_dash_ghost(color: Color = Color.WHITE, duration: float = 0.25,
		scale_factor: float = 1.0, offset: Vector2 = Vector2.ZERO) -> Node2D:
	var ghost := Sprite2D.new()
	ghost.texture = $BodySprite.texture
	ghost.hframes = $BodySprite.hframes
	ghost.vframes = $BodySprite.vframes
	ghost.frame = $BodySprite.frame
	ghost.scale = scale * scale_factor
	ghost.rotation = rotation
	ghost.modulate = color
	ghost.modulate.a = 0.7
	ghost.global_position = global_position + offset
	get_parent().add_child(ghost)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(ghost, "modulate:a", 0.0, duration)
	tw.tween_property(ghost, "scale", ghost.scale * 0.5, duration)
	tw.tween_callback(ghost.queue_free).set_delay(duration)
	return ghost

func _fx_plasma_ghost_burst(color: Color, count: int, duration: float) -> void:
	for i in range(count):
		var angle = TAU * i / count
		var ghost = _spawn_dash_ghost(color, duration, 0.6, Vector2.RIGHT.rotated(angle) * 8.0)
		var tw = create_tween()
		tw.tween_property(ghost, "global_position", global_position + Vector2.RIGHT.rotated(angle) * 50.0, duration)
		tw.parallel().tween_property(ghost, "modulate:a", 0.0, duration)
		tw.parallel().tween_property(ghost, "scale", Vector2(1.8, 1.8), duration)

func _spawn_dash_trail(color: Color, count: int, interval: float, lifetime: float) -> void:
	var dir := last_input_direction if last_input_direction != Vector2.ZERO else Vector2.RIGHT
	for i in range(count):
		await get_tree().create_timer(interval).timeout
		if not is_dashing: break
		_spawn_dash_ghost(color, lifetime, 0.8 + i * 0.02, -dir * (10.0 + i * 5.0))

func _fx_weapon_pickup(rarity: String) -> void:
	var rarity_col = {
		"common": Color(0.7, 0.9, 1.0), "rare": Color(0.2, 0.5, 1.0),
		"epic": Color(0.7, 0.0, 1.0),   "legendary": Color(1.0, 0.7, 0.0)
	}.get(rarity, Color.WHITE)
	var tw = create_tween().set_parallel(true)
	for p in [body_p, wing_p, prop_p, canon_p]:
		if not is_instance_valid(p): continue
		tw.tween_property(p, "modulate", rarity_col * 2.2, 0.06)
		tw.tween_property(p, "modulate", Color.WHITE, 0.5).set_delay(0.06)

func hurt_flash(amount: float = 0.0) -> void:
	var is_heavy := amount > Global.player_max_hp * 0.15
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.75, 0.38), 0.05)
	tw.tween_property(self, "scale", Vector2(0.72, 1.38), 0.10).set_delay(0.05)
	tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_delay(0.15).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate", Color(2.5, 0.0, 0.0, 1.0) if is_heavy else Color(2.0, 0.0, 0.0, 1.0), 0.03)
	tw.tween_property(self, "modulate", Color.WHITE, 0.32).set_delay(0.03)
	tw.tween_method(shake_position, 0.0, 1.0, 0.35)
	if is_heavy:
		if camera_ring: camera_ring.shake(0.75)
		_fx_ring_burst(Color(1.0, 0.0, 0.0, 0.4), 90.0, 0.3)

func shake_position(intensity: float) -> void:
	position.x += randf_range(-4.0, 4.0) * intensity
	position.y += randf_range(-3.0, 3.0) * intensity

func _fx_crystal_burst(col: Color) -> void:
	var burst := _CrystalBurst.new()
	burst.global_position = global_position
	burst.burst_color = col
	get_parent().add_child(burst)

func _fx_beam_to_target(target_pos: Vector2, col: Color) -> void:
	var beam := _BeamFX.new()
	beam.global_position = global_position
	beam.target_pos = target_pos
	beam.beam_color = col
	get_parent().add_child(beam)

func _spawn_swap_portal_fx(pos: Vector2) -> void:
	var portal := _SwapPortalFX.new()
	portal.global_position = pos
	get_parent().add_child(portal)

var _chrono_img_timer: float = 0.0
func _spawn_chrono_afterimage() -> void:
	for p in [body_p, wing_p]:
		if not (p is Sprite2D): continue
		var ghost := Sprite2D.new()
		ghost.texture = p.texture
		ghost.global_position = p.global_position
		ghost.global_rotation = p.global_rotation
		ghost.scale = p.scale * scale
		ghost.modulate = Color(0.0, 0.7, 1.0, 0.35)
		ghost.z_index = z_index - 1
		get_parent().add_child(ghost)
		var tw = create_tween()
		tw.tween_property(ghost, "modulate:a", 0.0, 0.28)
		tw.tween_callback(ghost.queue_free)

func _replace_aura(new_aura: Node2D) -> void:
	_remove_aura()
	_aura_node = new_aura
	add_child(_aura_node)

func _remove_aura() -> void:
	if is_instance_valid(_aura_node):
		_aura_node.queue_free()
		_aura_node = null

func _spawn_cd_hud() -> void:
	if is_instance_valid(_cd_hud_node): _cd_hud_node.queue_free()
	_cd_hud_node = _SkillCooldownHUD.new()
	_cd_hud_node.player_ref = self
	_cd_hud_node.total_cd = _skill_cooldown_max
	add_child(_cd_hud_node)

func activate_eclipse():
	is_eclipse_active = true
	eclipse_timer = 0.0
	_pre_eclipse_modulate = modulate
	_fx_tween_modulate(Color(0.05, 0.0, 0.15, 1.0), 0.4)
	_replace_aura(_EclipseAura.new())
	_fx_screen_flash(Color(0.0, 0.0, 0.0, 0.7))
	if camera_ring: camera_ring.shake(1.2)
	set_process(true)
	queue_redraw()

func deactivate_eclipse():
	is_eclipse_active = false
	set_process(false)
	queue_redraw()

# ==============================================================
# CLASSI INTERNE (invariate)
# ==============================================================

class _RingBurst extends Node2D:
	var ring_color: Color = Color(1,1,1,0.6)
	var max_radius: float = 300.0
	var duration: float = 0.5
	var _age: float = 0.0
	func _process(delta):
		_age += delta
		queue_redraw()
		if _age >= duration: queue_free()
	func _draw():
		var t := _age / duration
		for ri in range(3):
			var phase = min(t + ri * 0.12, 1.0)
			var r := max_radius * pow(phase, 0.6)
			var c := ring_color
			c.a = (1.0 - phase) * ring_color.a
			draw_arc(Vector2.ZERO, r, 0, TAU, 64, c, 4.0 * (1.0 - t), true)

class _CrystalBurst extends Node2D:
	var burst_color: Color = Color(0.7, 0.95, 1.0, 0.85)
	var _age: float = 0.0
	var _dur: float = 0.5
	var _arms: Array = []
	func _ready():
		for i in range(10):
			var angle := (TAU / 10.0) * i + randf_range(-0.2, 0.2)
			_arms.append({ "dir": Vector2(cos(angle), sin(angle)), "len": randf_range(22.0, 38.0) })
	func _process(delta):
		_age += delta
		queue_redraw()
		if _age >= _dur: queue_free()
	func _draw():
		var t := _age / _dur
		var a := (1.0 - t)
		for arm in _arms:
			var tip: Vector2 = arm.dir * arm.len * pow(t, 0.5)
			draw_line(Vector2.ZERO, tip, Color(burst_color.r, burst_color.g, burst_color.b, a * 0.8), 2.0, true)
			draw_circle(tip, (1.0 - t) * 3.5, Color(1.0, 1.0, 1.0, a * 0.7))

class _BurnFX extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 18.0) * 0.5 + 0.5
		for i in range(9):
			var a := (TAU / 9.0) * i + _t * 1.8
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a) - 0.35) * (13.0 + p * 7.0),
				Color(1.0, 0.25 + p * 0.5, 0.0, 0.6 * p), 2.2 * p, true)
		draw_circle(Vector2.ZERO, 5.0 + p * 3.5, Color(1.0, 0.35, 0.0, 0.4))

class _SovereignAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 6.0) * 0.5 + 0.5
		for ring in range(3):
			var phase := fmod(_t * 0.75 + ring * 0.33, 1.0)
			draw_arc(Vector2.ZERO, lerp(14.0, 52.0, phase), 0, TAU, 48,
				Color(0.5, 0.9, 1.0, (1.0 - phase) * 0.55), 2.5, true)
		draw_circle(Vector2.ZERO, 4.5 + p * 2.0, Color(0.7, 1.0, 1.0, 0.85))

class _HeraldAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 4.0) * 0.5 + 0.5
		for ring in range(2):
			var phase := _t * 2.5 + ring * PI
			draw_arc(Vector2.ZERO, 30.0 + float(ring) * 10.0 + p * 4.0, phase, phase + TAU * 0.7,
				20, Color(0.5, 0.0, 1.0, 0.5 - ring * 0.15), 2.5, true)
		draw_circle(Vector2.ZERO, 5.5 + p * 2.5, Color(0.7, 0.0, 1.0, 0.65))

class _EclipseAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 3.0) * 0.35 + 0.65
		for ci in range(16):
			var ca := (TAU / 16.0) * ci + _t * 0.18
			draw_line(Vector2.ZERO, Vector2(cos(ca), sin(ca)) * (18.0 + sin(_t * 5.0 + ci * 0.9) * 9.0) * p,
				Color(0.7, 0.0, 0.9, 0.5), 1.5, true)
		draw_circle(Vector2.ZERO, 9.0, Color(0.02, 0.0, 0.06, 1.0))
		draw_circle(Vector2.ZERO, 4.0, Color(0.6, 0.0, 0.85, 0.9))

class _BeamFX extends Node2D:
	var target_pos: Vector2 = Vector2.ZERO
	var beam_color: Color = Color(0.8, 0.0, 0.1)
	var _age: float = 0.0
	var _dur: float = 1.0
	func _process(delta):
		_age += delta
		queue_redraw()
		if _age >= _dur: queue_free()
	func _draw():
		var a := (1.0 - _age / _dur) * 0.8
		var local_t := to_local(target_pos)
		var perp := local_t.normalized().rotated(PI * 0.5) * sin(_age * 20.0) * 5.0
		draw_line(Vector2.ZERO, local_t + perp, Color(beam_color.r, beam_color.g, beam_color.b, a * 0.45), 9.0, true)
		draw_line(Vector2.ZERO, local_t + perp, Color(1.0, 0.3, 0.3, a), 2.0, true)

class _SwapPortalFX extends Node2D:
	var _age: float = 0.0
	var _dur: float = 0.4
	func _process(delta):
		_age += delta
		queue_redraw()
		if _age >= _dur: queue_free()
	func _draw():
		var t := _age / _dur
		var r: float = pow(t * 2.0, 0.4) * 65.0 if t < 0.5 else (1.0 - pow((t - 0.5) * 2.0, 0.6)) * 65.0
		var a := sin(t * PI)
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.8, 0.2, 1.0, a * 0.9), 4.0, true)

class _SkillCooldownHUD extends Node2D:
	var player_ref: Node = null
	var total_cd: float = 20.0
	const STAR_RADIUS := 12.0
	const OFFSET := Vector2(0, -40)
	func _process(_delta):
		queue_redraw()
	func _draw():
		if not is_instance_valid(player_ref):
			queue_free()
			return
		var cd: float = player_ref._skill_cooldown
		if cd <= 0.0:
			queue_free()
			return
		var pct := cd / total_cd
		draw_arc(OFFSET, STAR_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - pct),
			32, Color(0.3, 1.0, 0.5, 0.8), 3.0, true)
		draw_circle(OFFSET, STAR_RADIUS * 0.3, Color(1.0, 1.0, 1.0, 0.5))

# ==============================================================
# READY
# ==============================================================

func unlocker_stats() -> void:
	can_dash  = true
	can_move  = true
	can_rotate = true
	can_shoot = true
	GlobalStats.kill_mobs_lvl = 0

func start_possession_glitch() -> void:
	var parts = [body_p, wing_p, prop_p, canon_p]
	for p in parts:
		p.modulate = Color(1,1,1,0)
		p.scale = Vector2.ONE
		p.position = Vector2.ZERO
	var t = create_tween().set_parallel(true)
	for p in parts:
		t.tween_property(p, "modulate:a", 1.0, 0.1).from(0.0)
	await get_tree().create_timer(0.1).timeout
	for i in range(6):
		for p in parts:
			p.position = Vector2(randf_range(-12, 12), randf_range(-12, 12))
			p.modulate  = Color(1.0, randf_range(0.3, 1.0), randf_range(0.3, 1.0), 1.0)
		await get_tree().create_timer(0.05).timeout
	for p in parts:
		p.position = Vector2.ZERO
		p.scale = Vector2.ONE
		p.modulate = Color(1,1,1,1)

func color_check() -> void:
	$BodySprite.material.set_shader_parameter("red_factor",   Global.body_red_factor)
	$BodySprite.material.set_shader_parameter("green_factor", Global.body_green_factor)
	$BodySprite.material.set_shader_parameter("blue_factor",  Global.body_blue_factor)
	$BodySprite.material.set_shader_parameter("saturation",   Global.body_saturation)
	$BodySprite.material.set_shader_parameter("brightness",   Global.body_brightness)
	$BodySprite.material.set_shader_parameter("contrast",     Global.body_contrast)
	$BodySprite.material.set_shader_parameter("hue_shift",    Global.body_hue_shift)
	$BodySprite.material.set_shader_parameter("gamma",        Global.body_gamma)

# ==============================================================
# SKIN
# ==============================================================

@rpc("reliable", "call_local")
func _sync_skin(skin_data: Dictionary):
	print("[MP] _sync_skin ricevuto da peer ", multiplayer.get_remote_sender_id(), " dati: ", skin_data.keys())
	_apply_skin(skin_data)

func _apply_skin(skin_data: Dictionary):
	# Convert indices to paths if needed
	var body_path = ""
	var wings_path = ""
	var prop_path = ""
	var canon_path = ""

	if skin_data.has("body"):
		var body_val = skin_data["body"]
		if body_val is int:
			body_path = "res://Gres/Assets/player/body/body_%d.png" % max(body_val, 1)
		elif body_val is String:
			body_path = body_val
		if body_path != "" and ResourceLoader.exists(body_path):
			$BodySprite.texture = load(body_path)

	if skin_data.has("wings"):
		var wings_val = skin_data["wings"]
		if wings_val is int:
			wings_path = "res://Gres/Assets/player/wings/wing_%d.png" % max(wings_val, 1)
		elif wings_val is String:
			wings_path = wings_val
		if wings_path != "" and ResourceLoader.exists(wings_path):
			$Wings/WingsSprite.texture = load(wings_path)

	if skin_data.has("prop"):
		var prop_val = skin_data["prop"]
		if prop_val is int:
			prop_path = "res://Gres/Assets/player/propuls/prop_%d.png" % max(prop_val, 1)
		elif prop_val is String:
			prop_path = prop_val
		if prop_path != "" and ResourceLoader.exists(prop_path):
			$Propulsor/PropulsorSprite.texture = load(prop_path)

	if skin_data.has("canon"):
		var canon_val = skin_data["canon"]
		if canon_val is int:
			canon_path = "res://Gres/Assets/player/canon/canon_%d.png" % max(canon_val, 1)
		elif canon_val is String:
			canon_path = canon_val
		if canon_path != "" and ResourceLoader.exists(canon_path):
			$Canon/CanonSprite.texture = load(canon_path)

	if skin_data.has("body_colors") and $BodySprite.material is ShaderMaterial:
		var c = skin_data["body_colors"]
		$BodySprite.material.set_shader_parameter("red_factor",   c[0] if c.size() > 0 else 1.0)
		$BodySprite.material.set_shader_parameter("green_factor", c[1] if c.size() > 1 else 1.0)
		$BodySprite.material.set_shader_parameter("blue_factor",  c[2] if c.size() > 2 else 1.0)
		$BodySprite.material.set_shader_parameter("saturation",   c[3] if c.size() > 3 else 1.0)
		$BodySprite.material.set_shader_parameter("brightness",   c[4] if c.size() > 4 else 0.0)
		$BodySprite.material.set_shader_parameter("contrast",     c[5] if c.size() > 5 else 1.0)
		$BodySprite.material.set_shader_parameter("hue_shift",    c[6] if c.size() > 6 else 0.0)
		$BodySprite.material.set_shader_parameter("gamma",        c[7] if c.size() > 7 else 1.0)

	if skin_data.has("wings_colors") and $Wings/WingsSprite.material is ShaderMaterial:
		var c = skin_data["wings_colors"]
		$Wings/WingsSprite.material.set_shader_parameter("red_factor",   c[0] if c.size() > 0 else 1.0)
		$Wings/WingsSprite.material.set_shader_parameter("green_factor", c[1] if c.size() > 1 else 1.0)
		$Wings/WingsSprite.material.set_shader_parameter("blue_factor",  c[2] if c.size() > 2 else 1.0)
		$Wings/WingsSprite.material.set_shader_parameter("saturation",   c[3] if c.size() > 3 else 1.0)
		$Wings/WingsSprite.material.set_shader_parameter("brightness",   c[4] if c.size() > 4 else 0.0)
		$Wings/WingsSprite.material.set_shader_parameter("contrast",     c[5] if c.size() > 5 else 1.0)
		$Wings/WingsSprite.material.set_shader_parameter("hue_shift",    c[6] if c.size() > 6 else 0.0)
		$Wings/WingsSprite.material.set_shader_parameter("gamma",        c[7] if c.size() > 7 else 1.0)

	if skin_data.has("prop_colors") and $Propulsor/PropulsorSprite.material is ShaderMaterial:
		var c = skin_data["prop_colors"]
		$Propulsor/PropulsorSprite.material.set_shader_parameter("red_factor",   c[0] if c.size() > 0 else 1.0)
		$Propulsor/PropulsorSprite.material.set_shader_parameter("green_factor", c[1] if c.size() > 1 else 1.0)
		$Propulsor/PropulsorSprite.material.set_shader_parameter("blue_factor",  c[2] if c.size() > 2 else 1.0)
		$Propulsor/PropulsorSprite.material.set_shader_parameter("saturation",   c[3] if c.size() > 3 else 1.0)
		$Propulsor/PropulsorSprite.material.set_shader_parameter("brightness",   c[4] if c.size() > 4 else 0.0)
		$Propulsor/PropulsorSprite.material.set_shader_parameter("contrast",     c[5] if c.size() > 5 else 1.0)
		$Propulsor/PropulsorSprite.material.set_shader_parameter("hue_shift",    c[6] if c.size() > 6 else 0.0)
		$Propulsor/PropulsorSprite.material.set_shader_parameter("gamma",        c[7] if c.size() > 7 else 1.0)

	print("[MP] Skin applicata per peer ", get_multiplayer_authority())

func _ready() -> void:
	mp_peer_id     = get_multiplayer_authority()
	is_local_player = is_multiplayer_authority()
	mp_max_hp      = GameModes.get_max_hp_for_mode(GameModes.current_mode)
	mp_synced_hp   = mp_max_hp
	mp_max_stamina = Global.player_max_stamina
	mp_stamina     = Global.player_stamina
	progression_hp = GameModes.HP_PROGRESSION if GameModes.is_progression_mode() else mp_max_hp

	add_to_group("player")

	var shader = preload("res://Gres/Shaders/ColorShader.gdshader")

	var mat_body = ShaderMaterial.new()
	mat_body.shader = shader
	$BodySprite.material = mat_body

	var mat_wings = ShaderMaterial.new()
	mat_wings.shader = shader
	$Wings/WingsSprite.material = mat_wings

	var mat_prop = ShaderMaterial.new()
	mat_prop.shader = shader
	$Propulsor/PropulsorSprite.material = mat_prop

	var mat_canon = ShaderMaterial.new()
	mat_canon.shader = shader
	$Canon/CanonSprite.material = mat_canon

	var my_skin_data = {
		"body":   "res://Gres/Assets/player/body/body_%d.png"    % max(Global.texture_body, 1),
		"wings":  "res://Gres/Assets/player/wings/wing_%d.png"   % max(Global.texture_wing, 1),
		"prop":   "res://Gres/Assets/player/propuls/prop_%d.png" % max(Global.texture_prop, 1),
		"canon":  "res://Gres/Assets/player/canon/canon_%d.png"  % Global.texture_canon,
		"body_colors":  [Global.body_red_factor, Global.body_green_factor, Global.body_blue_factor,
						 Global.body_saturation, Global.body_brightness, Global.body_contrast,
						 Global.body_hue_shift, Global.body_gamma],
		"wings_colors": [Global.wings_red_factor, Global.wings_green_factor, Global.wings_blue_factor,
						 Global.wings_saturation, Global.wings_brightness, Global.wings_contrast,
						 Global.wings_hue_shift, Global.wings_gamma],
		"prop_colors":  [Global.prop_red_factor, Global.prop_green_factor, Global.prop_blue_factor,
						 Global.prop_saturation, Global.prop_brightness, Global.prop_contrast,
						 Global.prop_hue_shift, Global.prop_gamma]
	}

	_apply_skin(my_skin_data)

	if is_local_player:
		await get_tree().process_frame
		_sync_skin.rpc(my_skin_data)
		print("[MP] Skin inviata a tutti i peer")
		rpc_set_player_name.rpc(GlobalSteamScript.player_name)

	if GameModes.is_progression_mode():
		setup_progression_weapon(0)

	if not is_local_player:
		if camera_ring:
			camera_ring.current = false
			camera_ring.enabled = false
		return

	unlocker_stats()
	start_possession_glitch()

	if can_zoom:
		var tw = create_tween()
		if camera_ring:
			camera_ring.zoom = Vector2(6, 6)
			tw.tween_property(camera_ring, "zoom", Vector2(1,1), 1.5).set_ease(Tween.EASE_OUT)

	Global.player         = self
	Global.canon          = $Canon
	Global.player_hp      = mp_synced_hp
	Global.player_max_hp  = mp_max_hp

	if camera_ring:
		camera_ring.current = true

	if not GlobalWeapons.gun_found.is_connected(_on_gun_found):
		GlobalWeapons.gun_found.connect(_on_gun_found)
	
	# Connect to canon's weapon_equipped signal to update local texture
	if $Canon:
		$Canon.weapon_equipped.connect(_on_weapon_equipped)

	pulse_timer = Timer.new()
	add_child(pulse_timer)
	pulse_timer.wait_time = 0.08
	pulse_timer.timeout.connect(_on_pulse)
	pulse_timer.start()
	set_process(true)
	queue_redraw()

@rpc("reliable", "call_local")
func _sync_hue(hue: float):
	if not is_local_player:
		_set_hue(hue)

func _set_hue(hue: float):
	$BodySprite.material.set_shader_parameter("hue_shift", hue)
	$Wings/WingsSprite.material.set_shader_parameter("hue_shift", hue)
	$Propulsor/PropulsorSprite.material.set_shader_parameter("hue_shift", hue)

@rpc("reliable", "call_local")
func _sync_appearance(hue: float):
	if not is_local_player:
		_set_hue(hue)

func _on_pulse():
	pulse_scale = 1.0 + (void_stacks / float(max_stacks)) * 0.4
	queue_redraw()

func _process(delta):
	if is_local_player:
		Global.shootX = $Canon/Muzzle.global_position.x
		Global.shootY = $Canon/Muzzle.global_position.y
	rotation_angle += delta * 1.2
	queue_redraw()

	if is_eclipse_active:
		eclipse_timer    += delta
		eclipse_rotation += delta * 1.5
		queue_redraw()

func _on_gun_found(weapon_name: String, rarity: String) -> void:
	_fx_weapon_pickup(rarity)
	_skill_cooldown_max = _cd_for_weapon(GlobalWeapons.current_weapon.get("projectile_type",""))

func _on_weapon_equipped(weapon_name: String, rarity: String, weapon_data: Dictionary) -> void:
	# Update local canon texture when weapon changes
	if weapon_data.has("texture") and weapon_data["texture"] != "":
		$Canon/CanonSprite.texture = load(weapon_data["texture"])
	print("[MP] Weapon equipped locally: ", weapon_name)

# ==============================================================
# PROGRESSION MODE - GUN GAME
# ==============================================================

func setup_progression_weapon(index: int = 0) -> void:
	_set_progression_weapon_index(index)

func upgrade_weapon() -> void:
	_set_progression_weapon_index(progression_weapon_index + 1)

func downgrade_weapon() -> void:
	_set_progression_weapon_index(progression_weapon_index - 1)

func is_at_final_progression_weapon() -> bool:
	return progression_weapon_index >= GameModes.PROGRESSION_WEAPON_ORDER.size() - 1

func get_progression_weapon_name() -> String:
	var safe_index: int = clamp(progression_weapon_index, 0, GameModes.PROGRESSION_WEAPON_ORDER.size() - 1)
	return GameModes.PROGRESSION_WEAPON_ORDER[safe_index]

func get_progression_step_text() -> String:
	return "%d/%d" % [progression_weapon_index + 1, GameModes.PROGRESSION_WEAPON_ORDER.size()]

@rpc("any_peer", "call_local", "reliable")
func rpc_set_progression_weapon(index: int) -> void:
	_set_progression_weapon_index(index)

@rpc("any_peer", "call_local", "reliable")
func rpc_set_progression_hp(hp: float) -> void:
	progression_hp = clamp(hp, 50.0, 500.0)
	if is_multiplayer_authority():
		mp_synced_hp = min(mp_synced_hp, progression_hp)
		Global.player_hp = mp_synced_hp

func _set_progression_weapon_index(index: int) -> void:
	if GameModes.PROGRESSION_WEAPON_ORDER.is_empty():
		return
	progression_weapon_index = clamp(index, 0, GameModes.PROGRESSION_WEAPON_ORDER.size() - 1)
	var weapon_name := get_progression_weapon_name()
	var rarity := _get_weapon_default_rarity(weapon_name)
	current_weapon = weapon_name
	if canon and canon.has_method("equip_weapon"):
		canon.equip_weapon(weapon_name, rarity)
	_skill_cooldown_max = _cd_for_weapon(GlobalWeapons.current_weapon.get("projectile_type", ""))
	emit_signal(
		"progression_weapon_changed",
		get_multiplayer_authority(),
		weapon_name,
		progression_weapon_index,
		GameModes.PROGRESSION_WEAPON_ORDER.size()
	)

func _get_weapon_default_rarity(weapon_name: String) -> String:
	if GlobalWeapons.weapons.has(weapon_name):
		var rarities: Array = GlobalWeapons.weapons[weapon_name].keys()
		if not rarities.is_empty():
			return str(rarities[0])
	return "common"

func _cd_for_weapon(ptype: String) -> float:
	return {
		"nullborn_sovereign_shot": 20.0, "oblivion_herald_shot": 18.0,
		"voidfather_eclipse_shot": 40.0, "chrono_ripper_shot": 25.0,
		"soul_leech_shot": 18.0,         "dimensional_swap_shot": 20.0,
		"storm_caller_shot": 22.0,       "graviton_pulse_shot": 25.0,
		"proximity_mine_shot": 15.0,     "necro_pulse_shot": 30.0,
		"rift_blade_shot": 10.0,         "mind_fracture_shot": 30.0,
		"gaea_core_main": 25.0,          "blood_nexus_main": 20.0,
		"wall_caster_shot": 15.0,        "phantom_echo_shot": 18.0,
	}.get(ptype, 20.0)

func immune() -> void:
	if Global.player_immunity and can_immune:
		can_immune = false
		var effect = load("res://Gres/Scenes/Effects/immune_shield.tscn").instantiate()
		get_parent().add_child(effect)
		effect.global_position = global_position
		$TimeManager/ImmuneShieldCD.wait_time = Global.player_immunity_time
		$TimeManager/ImmuneShieldCD.start()

# ==============================================================
# PHYSICS PROCESS
# ==============================================================
func _physics_process(delta: float) -> void:
	_update_buffs(delta)
	_process_passives(delta)

	if not is_local_player:
		return

	# Sync stamina for remote UI display
	mp_max_stamina = Global.player_max_stamina
	mp_stamina = Global.player_stamina

	if Input.is_key_pressed(KEY_CTRL):
		global_position = get_global_mouse_position()

	handle_input()
	Global.PlayerX = position.x
	Global.PlayerY = position.y

	_process_skill_cooldown(delta)

	if GlobalWeapons.current_weapon.get("projectile_type","") == "chrono_ripper_shot" and is_moving:
		_chrono_img_timer += delta
		if _chrono_img_timer >= 0.05:
			_chrono_img_timer = 0.0
			_spawn_chrono_afterimage()

	if GlobalWeapons.current_weapon.get("projectile_type","") == "aegis_storm_shot":
		_handle_aegis_storm(delta)

	if GlobalStats.time_slow and can_time_slow:
		can_time_slow = false
		$Distort/start.play("dist")
		Global.slow_factor = 0.2
		$TimeManager/TimeSlowCD.wait_time = GlobalStats.time_slow_time
		$TimeManager/TimeSlowCD.start()

	immune()

	if can_move:   process_movement(delta)
	if can_dash:   process_dash(delta)
	if can_rotate: rotate_towards_mouse()

	if Input.is_action_just_pressed("skill_1"):
		_trigger_active_skill()

	if GlobalWeapons.current_weapon.get("projectile_type","") != "aegis_storm_shot":
		if can_shoot and is_shooting:
			can_shoot = false
			$TimeManager/ShootFreeze.wait_time = Global.shoot_freeze
			$TimeManager/ShootFreeze.start()
			_fx_shoot(GlobalWeapons.current_weapon.get("rarity", "common"))
			canon.shoot()

func _handle_aegis_storm(delta: float) -> void:
	_aegis_max_charge = GlobalWeapons.current_weapon.get("max_charge_time", 5.0)
	if Input.is_action_pressed("shoot"):
		if not _aegis_charging:
			_aegis_charging    = true
			_aegis_charge_time = 0.0
			apply_buff("aegis_shield", _aegis_max_charge + 1.0)
		_aegis_charge_time = min(_aegis_charge_time + delta, _aegis_max_charge)
		if is_instance_valid(_aegis_shield_node):
			var pct := _aegis_charge_time / _aegis_max_charge
			_aegis_shield_node.scale = Vector2.ONE * (0.8 + pct * 0.6)
	elif _aegis_charging:
		_aegis_charging = false
		remove_buff("aegis_shield")
		_fire_aegis_burst()

func _fire_aegis_burst() -> void:
	var wd         = GlobalWeapons.current_weapon
	var max_charge = wd.get("max_charge_time", 5.0)
	var min_b      = wd.get("min_bullets", 1)
	var max_b      = wd.get("max_bullets", 20)
	var pct        = _aegis_charge_time / max_charge
	var count      = clamp(int(lerp(float(min_b), float(max_b), pct)), min_b, max_b)
	var is_full    = pct >= 0.99

	if camera_ring: camera_ring.shake(Global.cam_shake * (0.3 + pct * 1.5))
	if is_full: _fx_screen_flash(Color(0.5, 0.3, 1.0, 0.35))

	var bs = load("res://Gres/Scenes/weapons/bullet/player_bullet.tscn")
	for _i in range(count):
		var angle := 0.0 if count == 1 else randf() * TAU
		var bd    := wd.duplicate(true)
		if is_full: bd["damage"] = int(wd.get("damage", 95.0) * 1.6)
		var b = bs.instantiate()
		get_parent().add_child(b)
		b.global_position = canon.global_position
		b.init_from_weapon(bd, Vector2(cos(angle), sin(angle)), self, false)
		b.target = b.find_nearest_enemy() if is_full else null
		await get_tree().create_timer(0.02).timeout
	_aegis_charge_time = 0.0

func take_damage(amount: float) -> void:
	print("[MP_Player] take_damage per ", name, " danno: ", amount)
	if not can_be_damaged:
		print("  -> can_be_damaged false")
		return
	if mp_is_dead:
		print("  -> già morto")
		return
	
	if has_node("Audio/hurt"):
		$Audio/hurt.play()
	
	var effect = load("res://Gres/Scenes/Effects/expl_p.tscn").instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
	hurt_flash(amount)
	
	mp_synced_hp -= amount
	print("  -> mp_synced_hp ora: ", mp_synced_hp)
	
	if is_local_player:
		Global.player_hp = mp_synced_hp
	
	if mp_synced_hp <= 0:
		mp_synced_hp = 0
		print("  -> MUORE! Chiamo on_player_dead()")
		on_player_dead()

func on_player_dead() -> void:
	if mp_is_dead: return
	mp_is_dead       = true
	can_be_damaged   = false   # FIX: invincibile subito, prima di qualsiasi RPC

	# FIX: In modalità PvP POINT salta la logica di respawn single-player
	# (GlobalStats.respawn, ecc.) — il respawn lo gestisce l'Arena.
	# Controlla se siamo in una partita multiplayer attiva.
	var in_pvp_match: bool = multiplayer.multiplayer_peer != null and \
							 multiplayer.get_unique_id() != 1 or multiplayer.is_server()

	if not in_pvp_match:
		# Logica single-player originale
		if not Global.player_dead and Global.player_hp <= 0:
			Global.player_hp = 0
			Global.update_mission_progress("die_time_1", 1)
			Global.update_mission_progress("die_time_2", 1)
			Global.update_mission_progress("die_time_3", 1)
			if GlobalStats.respawn >= 50:
				immune()
				Global.player_hp = Global.player_max_hp / 2
				Global.player_stamina = Global.player_max_stamina
				mp_is_dead = false
				can_be_damaged = true
				return
			elif randf() < GlobalStats.respawn / 100.0:
				immune()
				Global.player_hp = Global.player_max_hp / 8
				mp_is_dead = false
				can_be_damaged = true
				return
			Global.player_dead = true
			GlobalStats.died_times += 1

	notify_player_dead.rpc(mp_peer_id)
	rpc_notify_death.rpc()

func _mp_death_fx() -> void:
	_death_tweens.clear()
	var parts := [
		get_node_or_null("BodySprite"),
		get_node_or_null("Wings/WingsSprite"),
		get_node_or_null("Propulsor/PropulsorSprite"),
		get_node_or_null("Canon/CanonSprite"),
	]
	for part in parts:
		if not is_instance_valid(part):
			continue
		var rand_dir  := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var target_pos = part.global_position + rand_dir * randf_range(80.0, 160.0)
		var tw := create_tween()
		tw.tween_property(part, "global_position", target_pos,
			randf_range(1.0, 2.2)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var tw_fade := create_tween()
		tw_fade.tween_property(part, "modulate:a", 0.0, 2.5).set_delay(0.5)
		_death_tweens.append(tw)
		_death_tweens.append(tw_fade)

func handle_input() -> void:
	input_direction = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()
	if input_direction != Vector2.ZERO:
		last_input_direction = input_direction
		is_moving = true
		$run_fire.play("move")
	else:
		is_moving = false
		$run_fire.play("idle")
	is_shooting = Input.is_action_pressed("shoot")
	is_dashing  = Input.is_action_just_pressed("dash")

func process_movement(delta: float) -> void:
	var speed_mult := 1.0
	if has_buff("chrono_speed"):      speed_mult = max(speed_mult, 1.2)
	if has_meta("sovereign_active"): speed_mult *= 1.3
	if Global._dash_timer > 0:
		velocity = last_input_direction * Global.dash_speed
		move_and_slide()
		return
	var target_velocity: Vector2
	if input_direction != Vector2.ZERO:
		target_velocity = input_direction * Global.move_speed * speed_mult
		velocity = velocity.lerp(target_velocity, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
	move_and_slide()

func process_dash(delta: float) -> void:
	if is_dashing and Global._dash_timer <= 0 and Global.player_stamina >= 10:
		Global.update_mission_progress("dash_uses", 1)
		Global.player_stamina -= 0 if randi() % 100 < Global.chance_not_consum_stamina \
			else (10 if !Global.stamina_regen_skill else 8)
		if Global.player_stamina <= 0: Global.player_stamina = 0
		Global._dash_timer          = Global.dash_duration
		Global._dash_cooldown_timer = Global.dash_cooldown
		_fx_dash()
	if Global._dash_timer > 0:          Global._dash_timer -= delta
	else:                                Global._dash_timer  = 0.0
	if Global._dash_cooldown_timer > 0: Global._dash_cooldown_timer -= delta

func rotate_towards_mouse() -> void:
	look_at(get_global_mouse_position())

func get_current_velocity() -> Vector2:
	return velocity

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var min_d := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D): continue
		var d := global_position.distance_to(e.global_position)
		if d < min_d:
			min_d = d
			nearest = e
	return nearest

# ==============================================================
# TIMER CALLBACKS
# ==============================================================
func _on_shoot_freeze_timeout() -> void:
	can_shoot = true

func _on_immune_shield_cd_timeout() -> void:
	Global.player_immunity = false
	can_immune = true

func _on_time_slow_cd_timeout() -> void:
	GlobalStats.time_slow = false
	can_time_slow = true
	Global.slow_factor = 1.0

func _on_timer_stam_reg_timeout() -> void:
	if Global.player_stamina < Global.player_max_stamina:
		Global.player_stamina += 4 if !Global.stamina_regen_skill else 6
	$TimeManager/TimerStamReg.wait_time = 10 if !Global.stamina_regen_skill else 2
	$TimeManager/TimerStamReg.start()

func _on_timer_hp_reg_timeout() -> void:
	if Global.player_hp < Global.player_max_hp:
		Global.player_hp += Global.player_hp_reg
	$TimeManager/TimerHPReg.start()

func _on_shield_reflect_area_entered(area: Area2D) -> void:
	if _aegis_shield_active:
		_on_aegis_deflect(area)
