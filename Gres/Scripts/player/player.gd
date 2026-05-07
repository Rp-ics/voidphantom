extends CharacterBody2D

signal player_died

# ==============================================================
# FLAGS DI CONTROLLO
# ==============================================================
@export var can_move:      bool = true
@export var can_shoot:     bool = true
@export var can_dash:      bool = true
@export var can_rotate:    bool = true
@export var can_be_damaged:bool = true
@export var can_interact:  bool = true
@export var can_immune:    bool = true
@export var can_time_slow: bool = true
@export var can_zoom:      bool = true
@export var current_weapon: String = "Pulse Blaster"

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
var _aegis_charging:     bool   = false
var _aegis_charge_time:  float  = 0.0
var _aegis_max_charge:   float  = 5.0
var _aegis_shield_active:bool   = false
var _aegis_shield_node:  Node2D = null
var deflect_percent := 100

# ==============================================================
# SKILL ATTIVA — COOLDOWN
# ==============================================================
var _skill_ready:        bool  = true
var _skill_cooldown:     float = 0.0
var _skill_cooldown_max: float = 20.0

# Nodo draw che visualizza il cooldown sopra la nave
var _cd_hud_node: Node2D = null

# ==============================================================
# ANIMAZIONI — NODI AURA PERSISTENTI
# ==============================================================
var _aura_node:      Node2D = null   # aura generica (sovereign, eclipse…)
var _burn_fx_node:   Node2D = null   # fiamme burn
var _inv_tween:      Tween  = null   # lampeggio invincibilità
var _overheal_tween: Tween  = null   # lampeggio overheal

# Salva il modulate originale prima di eclipse
var _pre_eclipse_modulate: Color = Color.WHITE

# ==============================================================
# SISTEMA BUFF / DEBUFF
# ==============================================================
var active_buffs: Array = []

# Variabili per l'effetto
var void_stacks = 0
var max_stacks = 50
var pulse_scale = 1.0
var rotation_angle = 0.0
var pulse_timer : Timer

var is_eclipse_active : bool = false
var eclipse_timer : float = 0.0   # per animazione progressiva
var eclipse_rotation : float = 0.0


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

# --------------------------------------------------------------
func _buff_on_apply(buff: Dictionary) -> void:
	match buff.name:

		"frozen":
			can_move   = false
			can_rotate = false
			# FX: cristalli procedurali + modulate blu ghiaccio
			_fx_tween_modulate(Color(0.4, 0.85, 1.0, 1.0), 0.2)
			_fx_crystal_burst(Color(0.7, 0.95, 1.0, 0.8))
			# ==================================================
			# IMPLEMENTA TU: se hai un GPUParticles2D chiamato
			# $FrozenParticles, abilitalo qui:
			# if has_node("FrozenParticles"): $FrozenParticles.emitting = true
			# ==================================================

		"invincible":
			can_be_damaged = false
			# FX: lampeggio wireframe — Tween modulate:a loop
			if is_instance_valid(_inv_tween): _inv_tween.kill()
			_inv_tween = create_tween().set_loops()
			_inv_tween.tween_property(self, "modulate:a", 0.2, 0.07)
			_inv_tween.tween_property(self, "modulate:a", 1.0, 0.07)

		"burn":
			# FX: fiamme procedurali (nodo draw interno)
			if not is_instance_valid(_burn_fx_node):
				_burn_fx_node = _BurnFX.new()
				add_child(_burn_fx_node)
			# ==================================================
			# IMPLEMENTA TU: se hai GPUParticles2D $BurnParticles:
			# if has_node("BurnParticles"): $BurnParticles.emitting = true
			# ==================================================

		"aegis_shield":
			_aegis_shield_active = true
			_spawn_aegis_shield_visual()

		"soul_overheal":
			# FX: bordo dorato pulsante (Tween loop)
			if is_instance_valid(_overheal_tween): _overheal_tween.kill()
			_overheal_tween = create_tween().set_loops()
			_overheal_tween.tween_property(self, "modulate", Color(1.5, 1.2, 0.2, 1.0), 0.4)
			_overheal_tween.tween_property(self, "modulate", Color(1.0, 0.8, 0.1, 1.0), 0.4)

		"chrono_speed":
			# FX: scia afterimage cyan — gestita ogni frame in _physics_process
			pass

		# --- Skill attive: aure procedurali ---
		"sovereign_active":
			_replace_aura(_SovereignAura.new())
			_fx_ring_burst(Color(0.5, 0.9, 1.0, 0.8), 600.0, 0.6)
			_fx_screen_flash(Color(0.5, 0.9, 1.0, 0.25))
			$CameraRing.shake(0.8)

		"herald_judgment":
			_replace_aura(_HeraldAura.new())
			_fx_ring_burst(Color(0.5, 0.0, 1.0, 0.7), 500.0, 0.55)
			_fx_screen_flash(Color(0.3, 0.0, 0.6, 0.2))
			$CameraRing.shake(0.65)

		"eclipse_active":
			_pre_eclipse_modulate = modulate
			_fx_tween_modulate(Color(0.05, 0.0, 0.15, 1.0), 0.4)
			_replace_aura(_EclipseAura.new())
			_fx_screen_flash(Color(0.0, 0.0, 0.0, 0.7))
			$CameraRing.shake(1.2)

		"chrono_burst_active":
			_fx_ring_burst(Color(0.0, 1.0, 0.85, 0.75), 800.0, 0.5)
			_fx_screen_flash(Color(0.0, 0.7, 1.0, 0.2))
			$CameraRing.shake(0.55)

		"storm_apex_active":
			_fx_ring_burst(Color(1.0, 1.0, 0.2, 0.7), 400.0, 0.45)
			_fx_screen_flash(Color(1.0, 1.0, 0.0, 0.15))
			$CameraRing.shake(0.6)

		"gaia_pulse_active":
			_fx_ring_burst(Color(0.2, 1.0, 0.3, 0.85), 900.0, 0.7)
			_fx_screen_flash(Color(0.0, 0.8, 0.2, 0.3))
			$CameraRing.shake(1.0)

		"echo_storm_active":
			_fx_ring_burst(Color(0.5, 0.5, 1.0, 0.65), 300.0, 0.4)

		"necro_surge_active":
			_fx_ring_burst(Color(0.0, 1.0, 0.4, 0.65), 300.0, 0.5)

		"mass_swap_active":
			_fx_screen_flash(Color(0.6, 0.2, 1.0, 0.3))
			$CameraRing.shake(0.7)

func activate_eclipse():
	is_eclipse_active = true
	eclipse_timer = 0.0
	
	# I tuoi effetti esistenti
	_pre_eclipse_modulate = modulate
	_fx_tween_modulate(Color(0.05, 0.0, 0.15, 1.0), 0.4)
	_replace_aura(_EclipseAura.new())
	_fx_screen_flash(Color(0.0, 0.0, 0.0, 0.7))
	$CameraRing.shake(1.2)
	
	set_process(true)        # per aggiornare l'animazione
	queue_redraw()           # forza il primo disegno
	
func deactivate_eclipse():
	is_eclipse_active = false
	set_process(false)  # o lascia true ma controlli dentro _process
	queue_redraw()
	

# --------------------------------------------------------------
func _buff_on_remove(buff: Dictionary) -> void:
	match buff.name:

		"frozen":
			can_move   = true
			can_rotate = true
			_fx_tween_modulate(Color.WHITE, 0.3)
			# ==================================================
			# IMPLEMENTA TU: disabilita $FrozenParticles
			# if has_node("FrozenParticles"): $FrozenParticles.emitting = false
			# ==================================================

		"invincible":
			can_be_damaged = true
			if is_instance_valid(_inv_tween): _inv_tween.kill()
			modulate.a = 1.0

		"burn":
			if is_instance_valid(_burn_fx_node):
				_burn_fx_node.queue_free()
				_burn_fx_node = null
			# ==================================================
			# IMPLEMENTA TU: disabilita $BurnParticles
			# if has_node("BurnParticles"): $BurnParticles.emitting = false
			# ==================================================

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


# ==============================================================
# AEGIS SHIELD — spawn / destroy
# ==============================================================
func _spawn_aegis_shield_visual() -> void:
	# ==================================================
	# IMPLEMENTA TU: crea la scena aegis_shield.tscn con:
	#   - AnimatedSprite2D che ruota (animation "idle")
	#   - GPUParticles2D radiale colore viola/bianco
	#   - Area2D circolare r=60px con CollisionShape2D
	#     i cui body_entered chiamano Global.player._on_aegis_deflect(body)
	# Poi decommentare:
	if not ResourceLoader.exists("res://Gres/Scenes/Effects/shield_aeg.tscn"): return
	if is_instance_valid(_aegis_shield_node): return
	_aegis_shield_node = load("res://Gres/Scenes/Effects/shield_aeg.tscn").instantiate()
	add_child(_aegis_shield_node)
	# ==================================================
	
func _destroy_aegis_shield_visual() -> void:
	if is_instance_valid(_aegis_shield_node):
		# ==================================================
		# IMPLEMENTA TU: se aegis_shield.tscn ha AnimationPlayer
		# con "despawn": $aegis_shield_node/AnimationPlayer.play("despawn")
		# poi attendi il segnale animation_finished prima di queue_free.
		# ==================================================
		_aegis_shield_node.queue_free()
		_aegis_shield_node = null

func _on_aegis_deflect(enemy_bullet: Node) -> void:
	if not _aegis_shield_active: return
	
	# ✅ Solo il meta tag per evitare doppie deflessioni
	if enemy_bullet.has_meta("already_deflected"):
		return
	
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

# ==============================================================
# SKILL ATTIVA — SISTEMA CENTRALE
# ==============================================================
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
		"aegis_storm_shot":         pass   # gestita da hold/release
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
			# FX: skill pronta — flash verde + ring piccolo
			var tw = create_tween().set_parallel(true)
			tw.tween_property(self, "modulate", Color(0.3, 1.0, 0.5, 1.0), 0.08)
			tw.tween_property(self, "modulate", Color.WHITE, 0.4).set_delay(0.08)
			_fx_ring_burst(Color(0.3, 1.0, 0.5, 0.5), 120.0, 0.3)


# ==============================================================
# IMPLEMENTAZIONE SKILL ATTIVE
# ==============================================================

func _skill_sovereign_decree() -> void:
	_skill_cooldown_max = 20.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("apply_buff"): e.apply_buff("frozen", 4.0)
	apply_buff("sovereign_active", 4.0)
	apply_buff("invincible", 4.0)
	# player_bullet legge il meta "sovereign_active" → danno x3
	set_meta("sovereign_active", true)
	get_tree().create_timer(4.0).timeout.connect(func():
		if has_meta("sovereign_active"): remove_meta("sovereign_active")
	)

func _skill_herald_judgment() -> void:
	_skill_cooldown_max = 18.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("apply_buff"): e.apply_buff("marked", 10.0)
	apply_buff("herald_judgment", 10.0)
	# player_bullet legge "herald_judgment_active" → chain 70% sugli altri marked
	set_meta("herald_judgment_active", true)
	get_tree().create_timer(10.0).timeout.connect(func():
		if has_meta("herald_judgment_active"): remove_meta("herald_judgment_active")
	)

func _skill_the_eclipse() -> void:
	_skill_cooldown_max = 40.0
	apply_buff("eclipse_active", 8.0)
	apply_buff("invincible", 8.0)
	set_meta("eclipse_no_hp_cost", true)
	# player_bullet legge "eclipse_no_hp_cost" → VOIDFATHER non costa HP
	# ==================================================
	# IMPLEMENTA TU: imposta Engine.time_scale = 0.5 per 8s per
	# dare l'effetto rallentamento del tempo all'Eclipse:
	# Engine.time_scale = 0.5
	# get_tree().create_timer(8.0 / 0.5).timeout.connect(func(): Engine.time_scale = 1.0)
	# ==================================================

func _skill_chrono_burst() -> void:
	_skill_cooldown_max = 25.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("apply_buff"): e.apply_buff("frozen", 2.0)
	apply_buff("chrono_burst_active", 2.0)
	set_meta("chrono_burst_active", true)
	get_tree().create_timer(2.0).timeout.connect(func():
		if has_meta("chrono_burst_active"): remove_meta("chrono_burst_active")
	)

func _skill_soul_drain() -> void:
	_skill_cooldown_max = 18.0
	var target := _find_nearest_enemy()
	if not is_instance_valid(target): return
	_fx_beam_to_target(target.global_position, Color(0.8, 0.0, 0.1))
	$CameraRing.shake(0.35)
	for _i in range(3):
		await get_tree().create_timer(1.0).timeout
		if not is_instance_valid(target) or not is_instance_valid(self): break
		var drain = target.get("hp") if target.get("hp") != null else 0.0
		drain *= 0.08
		if target.has_method("take_damage"): target.take_damage(drain, self)
		Global.player_hp = min(Global.player_hp + drain, Global.player_max_hp)
		# FX: heal pulse dorato
		var tw = create_tween().set_parallel(true)
		tw.tween_property(self, "modulate", Color(1.0, 0.7, 0.0, 1.0), 0.05)
		tw.tween_property(self, "modulate", Color.WHITE, 0.3).set_delay(0.05)
		tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_BACK)
		tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_delay(0.08)

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
	# player_bullet legge "storm_apex_active" → ogni proiettile è multiplo x2
	get_tree().create_timer(6.0).timeout.connect(func():
		if has_meta("storm_apex_active"): remove_meta("storm_apex_active")
	)

func _skill_graviton_collapse() -> void:
	_skill_cooldown_max = 25.0
	# player_bullet.gd usa "graviton_collapse_next" → prossimo proiettile
	# diventa un black hole temporaneo da 200 raggio
	set_meta("graviton_collapse_next", true)
	_fx_ring_burst(Color(0.3, 0.0, 0.8, 0.7), 200.0, 0.4)
	$CameraRing.shake(0.5)
	# ==================================================
	# IMPLEMENTA TU in player_bullet._on_body_entered:
	# if bullet_owner.has_meta("graviton_collapse_next"):
	#   bullet_owner.remove_meta("graviton_collapse_next")
	#   _spawn_black_hole(global_position, 200.0, 3.0)
	# ==================================================

func _skill_detonate_all_mines() -> void:
	_skill_cooldown_max = 15.0
	$CameraRing.shake(0.9)
	_fx_screen_flash(Color(1.0, 0.5, 0.0, 0.25))
	for b in get_tree().get_nodes_in_group("p_bullet"):
		if b.get("projectile_type") == "proximity_mine_shot" and b.get("_is_mine"):
			if b.has_method("_mine_explode"): b._mine_explode()

func _skill_necro_surge() -> void:
	_skill_cooldown_max = 30.0
	apply_buff("necro_surge_active", 3.0)
	set_meta("necro_surge_active", true)
	# player_bullet.gd usa "necro_surge_active" → nemici uccisi per 3s
	# vengono rianimati come alleati per 8s (_become_ally)
	get_tree().create_timer(3.0).timeout.connect(func():
		if has_meta("necro_surge_active"): remove_meta("necro_surge_active")
	)

func _skill_rift_cascade() -> void:
	_skill_cooldown_max = 10.0
	$CameraRing.shake(0.75)
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
	$CameraRing.shake(0.6)
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
	$CameraRing.shake(0.85)
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
	# ==================================================
	# IMPLEMENTA TU: crea res://Gres/Scenes/weapons/void_wall.tscn
	# con StaticBody2D + CollisionPolygon2D (rettangolo 20x120px)
	# e Sprite2D con shader glow. Poi decommentare:
	var wall = load("res://Gres/Scenes/Effects/void_wall.tscn").instantiate()
	get_tree().current_scene.add_child(wall)
	wall.global_position = global_position + transform.x * 80.0
	wall.rotation = rotation
	get_tree().create_timer(dur).timeout.connect(func(): if is_instance_valid(wall): wall.queue_free())
	# ==================================================

func _skill_echo_storm() -> void:
	_skill_cooldown_max = 18.0
	apply_buff("echo_storm_active", 4.0)
	set_meta("echo_storm_active", true)
	# player_bullet.gd usa "echo_storm_active" → ogni proiettile spawna
	# una copia fantasma identica con 50% danno dopo 0.3s
	get_tree().create_timer(4.0).timeout.connect(func():
		if has_meta("echo_storm_active"): remove_meta("echo_storm_active")
	)


# ==============================================================
# SKILL PASSIVE — AGGIORNATE OGNI FRAME
# ==============================================================
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
	# +30% velocità quando almeno 1 nemico è frozen
	var any_frozen := false
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("has_buff") and e.has_buff("frozen"):
			any_frozen = true; break
	if any_frozen and not has_buff("chrono_speed"):
		apply_buff("chrono_speed", 0.5)

func _passive_soul_leech() -> void:
	# Se HP > max (overheal), attiva scudo dorato
	if Global.player_hp > Global.player_max_hp and not has_buff("soul_overheal"):
		apply_buff("soul_overheal", 999.0)
	elif Global.player_hp <= Global.player_max_hp and has_buff("soul_overheal"):
		remove_buff("soul_overheal")

func _passive_chrono() -> void:
	# +20% velocità quando nemici slowed
	var any_slowed := false
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_method("has_buff") and e.has_buff("slowed"):
			any_slowed = true; break
	if any_slowed and not has_buff("chrono_speed"):
		apply_buff("chrono_speed", 0.3)

func _passive_storm() -> void:
	# THUNDERCLAP gestito in player_bullet._apply_chain_lightning
	pass

func _passive_voidfather() -> void:
	# Leggi gli stack da dove li memorizzi (es. meta, variabile globale)
	var stacks = get_meta("void_empowerment_stacks", 0)
	void_stacks = clamp(stacks, 0, max_stacks)
	queue_redraw()

func _draw():
	var center = Vector2.ZERO   # coordinate locali (attorno al player)
	
	# --------------------------------------------
	# 1. EFFETTO VOID STACKS (sempre attivo se stacks > 0)
	# --------------------------------------------
	if void_stacks > 0:
		var max_radius_stack = 150.0
		var intensity = void_stacks / float(max_stacks)
		
		# Aura oscura radiale
		for i in range(5):
			var r = max_radius_stack * (0.7 + i * 0.1) * (0.8 + intensity * 0.4)
			var color = Color(0.05, 0.0, 0.1, 0.4 - i * 0.07)
			draw_circle(center, r, color)
		
		# Anello pulsante
		var ring_radius = max_radius_stack * (0.9 + sin(Time.get_ticks_msec() * 0.008) * 0.05) * pulse_scale
		draw_arc(center, ring_radius, 0, TAU, 64, Color(0.6, 0.0, 0.8, 0.9), 3.0, true)
		
		# Occhio dell'eclissi
		var eye_opening = 0.3 + intensity * 0.7
		var eye_radius = max_radius_stack * 0.4
		draw_circle(center, eye_radius * (0.5 + intensity * 0.5), Color(0, 0, 0, 1))
		draw_circle(center, eye_radius * (0.3 + intensity * 0.3), Color(0.8, 0.0, 0.9, 0.8))
		
		# Arti del vuoto
		var num_tentacles = int(void_stacks / 5)
		for i in range(num_tentacles):
			var angle_start = rotation_angle + (i * TAU / num_tentacles)
			var angle_end = angle_start + TAU / (num_tentacles * 1.8)
			var tent_radius = max_radius_stack * (0.9 + intensity * 0.3)
			draw_arc(center, tent_radius, angle_start, angle_end, 32, Color(0.5, 0.0, 0.7, 0.7 + intensity * 0.3), 5.0, false)
	
	# --------------------------------------------
	# 2. EFFETTO ECLISSE ATTIVA (sovrascrive/amplifica)
	# --------------------------------------------
	if is_eclipse_active:
		var max_radius_eclipse = 220.0
		var prog = min(eclipse_timer / 0.5, 1.0)
		
		# Aura di tenebra radiale
		for i in range(8):
			var r = max_radius_eclipse * (0.5 + i * 0.1) * (0.8 + sin(Time.get_ticks_msec() * 0.01) * 0.2)
			var alpha = 0.6 * (1.0 - i / 8.0) * prog
			draw_circle(center, r, Color(0.0, 0.0, 0.0, alpha))
		
		# Vortice di ombra
		var arms = 6
		for i in range(arms):
			var start_angle = eclipse_rotation + i * TAU / arms
			var end_angle = start_angle + TAU / (arms * 1.5)
			var radius = max_radius_eclipse * (0.8 + sin(Time.get_ticks_msec() * 0.008 + i) * 0.1)
			draw_arc(center, radius, start_angle, end_angle, 32, Color(0.4, 0.0, 0.5, 0.8), 6.0, false)
		
		# Buco nero centrale
		var core_radius = max_radius_eclipse * (0.2 + sin(eclipse_timer * 12) * 0.05) * prog
		draw_circle(center, core_radius, Color(0.0, 0.0, 0.0, 1.0))
		draw_circle(center, core_radius * 1.4, Color(0.3, 0.0, 0.6, 0.8))
		
		# Raggi di oscurità
		var num_rays = 12
		for r in range(num_rays):
			var angle = eclipse_rotation * 2 + r * TAU / num_rays
			var length = max_radius_eclipse * (0.7 + sin(Time.get_ticks_msec() * 0.015 + r) * 0.3)
			var end = center + Vector2(cos(angle), sin(angle)) * length
			draw_line(center, end, Color(0.0, 0.0, 0.0, 0.9), 4.0 + sin(Time.get_ticks_msec() * 0.02) * 2)
		
		# Effetto consumo frastagliato
		var chaos_radius = max_radius_eclipse * (0.9 + sin(eclipse_timer * 20) * 0.1)
		for p in range(36):
			var ang = p * TAU / 36 + eclipse_rotation
			var rad = chaos_radius * (0.8 + sin(ang * 5) * 0.2)
			var pos = center + Vector2(cos(ang), sin(ang)) * rad
			draw_circle(pos, 3.0 + sin(ang * 8) * 2, Color(0.1, 0.0, 0.2, 0.7))
		

func _passive_vulrath() -> void:
	# +18% fire rate sotto 40% HP
	if Global.player_hp < Global.player_max_hp * 0.4:
		if not has_meta("vulrath_boost"):
			set_meta("vulrath_boost", true)
			Global.shoot_freeze = GlobalWeapons.current_weapon.get("fire_rate", 0.38) * 0.82
			var tw = create_tween().set_parallel(true)
			tw.tween_property(self, "modulate", Color(1.5, 0.5, 0.1, 1.0), 0.15)
			tw.tween_property(self, "modulate", Color.WHITE, 0.5).set_delay(0.15)
	else:
		if has_meta("vulrath_boost"):
			remove_meta("vulrath_boost")
			Global.shoot_freeze = GlobalWeapons.current_weapon.get("fire_rate", 0.38)


# ==============================================================
# FX PROCEDURALI — FUNZIONI EPICHE
# ==============================================================

# --- Tween modulate semplice ---
func _fx_tween_modulate(col: Color, dur: float) -> void:
	create_tween().tween_property(self, "modulate", col, dur)

# --- Ring burst espandentesi (nodo draw, si auto-distrugge) ---
func _fx_ring_burst(col: Color, radius: float, dur: float) -> void:
	var ring := _RingBurst.new()
	ring.global_position = global_position
	ring.ring_color = col; ring.max_radius = radius; ring.duration = dur
	get_parent().add_child(ring)

# --- Screen flash (usa nodo FlashOverlay se esiste) ---
func _fx_screen_flash(col: Color) -> void:
	if not has_node("../FlashOverlay"): return
	var flash = get_node("../FlashOverlay")
	flash.modulate = col
	create_tween().tween_property(flash, "modulate:a", 0.0, 0.35)
	$FX_Bullets.play("eclipse")
	

# --- Shoot FX: recoil + barrel flash + squash ---
func _fx_shoot(rarity: String) -> void:
	var shake_map := {"common": 0.12, "rare": 0.25, "epic": 0.42, "legendary": 0.65}
	$CameraRing.shake(shake_map.get(rarity, 0.12))

	var tw = create_tween()
	tw.tween_property(canon, "position", Vector2(-7, 0), 0.04).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(canon, "position", Vector2.ZERO, 0.14).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)

	if is_instance_valid(canon_p):
		var tw2 = create_tween()
		tw2.tween_property(canon_p, "modulate", Color(2.5, 2.5, 1.5, 1.0), 0.03)
		tw2.tween_property(canon_p, "modulate", Color.WHITE, 0.12)

	# Squash lieve corpo
	var tw3 = create_tween()
	tw3.tween_property(body_p, "scale", Vector2(0.87, 1.16), 0.04)
	tw3.tween_property(body_p, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SPRING)

func _fx_dash() -> void:
	is_dashing = true
	
	var dash_col := _get_dash_color()
	
	# Camera shake
	$CameraRing.shake(0.9)
	
	# Squash & stretch esagerato
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(2.4, 0.1), 0.04).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	
	# Flash colore estremo su tutti gli sprite
	var tw2 = create_tween().set_parallel(true)
	for p in [body_p, wing_p, prop_p]:
		if not is_instance_valid(p): continue
		tw2.tween_property(p, "modulate", dash_col * 4.2, 0.02)
		tw2.tween_property(p, "modulate", Color.WHITE, 0.3).set_delay(0.02)
	
	# Plasma ghost burst (al posto del ring burst)
	_fx_plasma_ghost_burst(dash_col, 10, 0.5)
	
	# Flash schermo con accenno cromatico (opzionale)
	if has_node("../FlashOverlay"):
		var flash = get_node("../FlashOverlay")
		flash.modulate = Color(dash_col.r, dash_col.g, dash_col.b, 0.35)
		var ft = create_tween()
		ft.tween_property(flash, "modulate:a", 0.0, 0.2)
		if flash.material is ShaderMaterial and flash.material.has_shader_parameter("chromatic_strength"):
			ft.parallel().tween_property(flash.material, "shader_parameter/chromatic_strength", 0.3, 0.05)
			ft.tween_property(flash.material, "shader_parameter/chromatic_strength", 0.0, 0.15)
	
	# Trail di afterimage durante il dash
	_spawn_dash_trail(dash_col, 8, 0.02, 0.4)
	
	# Ghost iniziali extra
	for i in range(5):
		await get_tree().process_frame
		_spawn_dash_ghost(dash_col, 0.35, 1.0 + i * 0.05)
	
	# Fine dash (supponendo che durasse 0.3 sec circa)
	await get_tree().create_timer(0.3).timeout
	is_dashing = false


# ── Funzioni helper ──────────────────────────────────────────
func _get_dash_color() -> Color:
	# Personalizza in base ai tuoi buff
	return Color(0.2, 0.8, 1.0, 1.0)   # ciano plasma

func _spawn_dash_ghost(color: Color = Color.WHITE, duration: float = 0.25, scale_factor: float = 1.0, offset: Vector2 = Vector2.ZERO) -> Node2D:
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
		if not is_dashing:
			break
		var ghost = _spawn_dash_ghost(color, lifetime, 0.8 + i * 0.02, -dir * (10.0 + i * 5.0))
		var tw = create_tween()
		tw.tween_property(ghost, "modulate:a", 0.0, lifetime)

# --- Weapon pickup FX ---
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
	var tw2 = create_tween()
	tw2.tween_property(self, "scale", Vector2(1.3, 0.68), 0.07).set_trans(Tween.TRANS_BACK)
	tw2.tween_property(self, "scale", Vector2(0.85, 1.28), 0.08)
	tw2.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	if rarity in ["epic", "legendary"]:
		var shake_map := {"epic": 0.55, "legendary": 0.95}
		$CameraRing.shake(shake_map[rarity])
		_fx_ring_burst(rarity_col * Color(1,1,1,0.6), 180.0, 0.45)

# --- Hurt FX: squash + flash proporzionale al danno ---
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
		$CameraRing.shake(0.75)
		_fx_ring_burst(Color(1.0, 0.0, 0.0, 0.4), 90.0, 0.3)

func shake_position(intensity: float) -> void:
	position.x += randf_range(-4.0, 4.0) * intensity
	position.y += randf_range(-3.0, 3.0) * intensity

# --- Cristalli esplosivi (frozen) ---
func _fx_crystal_burst(col: Color) -> void:
	var burst := _CrystalBurst.new()
	burst.global_position = global_position
	burst.burst_color = col
	get_parent().add_child(burst)

# --- Beam verso target (soul drain) ---
func _fx_beam_to_target(target_pos: Vector2, col: Color) -> void:
	var beam := _BeamFX.new()
	beam.global_position = global_position
	beam.target_pos = target_pos; beam.beam_color = col
	get_parent().add_child(beam)

# --- Portale swap ---
func _spawn_swap_portal_fx(pos: Vector2) -> void:
	var portal := _SwapPortalFX.new()
	portal.global_position = pos
	get_parent().add_child(portal)



# --- Chrono afterimage cyan ---
var _chrono_img_timer: float = 0.0
func _spawn_chrono_afterimage() -> void:
	for p in [body_p, wing_p]:
		if not (p is Sprite2D): continue
		var ghost := Sprite2D.new()
		ghost.texture         = p.texture
		ghost.global_position = p.global_position
		ghost.global_rotation = p.global_rotation
		ghost.scale           = p.scale * scale
		ghost.modulate        = Color(0.0, 0.7, 1.0, 0.35)
		ghost.z_index         = z_index - 1
		get_parent().add_child(ghost)
		var tw = create_tween()
		tw.tween_property(ghost, "modulate:a", 0.0, 0.28)
		tw.tween_callback(ghost.queue_free)

# --- Aura node: sostituisce quella corrente ---
func _replace_aura(new_aura: Node2D) -> void:
	_remove_aura()
	_aura_node = new_aura
	add_child(_aura_node)

func _remove_aura() -> void:
	if is_instance_valid(_aura_node):
		_aura_node.queue_free()
		_aura_node = null

# --- HUD cooldown sopra la nave ---
func _spawn_cd_hud() -> void:
	if is_instance_valid(_cd_hud_node): _cd_hud_node.queue_free()
	_cd_hud_node = _SkillCooldownHUD.new()
	_cd_hud_node.player_ref = self
	_cd_hud_node.total_cd   = _skill_cooldown_max
	add_child(_cd_hud_node)


# ==============================================================
# NODI DRAW INTERNI — PROCEDURALI
# ==============================================================

class _RingBurst extends Node2D:
	var ring_color: Color = Color(1,1,1,0.6)
	var max_radius: float = 300.0
	var duration:   float = 0.5
	var _age:       float = 0.0
	func _process(delta):
		_age += delta; queue_redraw()
		if _age >= duration: queue_free()
	func _draw():
		var t := _age / duration
		for ri in range(3):
			var phase = min(t + ri * 0.12, 1.0)
			var r := max_radius * pow(phase, 0.6)
			var a = (1.0 - phase) * ring_color.a
			var c := ring_color; c.a = a
			draw_arc(Vector2.ZERO, r, 0, TAU, 64, c, 4.0 * (1.0 - t), true)

class _CrystalBurst extends Node2D:
	var burst_color: Color = Color(0.7, 0.95, 1.0, 0.85)
	var _age:  float = 0.0
	var _dur:  float = 0.5
	var _arms: Array = []
	func _ready():
		for i in range(10):
			var angle := (TAU / 10.0) * i + randf_range(-0.2, 0.2)
			_arms.append({ "dir": Vector2(cos(angle), sin(angle)), "len": randf_range(22.0, 38.0) })
	func _process(delta):
		_age += delta; queue_redraw()
		if _age >= _dur: queue_free()
	func _draw():
		var t := _age / _dur
		var a := (1.0 - t)
		for arm in _arms:
			var tip: Vector2 = arm.dir * arm.len * pow(t, 0.5)
			draw_line(Vector2.ZERO, tip, Color(burst_color.r, burst_color.g, burst_color.b, a * 0.8), 2.0, true)
			draw_circle(tip, (1.0 - t) * 3.5, Color(1.0, 1.0, 1.0, a * 0.7))
			var perp = Vector2(-arm.dir.y, arm.dir.x) * arm.len * 0.3 * (1.0 - t)
			draw_line(arm.dir * arm.len * 0.55 * pow(t, 0.5),
				arm.dir * arm.len * 0.55 * pow(t, 0.5) + perp,
				Color(burst_color.r, burst_color.g, burst_color.b, a * 0.45), 1.2, true)

class _BurnFX extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 18.0) * 0.5 + 0.5
		for i in range(9):
			var a := (TAU / 9.0) * i + _t * 1.8
			var r := 13.0 + p * 7.0
			var tip := Vector2(cos(a), sin(a) - 0.35) * r
			draw_line(Vector2.ZERO, tip, Color(1.0, 0.25 + p * 0.5, 0.0, 0.6 * p), 2.2 * p, true)
			if i % 3 == 0:
				draw_circle(tip, 1.5 + p * 1.5, Color(1.0, 0.9, 0.2, 0.65 * p))
		draw_circle(Vector2.ZERO, 5.0 + p * 3.5, Color(1.0, 0.35, 0.0, 0.4))

class _SovereignAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 6.0) * 0.5 + 0.5
		for ring in range(3):
			var phase := fmod(_t * 0.75 + ring * 0.33, 1.0)
			var r = lerp(14.0, 52.0, phase)
			draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.5, 0.9, 1.0, (1.0 - phase) * 0.55), 2.5, true)
		for arm in range(6):
			var angle := _t * 0.55 + (TAU / 6.0) * arm
			var tip := Vector2(cos(angle), sin(angle)) * (22.0 + p * 7.0)
			draw_line(Vector2.ZERO, tip, Color(0.7, 1.0, 1.0, 0.7), 1.5, true)
			for b in range(2):
				var bf := (float(b) + 0.5) / 2.0
				var bp := Vector2(cos(angle), sin(angle)) * tip.length() * bf
				var perp := Vector2(-sin(angle), cos(angle)) * 5.0 * (1.0 - bf)
				draw_line(bp - perp, bp + perp, Color(0.8, 1.0, 1.0, 0.45), 1.0, true)
		draw_circle(Vector2.ZERO, 4.5 + p * 2.0, Color(0.7, 1.0, 1.0, 0.85))

class _HeraldAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 4.0) * 0.5 + 0.5
		for ring in range(2):
			var phase := _t * 2.5 + ring * PI
			var r := 30.0 + float(ring) * 10.0 + p * 4.0
			draw_arc(Vector2.ZERO, r, phase, phase + TAU * 0.7, 20,
				Color(0.5, 0.0, 1.0, 0.5 - ring * 0.15), 2.5, true)
		for dot in range(5):
			var da := _t * 3.0 + (TAU / 5.0) * dot
			draw_circle(Vector2(cos(da), sin(da)) * 30.0, 3.2, Color(0.8, 0.2, 1.0, 0.85))
		draw_circle(Vector2.ZERO, 5.5 + p * 2.5, Color(0.7, 0.0, 1.0, 0.65))

class _EclipseAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 3.0) * 0.35 + 0.65
		for ci in range(16):
			var ca := (TAU / 16.0) * ci + _t * 0.18
			var cl := (18.0 + sin(_t * 5.0 + ci * 0.9) * 9.0) * p
			draw_line(Vector2.ZERO, Vector2(cos(ca), sin(ca)) * cl, Color(0.7, 0.0, 0.9, 0.5), 1.5, true)
		draw_circle(Vector2.ZERO, 15.0 * p, Color(0.5, 0.0, 0.8, 0.25))
		draw_circle(Vector2.ZERO, 9.0, Color(0.02, 0.0, 0.06, 1.0))
		draw_circle(Vector2.ZERO, 4.0, Color(0.6, 0.0, 0.85, 0.9))
		for si in range(7):
			var sa := _t * 0.45 + (TAU / 7.0) * si
			draw_circle(Vector2(cos(sa), sin(sa)) * 40.0, 1.5, Color(1.0, 0.9, 0.5, 0.4 * p))

class _BeamFX extends Node2D:
	var target_pos: Vector2 = Vector2.ZERO
	var beam_color: Color   = Color(0.8, 0.0, 0.1)
	var _age: float = 0.0; var _dur: float = 1.0
	func _process(delta): _age += delta; queue_redraw(); if _age >= _dur: queue_free()
	func _draw():
		var a := (1.0 - _age / _dur) * 0.8
		var local_t := to_local(target_pos)
		var perp := local_t.normalized().rotated(PI * 0.5) * sin(_age * 20.0) * 5.0
		draw_line(Vector2.ZERO, local_t + perp, Color(beam_color.r, beam_color.g, beam_color.b, a * 0.45), 9.0, true)
		draw_line(Vector2.ZERO, local_t + perp, Color(1.0, 0.3, 0.3, a), 2.0, true)
		draw_circle(local_t, 7.0 * (1.0 - _age / _dur), Color(1.0, 0.5, 0.5, a))

class _SwapPortalFX extends Node2D:
	var _age: float = 0.0
	var _dur: float = 0.4

	func _process(delta):
		_age += delta
		queue_redraw()
		if _age >= _dur:
			queue_free()

	func _draw():
		var t := _age / _dur
		var r: float
		if t < 0.5:
			r = pow(t * 2.0, 0.4) * 65.0
		else:
			r = (1.0 - pow((t - 0.5) * 2.0, 0.6)) * 65.0

		var a := sin(t * PI)
		draw_circle(Vector2.ZERO, r * 0.6, Color(0.3, 0.0, 0.7, a * 0.2))
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.8, 0.2, 1.0, a * 0.9), 4.0, true)
		draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 32, Color(0.2, 0.7, 1.0, a * 0.6), 2.0, true)
		var cr := r * 0.25
		draw_line(Vector2(-cr, 0), Vector2(cr, 0), Color(1, 1, 1, a), 2.5)
		draw_line(Vector2(0, -cr), Vector2(0, cr), Color(1, 1, 1, a), 2.5)

class _SkillCooldownHUD extends Node2D:
	var player_ref: Node  = null
	var total_cd:   float = 20.0
	const STAR_RADIUS := 12.0          # molto piccolo, discreto
	const OFFSET := Vector2(0, -40)    # sopra il giocatore

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

		var pct   := cd / total_cd
		var sweep := TAU * (1.0 - pct)             # quanto è già carico
		var start_angle := -PI * 0.5               # alto
		var end_angle   := start_angle + sweep

		var off := OFFSET

		# Stella di sfondo (spenta)
		draw_star(off, STAR_RADIUS, Color(0.1, 0.1, 0.1, 0.5))

		# Stella luminosa che segue il progresso
		draw_star_progress(off, STAR_RADIUS, start_angle, end_angle,
			Color(0.2, 0.9, 0.4, 0.8), Color(0.4, 1.0, 0.6, 1.0))

		# Piccolo bagliore pulsante al centro
		var t := Time.get_ticks_msec() / 1000.0
		var pulse = abs(sin(t * 5.0))
		draw_circle(off, 2.5, Color(1.0, 1.0, 1.0, 0.4 + 0.3 * pulse), true)

	func draw_star(origin: Vector2, r: float, col: Color):
		# 4 bracci a 45° (diagonali)
		var angles = [PI/4, 3*PI/4, 5*PI/4, 7*PI/4]
		for a in angles:
			var tip := Vector2(cos(a), sin(a)) * r
			var left := Vector2(cos(a - 0.3), sin(a - 0.3)) * (r * 0.3)
			var right:= Vector2(cos(a + 0.3), sin(a + 0.3)) * (r * 0.3)
			var polygon := PackedVector2Array([origin, origin + left, origin + tip, origin + right])
			draw_colored_polygon(polygon, col)

	func draw_star_progress(origin: Vector2, r: float, start_a: float, end_a: float,
		col_main: Color, col_tip: Color):
		# 4 settori di 90° ciascuno, coprono tutta la stella
		for i in range(4):
			var sector_start := start_a + i * PI/2   # angolo inizio braccio
			var sector_end   := sector_start + PI/2   # angolo fine braccio
			if sector_start >= TAU:
				sector_start -= TAU
				sector_end -= TAU

			# Intersezione con l’arco di progresso
			var a1 = max(sector_start, start_a)
			var a2 = min(sector_end, end_a)
			if a1 >= a2:
				continue   # nessuna parte da illuminare

			# Disegna il braccio parziale (triangolo intersecato)
			var mid := (sector_start + sector_end) * 0.5
			var tip_angle := mid
			if abs(a2 - a1) < 0.01:
				continue

			# Vertici del poligono: centro, punto interno, punta esterna, altro punto interno
			var p0 := origin
			var p1 := origin + Vector2(cos(a1), sin(a1)) * (r * 0.3)  # base del braccio
			var p2 := origin + Vector2(cos(tip_angle), sin(tip_angle)) * r
			var p3 := origin + Vector2(cos(a2), sin(a2)) * (r * 0.3)

			var poly := PackedVector2Array([p0, p1, p2, p3])
			draw_colored_polygon(poly, col_main)

		# Contorno brillante sulle punte illuminate
		for i in range(4):
			var tip_angle := start_a + i * PI/2 + PI/4
			if tip_angle >= TAU:
				tip_angle -= TAU
			var a1 := start_a
			var a2 := end_a
			if a2 < a1:
				a2 += TAU
			if tip_angle >= a1 and tip_angle <= a2:
				var tip := origin + Vector2(cos(tip_angle), sin(tip_angle)) * r
				draw_circle(tip, 2.0, col_tip, true)
	

# ==============================================================
# MORTE EPICA
# ==============================================================
func on_player_dead() -> void:
	if !Global.player_dead and Global.player_hp <= 0:
		Global.player_hp = 0
		Global.update_mission_progress("die_time_1", 1)
		Global.update_mission_progress("die_time_2", 1)
		Global.update_mission_progress("die_time_3", 1)
		if GlobalStats.respawn >= 50:
			immune(); Global.player_hp = Global.player_max_hp / 2
			Global.player_stamina = Global.player_max_stamina; return
		elif randf() < GlobalStats.respawn / 100.0:
			immune(); Global.player_hp = Global.player_max_hp / 8
			if GlobalStats.respawn_god:
				Global.player_hp    = Global.player_max_hp
				Global.player_stamina = Global.player_max_stamina
			return
		Global.player_dead = true
		GlobalStats.died_times += 1

	can_dash = false; can_move = false; can_rotate = false; can_shoot = false
	$Audio/die.play()

	# FX morte: flash bianco → dispersione pezzi
	var tw_flash = create_tween().set_parallel(true)
	for p in [body_p, wing_p, prop_p, canon_p]:
		if is_instance_valid(p):
			tw_flash.tween_property(p, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.04)
	_fx_ring_burst(Color(1.0, 0.5, 0.0, 0.85), 240.0, 0.65)
	$CameraRing.shake(1.5)

	var parts = [$BodySprite, $Wings/WingsSprite, $Propulsor/PropulsorSprite, $Canon/CanonSprite]
	for part in parts:
		if not is_instance_valid(part): continue
		var rand_dir  := Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
		var target_pos = part.global_position + rand_dir * randf_range(80.0, 160.0)
		var tw = create_tween()
		tw.tween_property(part, "global_position", target_pos, randf_range(1.0, 2.2)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var tw_rot = create_tween().set_loops()
		tw_rot.tween_property(part, "rotation_degrees", randf_range(360, 720), randf_range(2.0, 4.0)).as_relative()
		var tw_float = create_tween().set_loops()
		tw_float.tween_property(part, "position:y", part.position.y + randf_range(-15, 15), randf_range(0.8, 1.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Fade out lento
		var tw_fade = create_tween()
		tw_fade.tween_property(part, "modulate:a", 0.0, 2.5).set_delay(0.5)


# ==============================================================
# READY
# ==============================================================
func unlocker_stats() -> void:
	can_dash = true; can_move = true; can_rotate = true; can_shoot = true
	GlobalStats.kill_mobs_lvl = 0

func start_possession_glitch() -> void:
	var parts = [body_p, wing_p, prop_p, canon_p]
	for p in parts: p.modulate = Color(1,1,1,0); p.scale = Vector2.ONE; p.position = Vector2.ZERO
	var t = create_tween().set_parallel(true)
	for p in parts: t.tween_property(p, "modulate:a", 1.0, 0.1).from(0.0)
	await get_tree().create_timer(0.1).timeout
	for i in range(6):
		for p in parts:
			p.position = Vector2(randf_range(-12, 12), randf_range(-12, 12))
			p.modulate  = Color(1.0, randf_range(0.3, 1.0), randf_range(0.3, 1.0), 1.0)
			p.scale     = Vector2.ONE * randf_range(0.9, 1.2)
		await get_tree().create_timer(0.05).timeout
	for p in parts: p.position = Vector2.ZERO; p.scale = Vector2.ONE; p.modulate = Color(1,1,1,1)
	var t2 = create_tween().set_parallel(true)
	for p in parts:
		t2.tween_property(p, "scale", Vector2.ONE * 1.15, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t2.tween_property(p, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if has_node("../FlashOverlay"):
		var flash = get_node("../FlashOverlay")
		flash.modulate = Color(1,1,1,0)
		var tf = create_tween()
		tf.tween_property(flash, "modulate:a", 1.0, 0.08)
		tf.tween_property(flash, "modulate:a", 0.0, 0.3)
	if has_node("../Camera2D"):
		var cam = get_node("../Camera2D")
		if cam.has_method("start_shake"): cam.start_shake(0.4, 10.0)
	if has_node("GlitchSound"): $GlitchSound.play()

func color_check() -> void:
	$BodySprite.material.set_shader_parameter("red_factor",   Global.body_red_factor)
	$BodySprite.material.set_shader_parameter("green_factor", Global.body_green_factor)
	$BodySprite.material.set_shader_parameter("blue_factor",  Global.body_blue_factor)
	$BodySprite.material.set_shader_parameter("saturation",   Global.body_saturation)
	$BodySprite.material.set_shader_parameter("brightness",   Global.body_brightness)
	$BodySprite.material.set_shader_parameter("contrast",     Global.body_contrast)
	$BodySprite.material.set_shader_parameter("hue_shift",    Global.body_hue_shift)
	$BodySprite.material.set_shader_parameter("gamma",        Global.body_gamma)

func _ready() -> void:
	unlocker_stats()
	start_possession_glitch()
	if can_zoom:
		var tw = create_tween()
		$CameraRing.zoom = Vector2(6, 6)
		tw.tween_property($CameraRing, "zoom", Vector2(1,1), 1.5).set_ease(Tween.EASE_OUT)
	Global.player = self
	Global.canon  = $Canon
	$BodySprite.texture = load("res://Gres/Assets/player/body/body_%s.png" % Global.texture_body)
	var mat_body = ShaderMaterial.new()
	mat_body.shader = preload("res://Gres/Shaders/ColorShader.gdshader")
	$BodySprite.material = mat_body
	color_check()
	# ==================================================
	# IMPLEMENTA TU: Aggiungi "active_skill" in
	# Project > Project Settings > Input Map
	# Action name: "active_skill", tasto consigliato: E
	# ==================================================
	if not GlobalWeapons.gun_found.is_connected(_on_gun_found):
		GlobalWeapons.gun_found.connect(_on_gun_found)

	# Crea il timer per la pulsazione
	pulse_timer = Timer.new()
	add_child(pulse_timer)
	pulse_timer.wait_time = 0.08
	pulse_timer.timeout.connect(_on_pulse)
	pulse_timer.start()
	set_process(true)
	queue_redraw()

func _on_pulse():
	pulse_scale = 1.0 + (void_stacks / float(max_stacks)) * 0.4
	queue_redraw()

func _process(delta):
	rotation_angle += delta * 1.2
	queue_redraw()
	
	if is_eclipse_active:
		eclipse_timer += delta
		eclipse_rotation += delta * 1.5   # rotazione delle ombre
		queue_redraw()

func _on_gun_found(weapon_name: String, rarity: String) -> void:
	_fx_weapon_pickup(rarity)
	_skill_cooldown_max = _cd_for_weapon(GlobalWeapons.current_weapon.get("projectile_type",""))

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


# ==============================================================
# IMMUNE
# ==============================================================
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
	if Input.is_key_pressed(KEY_CTRL):
		global_position = get_global_mouse_position()

	handle_input()
	Global.PlayerX = position.x
	Global.PlayerY = position.y

	_update_buffs(delta)
	_process_skill_cooldown(delta)
	_process_passives(delta)

	# Chrono afterimage durante il movimento
	if GlobalWeapons.current_weapon.get("projectile_type","") == "chrono_ripper_shot" and is_moving:
		_chrono_img_timer += delta
		if _chrono_img_timer >= 0.05:
			_chrono_img_timer = 0.0
			_spawn_chrono_afterimage()

	# AEGIS STORM logica hold
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

	# Skill attiva — tasto E (Input Map: "active_skill")
	if Input.is_action_just_pressed("skill_1"):
		_trigger_active_skill()

	# Shoot normale (non AEGIS)
	if GlobalWeapons.current_weapon.get("projectile_type","") != "aegis_storm_shot":
		if can_shoot and is_shooting:
			can_shoot = false
			$TimeManager/ShootFreeze.wait_time = Global.shoot_freeze
			$TimeManager/ShootFreeze.start()
			_fx_shoot(GlobalWeapons.current_weapon.get("rarity", "common"))
			canon.shoot()
	
# ==============================================================
# AEGIS STORM
# ==============================================================
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
	var wd          = GlobalWeapons.current_weapon
	var max_charge  = wd.get("max_charge_time", 5.0)
	var min_b       = wd.get("min_bullets", 1)
	var max_b       = wd.get("max_bullets", 20)
	var pct         = _aegis_charge_time / max_charge
	var count       = clamp(int(lerp(float(min_b), float(max_b), pct)), min_b, max_b)
	var is_full     = pct >= 0.99
	
	$CameraRing.shake(Global.cam_shake * (0.3 + pct * 1.5))
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


# ==============================================================
# TAKE DAMAGE
# ==============================================================
func take_damage(amount: float) -> void:
	if not can_be_damaged: return
	Global.player_hp -= amount
	$Audio/hurt.play()
	var effect = load("res://Gres/Scenes/Effects/expl_p.tscn").instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
	hurt_flash(amount)
	if Global.player_hp <= 0:
		Global.player_hp = 0
		on_player_dead()


# ==============================================================
# INPUT / MOVIMENTO / DASH / ROTAZIONE
# ==============================================================
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
	if has_buff("chrono_speed"): speed_mult = max(speed_mult, 1.2)
	if has_meta("sovereign_active"): speed_mult *= 1.3
	velocity = (last_input_direction if Global._dash_timer > 0 else input_direction) \
		* (Global.dash_speed if Global._dash_timer > 0 else Global.move_speed * speed_mult)
	move_and_slide()

func process_dash(delta: float) -> void:
	if is_dashing and Global._dash_timer <= 0 and Global.player_stamina >= 10:
		Global.update_mission_progress("dash_uses", 1)
		Global.player_stamina -= 0 if randi() % 100 < Global.chance_not_consum_stamina \
			else (10 if !Global.stamina_regen_skill else 8)
		if Global.player_stamina <= 0: Global.player_stamina = 0
		Global._dash_timer         = Global.dash_duration
		Global._dash_cooldown_timer = Global.dash_cooldown
		_fx_dash()
	if Global._dash_timer > 0:      Global._dash_timer -= delta
	else:                            Global._dash_timer  = 0.0
	if Global._dash_cooldown_timer > 0: Global._dash_cooldown_timer -= delta

func rotate_towards_mouse() -> void: look_at(get_global_mouse_position())
func get_current_velocity() -> Vector2: return velocity

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null; var min_d := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D): continue
		var d := global_position.distance_to(e.global_position)
		if d < min_d: min_d = d; nearest = e
	return nearest


# ==============================================================
# TIMER CALLBACKS
# ==============================================================
func _on_shoot_freeze_timeout() -> void:       can_shoot = true
func _on_immune_shield_cd_timeout() -> void:   Global.player_immunity = false; can_immune = true
func _on_time_slow_cd_timeout() -> void:
	GlobalStats.time_slow = false; can_time_slow = true; Global.slow_factor = 1.0
func _on_timer_stam_reg_timeout() -> void:
	if Global.player_stamina < Global.player_max_stamina:
		Global.player_stamina += 4 if !Global.stamina_regen_skill else 6
	$TimeManager/TimerStamReg.wait_time = 10 if !Global.stamina_regen_skill else 2
	$TimeManager/TimerStamReg.start()
func _on_timer_hp_reg_timeout() -> void:
	if Global.player_hp < Global.player_max_hp: Global.player_hp += Global.player_hp_reg
	$TimeManager/TimerHPReg.start()


func _on_shield_reflect_area_entered(area: Area2D) -> void:
	if _aegis_shield_active:
		_on_aegis_deflect(area)
	
