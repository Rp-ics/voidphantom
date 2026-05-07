## BossTemplate_Artillery.gd (EPIC DRAW-ONLY VERSION - ULTRA ENHANCED)
## ============================================================
extends CharacterBody2D
class_name BossTemplate_Artillery

# ============================================================
# === IDENTITÀ ================================================
# ============================================================
@export_group("Boss Identity")
@export var boss_name: String = "Artillery Boss"
@export var hp_key: String = "artillery_hp"
@export var mission_key_easy: String = "boss_killer_1"
@export var mission_key_medium: String = "boss_killer_2"
@export var mission_key_hard: String = "boss_killer_3"
@export var legendary_weapon_drop: String = "ARTILLERY CORE"
@export var death_scene_path: String = "res://Gres/Scenes/Story/boss_dead_scene.tscn"
@export var can_tp_scene: bool = false
@export var phase_1_texture: Texture
@export var phase_2_texture: Texture
@export var phase_3_texture: Texture
@export var dificulty: String = "easy"

## Modalità endless
@export_group("Endless Mode")
@export var endless_mode: bool = false
@export var endless_wave_easy_max: int = 19
@export var endless_wave_medium_max: int = 34
@export var endless_hard_start: int = 35

# ============================================================
# === HP ======================================================
# ============================================================
@export_group("Health")
@export var hp_easy: int = 9000
@export var hp_medium: int = 14000
@export var hp_hard: int = 21000
@export var shield_hp_easy: int = 200
@export var shield_hp_medium: int = 700
@export var shield_hp_hard: int = 2000
@export var shield_regen_time: float = 10.0

var _current_hp: int = 0

# ============================================================
# === MOVIMENTO ===============================================
# ============================================================
@export_group("Movement")
enum MovementType { RANDOM, ORBITAL, FLOATING }
@export var movement_type: MovementType = MovementType.RANDOM

@export var preferred_distance: float = 400.0
@export var flee_distance: float = 200.0
@export var max_distance: float = 600.0
@export var speed_easy: float = 150.0
@export var speed_medium: float = 200.0
@export var speed_hard: float = 270.0

@export var random_wander_range: float = 500.0
@export var random_new_target_interval: float = 1.5

@export var orbit_radius: float = 350.0
@export var orbit_speed: float = 45.0

@export var float_amplitude: float = 30.0
@export var float_frequency: float = 2.0
@export var float_reposition_interval: float = 3.0
@export var float_dash_speed: float = 800.0
@export var float_dash_duration: float = 0.3

# ============================================================
# === FASI ====================================================
# ============================================================
@export_group("Phases")
@export var use_phase_two: bool = true
@export var use_phase_three: bool = true
@export var phase_two_threshold: float = 0.6
@export var phase_three_threshold: float = 0.25
@export var aura_color_p1: Color = Color(0.0, 0.6, 1.0, 0.5)
@export var aura_color_p2: Color = Color(1.0, 0.5, 0.0, 0.6)
@export var aura_color_p3: Color = Color(1.0, 0.0, 0.0, 0.8)

# ============================================================
# === ANIMAZIONI DI TRANSIZIONE FASE ==========================
# ============================================================
@export_group("Phase Transition Animations")
@export var phase_transition_duration: float = 1.5
@export var transition_shockwave_rings: int = 6
@export var transition_spark_count: int = 60
@export var transition_lightning_count: int = 8
@export var transition_flash_color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var invincible_during_transition: bool = true
@export var transition_scale_bump: float = 1.3

# ============================================================
# === ATTACK COLORS & INTENSITIES =============================
# ============================================================
@export_group("Attack Colors")
@export var bullet_color: Color = Color(0.0, 1.0, 0.8, 0.9)
@export var spread_color: Color = Color(1.0, 0.6, 0.0, 0.9)
@export var laser_color: Color = Color(1.0, 0.2, 0.2, 1.0)
@export var mine_color: Color = Color(0.8, 0.2, 1.0, 0.9)
@export var rocket_color: Color = Color(1.0, 0.1, 0.1, 1.0)
@export var orbital_color: Color = Color(0.2, 0.8, 1.0, 0.9)
@export var vortex_color: Color = Color(0.5, 0.0, 0.8, 0.9)

@export_group("Attack Visual Intensity")
@export var bullet_glow_size: float = 30.0
@export var spread_ring_count: int = 5
@export var laser_charge_time: float = 0.8
@export var mine_mark_size: float = 50.0
@export var rocket_mark_grow_time: float = 0.4

# ============================================================
# === ATTACCO BASE (SHOOT) ====================================
# ============================================================
@export_group("Attacks - Basic Shoot")
@export var bullet_scene: PackedScene
@export var shoot_probability: float = 0.03
@export var bullet_count_easy: int = 3
@export var bullet_count_medium: int = 5
@export var bullet_count_hard: int = 8
@export var bullet_speed_easy: float = 250.0
@export var bullet_speed_medium: float = 320.0
@export var bullet_speed_hard: float = 420.0
@export var bullet_spread_deg: float = 8.0

# ============================================================
# === SPREAD FIRE (VENTAGLIO) =================================
# ============================================================
@export_group("Attacks - Spread Fire")
@export var use_spread: bool = true
@export var spread_probability: float = 0.008
@export var spread_count_easy: int = 12
@export var spread_count_medium: int = 18
@export var spread_count_hard: int = 24
@export var spread_rotated: bool = true

# ============================================================
# === ORBITA DI PROIETTILI ====================================
# ============================================================
@export_group("Attacks - Orbital")
@export var use_orbital_bullets: bool = true
@export var orbital_probability: float = 0.004
@export var orbital_ring_count: int = 2
@export var orbital_speed_deg: float = 30.0
@export var bullet_ring: float = 20.0
@export var orbital_duration: float = 5.0
@export var explosion_scene: PackedScene

# ============================================================
# === LASER ===================================================
# ============================================================
@export_group("Attacks - Laser")
@export var laser_scene: PackedScene
@export var use_laser: bool = true
@export var laser_probability: float = 0.005
@export var laser_count_easy: int = 1
@export var laser_count_medium: int = 2
@export var laser_count_hard: int = 4
@export var laser_offset_range: float = 300.0

@export var laser_glow_color: Color = Color(1.0, 0.4, 0.1, 0.5)
@export var laser_thickness: float = 4.0
@export var laser_length: float = 500.0
@export var laser_damage: int = 1

var active_lasers: Array = []
var laser_lifetime: float = 0.4

var _draw_charging_laser: bool = false
var _laser_target: Vector2 = Vector2.ZERO
var _laser_charge_progress: float = 0.0
var _particles_laser_charge: Array = []

# ============================================================
# === MINE ====================================================
# ============================================================
@export_group("Attacks - Mines")
@export var mine_scene: PackedScene
@export var use_mines: bool = false
@export var mine_probability: float = 0.004
@export var mine_count_easy: int = 2
@export var mine_count_medium: int = 4
@export var mine_count_hard: int = 7
@export var mine_spread_radius: float = 400.0

# ============================================================
# === ROCKET BARRAGE ==========================================
# ============================================================
@export_group("Attacks - Rocket Barrage")
@export var use_rocket_barrage: bool = false
@export var rocket_probability: float = 0.003
@export var rocket_count_easy: int = 3
@export var rocket_count_medium: int = 6
@export var rocket_count_hard: int = 10
@export var rocket_warning_time: float = 1.5
@export var rocket_damage_easy: float = 30.0
@export var rocket_damage_medium: float = 50.0
@export var rocket_damage_hard: float = 80.0
@export var rocket_blast_radius: float = 120.0

# ============================================================
# === VORTEX ==================================================
# ============================================================
@export_group("Attacks - Vortex")
@export var use_vortex: bool = false
@export var vortex_probability: float = 0.002
@export var vortex_duration: float = 6.0
@export var vortex_step_deg_easy: int = 20
@export var vortex_step_deg_medium: int = 15
@export var vortex_step_deg_hard: int = 10

# ============================================================
# === SCUDO ===================================================
# ============================================================
@export_group("Shield")
@export var use_shield: bool = true

# ============================================================
# === DROPS ===================================================
# ============================================================
@export_group("Drops")
@export var gold_min: int = 180
@export var gold_max: int = 650
@export var shard_chance_easy: float = 0.10
@export var shard_chance_medium: float = 0.16
@export var shard_chance_hard: float = 0.22
@export var tablet_chance_easy: float = 0.50
@export var tablet_chance_medium: float = 0.72
@export var tablet_chance_hard: float = 0.91
@export var spin_gem_chance: float = 0.001
@export var icon_chance_easy: float = 0.02
@export var icon_chance_medium: float = 0.05
@export var icon_chance_hard: float = 0.10

# ============================================================
# === RUNTIME =================================================
# ============================================================
var phase: int = 1
var attacking: bool = false
var can_move: bool = true
var is_invincible: bool = false
var in_transition: bool = false
var player: Node2D
var rng := RandomNumberGenerator.new()
var can_regen: bool = true
var _shield_hp_current: int = 0
var _max_hp: int = 0
var _speed: float = 0.0
var _spread_rotation_offset: float = 0.0
var _orbital_bullets: Array = []
var can_die: bool = true

# Movimento runtime
var _random_target: Vector2 = Vector2.ZERO
var _random_timer: float = 0.0
var _float_time: float = 0.0
var _float_reposition_timer: float = 0.0
var _float_base_position: Vector2 = Vector2.ZERO
var _float_target_position: Vector2 = Vector2.ZERO
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO
var _current_orbit_angle: float = 0.0

# Draw state - SISTEMA DI PARTICELLE POTENZIATO
var _particles_aura: Array = []
var _particles_rings: Array = []
var _particles_sparks: Array = []
var _particles_lightning: Array = []
var _particles_rocket_markers: Array = []
var _particles_explosion: Array = []
var _particles_mine_flash: Array = []
var _particles_energy_orbits: Array = []      # NUOVO: particelle orbitanti energetiche
var _particles_death_explosion: Array = []    # NUOVO: esplosione finale di morte

# Transizione di fase
var _transition_elapsed: float = 0.0
var _transition_sparks_spawned: bool = false
var _transition_mid_sparks_spawned: bool = false
var _original_scale: Vector2 = Vector2.ONE

# Effetti scudo visivi
var _shield_particles: Array = []             # NUOVO: particelle visive scudo
var _shield_break_particles: Array = []       # NUOVO: esplosione rottura scudo

# Difficulty override
var _effective_difficulty: String = "easy"
var _endless_scale: float = 1.0

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var fire_timer: Timer = $FireTimer

# ============================================================
# === READY ===================================================
# ============================================================
func _ready() -> void:
	if endless_mode:
		_effective_difficulty = _get_endless_difficulty()
		_endless_scale = _compute_endless_scale()
	else:
		_effective_difficulty = Global.dificulty

	match _effective_difficulty:
		"easy":
			_max_hp = int(hp_easy * _endless_scale)
			_speed = speed_easy
			_shield_hp_current = shield_hp_easy
		"medium":
			_max_hp = int(hp_medium * _endless_scale)
			_speed = speed_medium
			_shield_hp_current = shield_hp_medium
		"hard":
			_max_hp = int(hp_hard * _endless_scale)
			_speed = speed_hard
			_shield_hp_current = shield_hp_hard

	Global.set(hp_key + "_max", _max_hp)
	Global.set(hp_key, _max_hp)
	player = get_tree().get_first_node_in_group("player")
	
	_original_scale = sprite.scale if sprite else Vector2.ONE
	
	# Inizia l'aura della fase 1 + orbite energetiche
	_particles_aura.append({"radius": 80.0, "alpha": 0.8, "color": aura_color_p1, "speed": 20.0, "pulse": 0.0})
	
	# Crea orbite energetiche iniziali
	for i in range(3):
		_particles_energy_orbits.append({
			"angle": i * TAU / 3.0,
			"radius": 100.0,
			"speed": 1.5 + i * 0.5,
			"color": aura_color_p1,
			"size": 4.0 + i * 2.0,
			"trail": []
		})
	
	# Inizializza posizioni movimento
	if player:
		_random_target = _get_random_position_around_player()
		_float_base_position = _get_random_position_around_player()
		_float_target_position = _float_base_position
		_current_orbit_angle = atan2(global_position.y - player.global_position.y, global_position.x - player.global_position.x)
	
	fire_timer.start()
	_play_anim("idle")
	_current_hp = _max_hp
	if use_shield:
		_update_shield_label()
		_init_shield_particles()

func _init_shield_particles() -> void:
	_shield_particles.clear()
	for i in range(20):
		_shield_particles.append({
			"angle": i * TAU / 20.0,
			"dist": 70.0 + sin(i * 0.5) * 10.0,
			"speed": 0.5 + randf() * 1.0,
			"alpha": 0.4 + randf() * 0.3,
			"size": 2.0 + randf() * 3.0
		})

# ============================================================
# === ENDLESS LOGIC ===========================================
# ============================================================
func _get_endless_difficulty() -> String:
	var wave = Global.wave if "wave" in Global else 10
	if wave >= endless_hard_start:
		return "hard"
	elif wave >= endless_wave_easy_max + 1:
		return "medium"
	return "easy"

func _compute_endless_scale() -> float:
	var wave = Global.wave if "wave" in Global else 10
	var base_wave: int
	match _effective_difficulty:
		"easy": base_wave = 5
		"medium": base_wave = 20
		"hard": base_wave = 35
		_: base_wave = 5
	var extra = max(0, wave - base_wave)
	return 1.0 + extra * 0.02

# ============================================================
# === PROCESS (POTENZIATO) ====================================
# ============================================================
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_current_hp -= 100
	if _current_hp <= 0:
		_current_hp = 0
	if $HP_Bar:
		$HP_Bar.max_value = _max_hp
		$HP_Bar.value = _current_hp
		$HP_Text.text = str(_current_hp)
	
	# Gestione transizione di fase
	if in_transition:
		_update_phase_transition(delta)
	else:
		match phase:
			1: _phase_one(delta)
			2: _phase_two(delta)
			3: _phase_three(delta)
	
	# Aggiorna tutte le particelle
	_update_particles(delta)
	_update_energy_orbits(delta)
	_update_shield_visuals(delta)
	_process_lasers(delta)
	
	# Scintille casuali ambientali quando il boss è carico
	if not in_transition and randf() < 0.05:
		var angle = rng.randf() * TAU
		var dist = rng.randf_range(50, 120)
		var pos = Vector2(cos(angle), sin(angle)) * dist
		_particles_sparks.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * rng.randf_range(20, 60),
			"life": rng.randf_range(0.2, 0.5),
			"color": aura_color_p1 if phase == 1 else (aura_color_p2 if phase == 2 else aura_color_p3)
		})
	
	queue_redraw()

func _update_energy_orbits(delta: float) -> void:
	for orb in _particles_energy_orbits:
		orb["angle"] += orb["speed"] * delta
		# Trail
		orb["trail"].append(orb["angle"])
		if orb["trail"].size() > 8:
			orb["trail"].pop_front()

func _update_shield_visuals(delta: float) -> void:
	if not use_shield: return
	
	for p in _shield_particles:
		p["angle"] += p["speed"] * delta
	
	# Se scudo rotto, anima particelle di rottura
	for i in range(_shield_break_particles.size() - 1, -1, -1):
		var bp = _shield_break_particles[i]
		bp["life"] -= delta
		bp["pos"] += bp["vel"] * delta
		bp["vel"] *= 0.95
		if bp["life"] <= 0.0:
			_shield_break_particles.remove_at(i)

func _update_particles(delta: float) -> void:
	# Aura
	for p in _particles_aura:
		p["radius"] += p["speed"] * delta
		if p["radius"] > 120.0 or p["radius"] < 70.0:
			p["speed"] *= -1
		p["alpha"] = lerp(p["alpha"], 0.7, 2.0 * delta)
		p["pulse"] += delta * 3.0
	
	# Anelli
	for i in range(_particles_rings.size() - 1, -1, -1):
		var r = _particles_rings[i]
		r["radius"] += r["speed"] * delta
		r["alpha"] -= 0.8 * delta
		if r["alpha"] <= 0.0 or r["radius"] >= r["max_radius"]:
			_particles_rings.remove_at(i)
	
	# Scintille
	for i in range(_particles_sparks.size() - 1, -1, -1):
		var s = _particles_sparks[i]
		s["pos"] += s["vel"] * delta
		s["vel"] *= 0.98
		s["life"] -= delta
		if s["life"] <= 0.0:
			_particles_sparks.remove_at(i)
	
	# Fulmini
	for i in range(_particles_lightning.size() - 1, -1, -1):
		var l = _particles_lightning[i]
		l["life"] -= delta
		if l["life"] <= 0.0:
			_particles_lightning.remove_at(i)
	
	# Marcatori razzi
	for i in range(_particles_rocket_markers.size() - 1, -1, -1):
		var m = _particles_rocket_markers[i]
		m["alpha"] -= 0.5 * delta
		m["life"] -= delta
		if m["life"] <= 0.0 or m["alpha"] <= 0.0:
			_particles_rocket_markers.remove_at(i)
	
	# Carica laser
	for i in range(_particles_laser_charge.size() - 1, -1, -1):
		var c = _particles_laser_charge[i]
		c["life"] -= delta
		if c["life"] <= 0.0:
			_particles_laser_charge.remove_at(i)
	
	# Esplosioni
	for i in range(_particles_explosion.size() - 1, -1, -1):
		var e = _particles_explosion[i]
		e["radius"] += 300.0 * delta
		e["alpha"] -= 1.5 * delta
		if e["alpha"] <= 0.0:
			_particles_explosion.remove_at(i)
	
	# Flash mine
	for i in range(_particles_mine_flash.size() - 1, -1, -1):
		var f = _particles_mine_flash[i]
		f["alpha"] -= 2.0 * delta
		f["radius"] += 50.0 * delta
		if f["alpha"] <= 0.0:
			_particles_mine_flash.remove_at(i)
	
	# Esplosione morte
	for i in range(_particles_death_explosion.size() - 1, -1, -1):
		var de = _particles_death_explosion[i]
		de["life"] -= delta
		de["radius"] += de["speed"] * delta
		de["alpha"] -= delta * 0.8
		if de["life"] <= 0.0 or de["alpha"] <= 0.0:
			_particles_death_explosion.remove_at(i)
	
	# Carica laser progress
	if _draw_charging_laser:
		_laser_charge_progress = min(1.0, _laser_charge_progress + delta / laser_charge_time)
	else:
		_laser_charge_progress = max(0.0, _laser_charge_progress - delta * 3.0)

# ============================================================
# === DRAW (ULTRA EPIC) =======================================
# ============================================================
func _draw() -> void:
	# Scudo visivo
	if use_shield and _shield_hp_current > 0 and not in_transition:
		_draw_shield()
	
	# Orbite energetiche
	_draw_energy_orbits()
	
	# Aura
	for p in _particles_aura:
		var c = p["color"]
		c.a *= p["alpha"] * (0.8 + sin(p.get("pulse", 0.0)) * 0.2)
		# Alone esterno sfumato
		for j in range(4):
			var r = p["radius"] + j * 15.0
			var col = c
			col.a = c.a * (0.4 - j * 0.1)
			draw_arc(Vector2.ZERO, r, 0, TAU, 64, col, 3.0 - j * 0.5, false)
		# Nucleo
		draw_arc(Vector2.ZERO, p["radius"], 0, TAU, 64, c, 4.0, false)
		c.a *= 0.3
		draw_arc(Vector2.ZERO, p["radius"] * 1.3, 0, TAU, 64, c, 1.5, false)
	
	# Anelli
	for r in _particles_rings:
		var c = r["color"]; c.a *= r["alpha"]
		draw_arc(Vector2.ZERO, r["radius"], 0, TAU, 64, c, 2.5, false)
		# Anello secondario
		c.a *= 0.4
		draw_arc(Vector2.ZERO, r["radius"] * 0.8, 0, TAU, 64, c, 1.0, false)
	
	# Scintille
	for s in _particles_sparks:
		var c = s["color"]
		draw_circle(s["pos"], 3.0 * (s["life"] / 0.8), c)
		draw_line(s["pos"], s["pos"] - s["vel"].normalized() * 8.0, c, 1.5)
		# Bagliore
		var glow = c
		glow.a *= 0.3
		draw_circle(s["pos"], 6.0, glow)
	
	# Fulmini
	for l in _particles_lightning:
		_draw_lightning(l["start"], l["end"], l["color"], l["segments"])
	
	# Marcatori razzi (teschio stilizzato potenziato)
	for m in _particles_rocket_markers:
		var c = m["color"]; c.a *= m["alpha"]
		var p = m["pos"]
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.1
		# Cerchio esterno pulsante
		draw_arc(p, 35.0 * pulse, 0, TAU, 32, c, 3.0, false)
		draw_arc(p, 25.0, 0, TAU, 32, c, 2.5, false)
		# Teschio
		draw_line(p + Vector2(-15, 0), p + Vector2(15, 0), c, 3.0)
		draw_line(p + Vector2(0, -15), p + Vector2(0, 15), c, 3.0)
		draw_circle(p + Vector2(-8, -5), 4.0, c)
		draw_circle(p + Vector2(8, -5), 4.0, c)
		draw_line(p + Vector2(-10, 8), p + Vector2(10, 8), c, 2.0)
		# Occhi brillanti
		draw_circle(p + Vector2(-8, -5), 1.5, Color.WHITE * m["alpha"])
		draw_circle(p + Vector2(8, -5), 1.5, Color.WHITE * m["alpha"])
	
	# Carica laser
	if _draw_charging_laser and player:
		var target = to_local(_laser_target)
		var c = laser_color
		c.a = 0.6 + sin(Time.get_ticks_msec() * 0.02) * 0.3
		
		# Raggio di carica pulsante
		for j in range(5):
			var thickness = 5.0 + _laser_charge_progress * 5.0 - j * 1.5
			if thickness <= 0: continue
			var col = c
			col.a = c.a * (1.0 - j * 0.18)
			draw_line(Vector2.ZERO, target, col, thickness)
		
		# Particelle sul raggio
		for i in range(15):
			var t = float(i) / 15.0
			var p = Vector2.ZERO.lerp(target, t)
			var offset = Vector2(randf() - 0.5, randf() - 0.5) * 8.0
			draw_circle(p + offset, 2.0 + randf() * 3.0, c)
	
	# Particelle laser
	for pc in _particles_laser_charge:
		var p = Vector2(cos(pc["angle"]), sin(pc["angle"])) * pc["dist"]
		var col = pc["color"]
		col.a *= pc["life"] / laser_charge_time
		draw_circle(p, 3.0, col)
		draw_circle(p, 5.0, Color(col.r, col.g, col.b, col.a * 0.3))
	
	# LASER ATTIVI (SEZIONE INTEGRATA)
	_draw_active_lasers()
	
	# Esplosioni
	for e in _particles_explosion:
		var col = e["color"]; col.a *= e["alpha"]
		draw_arc(e["pos"], e["radius"], 0, TAU, 32, col, 5.0, false)
		for i in range(8):
			var angle = i * TAU / 8.0
			var dir = Vector2(cos(angle), sin(angle))
			draw_line(e["pos"], e["pos"] + dir * e["radius"], col, 2.0)
		# Nucleo
		draw_circle(e["pos"], e["radius"] * 0.3, Color.WHITE * e["alpha"] * 0.5)
	
	# Flash mine
	for f in _particles_mine_flash:
		var c = f["color"]; c.a *= f["alpha"]
		draw_arc(f["pos"], f["radius"], 0, TAU, 32, c, 4.0, false)
		for i in range(6):
			var angle = i * TAU / 6.0
			var dir = Vector2(cos(angle), sin(angle))
			draw_line(f["pos"], f["pos"] + dir * f["radius"] * 0.7, c, 2.0)
	
	# Esplosione di morte
	for de in _particles_death_explosion:
		var col = Color(1.0, 0.3, 0.0, de["alpha"])
		draw_arc(Vector2.ZERO, de["radius"], 0, TAU, 32, col, 3.0, false)
		col = Color(1.0, 1.0, 0.0, de["alpha"] * 0.7)
		draw_arc(Vector2.ZERO, de["radius"] * 0.7, 0, TAU, 32, col, 2.0, false)
		col = Color.WHITE
		col.a = de["alpha"] * 0.5
		draw_arc(Vector2.ZERO, de["radius"] * 0.4, 0, TAU, 32, col, 1.5, false)
	
	# Particelle rottura scudo
	for bp in _shield_break_particles:
		var col = Color(0.5, 0.8, 1.0, bp["life"] / 0.8)
		draw_circle(bp["pos"], bp["size"], col)
		draw_line(bp["pos"], bp["pos"] - bp["vel"].normalized() * 6.0, col, 1.0)
	
	# Overlay di transizione fase (flash bianco)
	if in_transition:
		_transition_draw_overlay()

# ============================================================
# === DISEGNO SCUDO ===========================================
# ============================================================
func _draw_shield() -> void:
	var shield_alpha = 0.4 + sin(Time.get_ticks_msec() * 0.003) * 0.1
	var shield_color = Color(0.4, 0.6, 1.0, shield_alpha)
	
	# Cerchio esterno (bolle energetiche)
	for p in _shield_particles:
		var angle = p["angle"]
		var dist = p["dist"] + sin(Time.get_ticks_msec() * 0.002 + angle) * 5.0
		var pos = Vector2(cos(angle), sin(angle)) * dist
		var col = Color(0.5, 0.7, 1.0, p["alpha"] * shield_alpha)
		draw_circle(pos, p["size"], col)
	
	# Linee di connessione
	for i in range(_shield_particles.size()):
		var a1 = _shield_particles[i]["angle"]
		var d1 = _shield_particles[i]["dist"]
		var p1 = Vector2(cos(a1), sin(a1)) * d1
		
		var next_i = (i + 1) % _shield_particles.size()
		var a2 = _shield_particles[next_i]["angle"]
		var d2 = _shield_particles[next_i]["dist"]
		var p2 = Vector2(cos(a2), sin(a2)) * d2
		
		var col = Color(0.5, 0.7, 1.0, shield_alpha * 0.3)
		draw_line(p1, p2, col, 1.0)

# ============================================================
# === DISEGNO ORBITE ENERGETICHE ==============================
# ============================================================
func _draw_energy_orbits() -> void:
	for orb in _particles_energy_orbits:
		var col = orb["color"]
		var radius = orb["radius"]
		
		# Trail
		for i in range(orb["trail"].size()):
			var trail_angle = orb["trail"][i]
			var alpha = float(i) / orb["trail"].size() * 0.4
			var trail_pos = Vector2(cos(trail_angle), sin(trail_angle)) * radius
			var trail_col = col
			trail_col.a *= alpha
			draw_circle(trail_pos, orb["size"] * 0.5, trail_col)
		
		# Corpo principale
		var pos = Vector2(cos(orb["angle"]), sin(orb["angle"])) * radius
		col.a *= 0.9
		draw_circle(pos, orb["size"], col)
		draw_circle(pos, orb["size"] * 1.5, Color(col.r, col.g, col.b, col.a * 0.3))

# ============================================================
# === DISEGNO LASER ATTIVI ====================================
# ============================================================
func _draw_active_lasers() -> void:
	for laser in active_lasers:
		var origin = to_local(laser["origin"])
		var end = to_local(laser["end"])
		var timer = laser["timer"]
		var lifetime = laser["lifetime"]
		var fade = 1.0 - (timer / lifetime)
		
		if fade <= 0.05:
			continue
		
		var col_nucleo = laser["color"]
		var col_alone = laser["glow_color"]
		var thickness = laser["thickness"]
		
		var flicker = 1.0 + sin(Time.get_ticks_msec() * 0.03 + active_lasers.find(laser) * 1.7) * 0.15
		fade *= flicker
		fade = clamp(fade, 0.0, 1.0)
		
		# Alone esterno
		col_alone.a = fade * 0.6
		draw_line(origin, end, col_alone, thickness * 4.0)
		
		# Alone intermedio
		var col_mid = col_nucleo
		col_mid.a = fade * 0.4
		draw_line(origin, end, col_mid, thickness * 2.0)
		
		# Nucleo bianco
		var col_bianco = Color.WHITE
		col_bianco.a = fade * 0.9
		draw_line(origin, end, col_bianco, thickness * 0.5)
		
		# Nucleo colorato
		col_nucleo.a = fade
		draw_line(origin, end, col_nucleo, thickness)
		
		# Scintille lungo il raggio
		var distanza = origin.distance_to(end)
		var num_scintille = int(distanza / 20.0)
		for i in range(num_scintille):
			var t = float(i) / num_scintille
			var punto_base = origin.lerp(end, t)
			var offset_x = sin(Time.get_ticks_msec() * 0.01 + i * 2.3) * 4.0
			var offset_y = cos(Time.get_ticks_msec() * 0.015 + i * 1.7) * 4.0
			var punto_spark = punto_base + Vector2(offset_x, offset_y)
			var col_spark = Color(1.0, 0.9, 0.2, fade * 0.7)
			draw_circle(punto_spark, 1.5, col_spark)
		
		# Origine
		draw_circle(origin, 8.0 * fade, col_nucleo * 0.5)
		draw_circle(origin, 4.0 * fade, Color.WHITE * 0.8)
		draw_circle(origin, 1.5 * fade, Color.WHITE)
		
		for j in range(3):
			var rad_alone = j * 6.0 + 3.0
			var col_anello = col_nucleo
			col_anello.a = fade * (0.4 - j * 0.12)
			draw_arc(origin, rad_alone, 0, TAU, 16, col_anello, 1.5, false)
		
		# Impatto
		if laser["has_impact"]:
			var col_impatto = Color(1.0, 0.9, 0.3, fade)
			draw_circle(end, 10.0 * fade, col_impatto * 0.3)
			draw_arc(end, 12.0 * fade, 0, TAU, 32, col_impatto, 3.0, false)
			
			for i in range(8):
				var angle = Time.get_ticks_msec() * 0.003 + i * TAU / 8.0
				var dir = Vector2(cos(angle), sin(angle))
				var lunghezza = 15.0 * fade + sin(Time.get_ticks_msec() * 0.02 + i) * 5.0
				draw_line(end, end + dir * lunghezza, col_impatto, 2.0 * fade)
			
			draw_circle(end, 4.0 * fade, Color.WHITE * fade)
			draw_circle(end, 2.0 * fade, col_impatto * 1.5)
			
			for i in range(6):
				var angle_spark = i * TAU / 6.0 + Time.get_ticks_msec() * 0.005
				var spark_pos = end + Vector2(cos(angle_spark), sin(angle_spark)) * (8.0 * fade)
				var col_spark = Color(1.0, 0.8, 0.1, fade * 0.9)
				draw_circle(spark_pos, 2.0, col_spark)

func _draw_lightning(start: Vector2, end: Vector2, color: Color, segments: int) -> void:
	var points = [start]
	for i in range(segments):
		var t = float(i + 1) / float(segments + 1)
		var p = start.lerp(end, t)
		p += Vector2(randf_range(-20, 20), randf_range(-20, 20))
		points.append(p)
	points.append(end)
	
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, 2.0 + randf())
		# Bagliore fulmineo
		var glow = color; glow.a *= 0.3
		draw_line(points[i], points[i + 1], glow, 4.0)

# ============================================================
# === ANIMAZIONE TRANSIZIONE FASE (POTENZIATA) ================
# ============================================================
func _transition_draw_overlay() -> void:
	var progress = _transition_elapsed / phase_transition_duration
	
	# Flash iniziale
	if progress < 0.15:
		var alpha = 1.0 - (progress / 0.15)
		var c = transition_flash_color; c.a *= alpha
		draw_rect(Rect2(-300, -300, 600, 600), c)
		# Linee radiali
		for i in range(16):
			var angle = i * TAU / 16.0
			var dir = Vector2(cos(angle), sin(angle))
			draw_line(Vector2.ZERO, dir * 300.0, Color.WHITE * alpha * 0.5, 2.0)
	
	# Espansione energetica
	elif progress >= 0.15 and progress < 0.45:
		var exp_progress = (progress - 0.15) / 0.3
		for j in range(5):
			var radius = 50.0 + exp_progress * 250.0 + j * 30.0
			var alpha = (1.0 - exp_progress) * (1.0 - j * 0.2)
			if alpha <= 0: continue
			var c = Color(1.0, 0.8, 0.3, alpha)
			draw_arc(Vector2.ZERO, radius, 0, TAU, 64, c, 4.0 - j * 0.5, false)
	
	# Contrazione e pulsazione
	elif progress >= 0.45 and progress < 0.7:
		var cont_progress = (progress - 0.45) / 0.25
		var pulse = sin(cont_progress * PI * 2)
		var c = transition_flash_color; c.a *= 0.3 + abs(pulse) * 0.4
		draw_arc(Vector2.ZERO, 120.0 + pulse * 40.0, 0, TAU, 64, c, 6.0, false)
		
		# Vortex energetico
		for i in range(12):
			var angle = Time.get_ticks_msec() * 0.005 + i * TAU / 12.0
			var dist = 80.0 + cont_progress * 100.0
			var pos = Vector2(cos(angle), sin(angle)) * dist
			draw_circle(pos, 3.0, Color(1.0, 0.6, 0.1, 0.6))
	
	# Rilascio finale
	else:
		var end_progress = (progress - 0.7) / 0.3
		for i in range(transition_shockwave_rings):
			var radius = 100.0 + end_progress * 350.0 + i * 40.0
			var alpha = (1.0 - end_progress) * (0.8 - i * 0.1)
			if alpha <= 0: continue
			var c = transition_flash_color; c.a *= alpha
			draw_arc(Vector2.ZERO, radius, 0, TAU, 64, c, 3.0, false)

func _update_phase_transition(delta: float) -> void:
	_transition_elapsed += delta
	var progress = _transition_elapsed / phase_transition_duration
	
	# Animazione scala potenziata
	if sprite:
		var scale_target = _original_scale
		if progress < 0.15:
			var t = progress / 0.15
			scale_target = _original_scale * lerp(1.0, transition_scale_bump, t)
		elif progress < 0.4:
			var t = (progress - 0.15) / 0.25
			scale_target = _original_scale * lerp(transition_scale_bump, 0.7, t)
		elif progress < 0.55:
			var t = (progress - 0.4) / 0.15
			scale_target = _original_scale * lerp(0.7, transition_scale_bump * 1.1, t)
		elif progress < 0.75:
			var t = (progress - 0.55) / 0.2
			scale_target = _original_scale * lerp(transition_scale_bump * 1.1, transition_scale_bump * 0.85, t)
		else:
			var t = (progress - 0.75) / 0.25
			scale_target = _original_scale * lerp(transition_scale_bump * 0.85, 1.0, t)
		sprite.scale = scale_target
	
	# Spark iniziali
	if not _transition_sparks_spawned and progress > 0.05:
		_transition_sparks_spawned = true
		_spawn_sparks(global_position, transition_spark_count, transition_flash_color)
		# Aggiungi fulmini radiali
		for i in range(6):
			var angle = i * TAU / 6.0
			var end_pos = global_position + Vector2(cos(angle), sin(angle)) * 200.0
			_particles_lightning.append({
				"start": global_position,
				"end": end_pos,
				"life": 0.4,
				"color": transition_flash_color,
				"segments": 6
			})
	
	# Spark a metà
	if not _transition_mid_sparks_spawned and progress > 0.45:
		_transition_mid_sparks_spawned = true
		_spawn_sparks(global_position, transition_spark_count / 2, transition_flash_color)
		for i in range(transition_lightning_count):
			if player:
				var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
				_particles_lightning.append({
					"start": global_position,
					"end": player.global_position + offset,
					"life": 0.3,
					"color": transition_flash_color,
					"segments": 6
				})
	
	# Anelli d'urto
	var ring_interval = phase_transition_duration / (transition_shockwave_rings * 2)
	var ring_index = int(progress * transition_shockwave_rings * 2)
	if ring_index < transition_shockwave_rings * 2:
		var ring_progress = (progress * transition_shockwave_rings * 2) - ring_index
		if ring_progress < delta * 2:
			_particles_rings.append({
				"radius": 30.0,
				"alpha": 1.0,
				"color": transition_flash_color,
				"max_radius": 250.0 + ring_index * 40,
				"speed": 400.0 + ring_index * 80
			})
	
	# Fine transizione
	if _transition_elapsed >= phase_transition_duration:
		_transition_finish()

func _transition_finish() -> void:
	in_transition = false
	if sprite:
		sprite.scale = _original_scale
	if invincible_during_transition:
		is_invincible = false
	can_move = true
	queue_redraw()

# ============================================================
# === FASI ====================================================
# ============================================================
func _phase_one(delta: float) -> void:
	_smart_move(delta)
	if rng.randf() < shoot_probability: _basic_shoot()
	if use_spread and rng.randf() < spread_probability: _spread_fire()
	if use_laser and rng.randf() < laser_probability: _spawn_laser()
	if use_orbital_bullets and rng.randf() < orbital_probability: _orbital_attack()

func _phase_two(delta: float) -> void:
	_smart_move(delta)
	if rng.randf() < shoot_probability * 1.4: _basic_shoot()
	if use_spread and rng.randf() < spread_probability * 1.5: _spread_fire()
	if use_laser and rng.randf() < laser_probability * 1.5: _spawn_laser()
	if use_mines and rng.randf() < mine_probability: _drop_mines()
	if use_orbital_bullets and rng.randf() < orbital_probability * 1.4: _orbital_attack()
	if use_vortex and rng.randf() < vortex_probability: _vortex_attack()

func _phase_three(delta: float) -> void:
	_smart_move(delta)
	if rng.randf() < shoot_probability * 1.8: _basic_shoot()
	if use_spread and rng.randf() < spread_probability * 2.0: _spread_fire()
	if use_laser and rng.randf() < laser_probability * 2.0: _spawn_laser()
	if use_mines and rng.randf() < mine_probability * 1.6: _drop_mines()
	if use_rocket_barrage and rng.randf() < rocket_probability: _rocket_barrage()
	if use_orbital_bullets and rng.randf() < orbital_probability * 1.8: _orbital_attack()
	if use_vortex and rng.randf() < vortex_probability * 1.5: _vortex_attack()

# ============================================================
# === SISTEMA DI MOVIMENTO UNIFICATO ==========================
# ============================================================
func _smart_move(delta: float) -> void:
	if not can_move or not player: return
	
	match movement_type:
		MovementType.RANDOM: _move_random(delta)
		MovementType.ORBITAL: _move_orbital(delta)
		MovementType.FLOATING: _move_floating(delta)

func _move_random(delta: float) -> void:
	if not player: return
	
	_random_timer -= delta
	if _random_timer <= 0.0:
		_random_timer = random_new_target_interval * rng.randf_range(0.7, 1.3)
		_random_target = _get_random_position_around_player()
	
	var dist = global_position.distance_to(player.global_position)
	var dir_to_target = (_random_target - global_position).normalized()
	var dir_from_player = (global_position - player.global_position).normalized()
	
	if dist < flee_distance:
		velocity = dir_from_player * _speed * 1.5
	elif dist > max_distance:
		velocity = (player.global_position - global_position).normalized() * _speed
	else:
		velocity = dir_to_target * _speed * 0.6
		if global_position.distance_to(_random_target) < 30.0:
			_random_target = _get_random_position_around_player()
	
	move_and_slide()

func _move_orbital(delta: float) -> void:
	if not player: return
	
	var dist = global_position.distance_to(player.global_position)
	_current_orbit_angle += deg_to_rad(orbit_speed) * delta
	
	var target_radius = orbit_radius
	var dir_from_player = (global_position - player.global_position).normalized()
	
	if dist < flee_distance:
		var flee_factor = (flee_distance - dist) / flee_distance
		target_radius += flee_factor * 200.0
	
	var target_pos = player.global_position + Vector2(cos(_current_orbit_angle), sin(_current_orbit_angle)) * target_radius
	
	var dir = (target_pos - global_position).normalized()
	var speed_mult = clamp(abs(dist - target_radius) / 100.0, 0.3, 1.5)
	velocity = dir * _speed * speed_mult
	
	move_and_slide()

func _move_floating(delta: float) -> void:
	if not player: return
	
	_float_time += delta
	_float_reposition_timer -= delta
	
	if _float_reposition_timer <= 0.0 and not _is_dashing:
		_is_dashing = true
		_dash_timer = float_dash_duration
		_float_reposition_timer = float_reposition_interval * rng.randf_range(0.8, 1.2)
		_float_target_position = _get_random_position_around_player()
		_dash_direction = (_float_target_position - global_position).normalized()
		
		_spawn_sparks(global_position, 15, Color(0.5, 0.8, 1.0, 0.8))
	
	if _is_dashing:
		_dash_timer -= delta
		velocity = _dash_direction * float_dash_speed
		
		if int(_dash_timer * 60) % 3 == 0:
			_spawn_sparks(global_position, 3, Color(0.5, 0.8, 1.0, 0.6))
		
		if _dash_timer <= 0.0:
			_is_dashing = false
			_float_base_position = _float_target_position
			_particles_rings.append({
				"radius": 20.0,
				"alpha": 0.7,
				"color": Color(0.5, 0.8, 1.0, 0.5),
				"max_radius": 120.0,
				"speed": 350.0
			})
	else:
		var float_offset = Vector2(
			sin(_float_time * float_frequency) * float_amplitude,
			cos(_float_time * float_frequency * 1.3) * float_amplitude * 0.7
		)
		var target_pos = _float_base_position + float_offset
		
		var dist = global_position.distance_to(player.global_position)
		var dir_from_player = (global_position - player.global_position).normalized()
		
		if dist < flee_distance:
			_float_base_position += dir_from_player * _speed * 1.5 * delta
			_float_base_position = _clamp_distance_from_player(_float_base_position, flee_distance, max_distance)
		
		var dir = (target_pos - global_position).normalized()
		var dist_to_target = global_position.distance_to(target_pos)
		velocity = dir * min(_speed * 0.5, dist_to_target * 5.0)
	
	move_and_slide()

func _get_random_position_around_player() -> Vector2:
	if not player:
		return global_position
	
	var angle = rng.randf() * TAU
	var dist = rng.randf_range(preferred_distance, max_distance)
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	
	return _clamp_distance_from_player(pos, preferred_distance, max_distance)

func _clamp_distance_from_player(pos: Vector2, min_dist: float, max_dist: float) -> Vector2:
	if not player:
		return pos
	
	var dir = (pos - player.global_position).normalized()
	var dist = pos.distance_to(player.global_position)
	
	if dist < min_dist:
		return player.global_position + dir * min_dist
	elif dist > max_dist:
		return player.global_position + dir * max_dist
	
	return pos

# ============================================================
# === TRANSIZIONI (POTENZIATE) ================================
# ============================================================
func _on_damage(amount: int) -> void:
	if is_invincible or in_transition: return
	if use_shield and _shield_hp_current > 0:
		_shield_hp_current -= amount
		_update_shield_label()
		if _shield_hp_current <= 0:
			_shield_hp_current = 0
			_break_shield()
			if can_regen:
				can_regen = false
				$ShieldRegenTimer.start()
		return

	_current_hp -= amount
	Global.set(hp_key, _current_hp)
	
	_spawn_sparks(global_position, 25, Color(1, 1, 1, 0.8))
	if player:
		_particles_lightning.append({
			"start": global_position,
			"end": player.global_position,
			"life": 0.2,
			"color": Color(1, 0.5, 0, 0.7),
			"segments": 8
		})
	
	if _current_hp <= 0:
		_die()
		return

	var ratio = float(_current_hp) / float(_max_hp)
	if use_phase_two and phase == 1 and ratio <= phase_two_threshold: _enter_phase(2)
	elif use_phase_three and phase == 2 and ratio <= phase_three_threshold: _enter_phase(3)

func _break_shield() -> void:
	# Esplosione scudo
	_spawn_explosion(Vector2.ZERO, Color(0.4, 0.6, 1.0, 0.8))
	
	# Particelle rottura scudo
	for i in range(30):
		var angle = rng.randf() * TAU
		var speed = rng.randf_range(50, 200)
		_shield_break_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": rng.randf_range(0.4, 1.0),
			"size": 2.0 + randf() * 4.0
		})
	
	# Fulmini
	for i in range(5):
		var angle = i * TAU / 5.0
		_particles_lightning.append({
			"start": Vector2.ZERO,
			"end": Vector2(cos(angle), sin(angle)) * 150.0,
			"life": 0.3,
			"color": Color(0.5, 0.7, 1.0, 0.8),
			"segments": 5
		})

func _enter_phase(p: int) -> void:
	phase = p
	can_move = false
	attacking = false
	in_transition = true
	_transition_elapsed = 0.0
	_transition_sparks_spawned = false
	_transition_mid_sparks_spawned = false
	
	if invincible_during_transition:
		is_invincible = true
	
	match p:
		2:
			if phase_2_texture:
				sprite.texture = phase_2_texture
				$FXShadow.texture = phase_2_texture
		3:
			if phase_3_texture:
				sprite.texture = phase_3_texture
				$FXShadow.texture = phase_3_texture
	
	var new_color = aura_color_p2 if p == 2 else aura_color_p3
	_particles_aura.clear()
	_particles_aura.append({"radius": 80.0, "alpha": 1.0, "color": new_color, "speed": 30.0, "pulse": 0.0})
	
	# Aggiorna orbite energetiche
	for orb in _particles_energy_orbits:
		orb["color"] = new_color
		orb["speed"] *= 1.3
	
	# Effetti transizione
	_spawn_explosion(global_position, new_color)
	_spawn_sparks(global_position, 50, new_color)
	
	for i in range(8):
		_particles_rings.append({
			"radius": 30.0,
			"alpha": 1.0,
			"color": new_color,
			"max_radius": 350.0 + i * 60,
			"speed": 450.0 + i * 120
		})
	
	_play_anim("transform_p" + str(p))
	if "screen_shake" in Global:
		Global.screen_shake(0.5, 15)
	
	await get_tree().create_timer(phase_transition_duration).timeout
	_transition_finish()

# ============================================================
# === ATTACCHI ================================================
# ============================================================
func _basic_shoot() -> void:
	if not player or not bullet_scene: return
	var count = bullet_count_easy if _effective_difficulty == "easy" else (bullet_count_medium if _effective_difficulty == "medium" else bullet_count_hard)
	var spd = bullet_speed_easy if _effective_difficulty == "easy" else (bullet_speed_medium if _effective_difficulty == "medium" else bullet_speed_hard)
	var base_dir = (player.global_position - global_position).normalized()
	_play_anim("shoot")
	_spawn_sparks(global_position, 8, bullet_color)
	
	for i in range(count):
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position
		var spread = (i - count / 2.0) * bullet_spread_deg
		b.direction = base_dir.rotated(deg_to_rad(spread))
		b.speed = spd * _endless_scale

func _spread_fire() -> void:
	if not bullet_scene: return
	var count = spread_count_easy if _effective_difficulty == "easy" else (spread_count_medium if _effective_difficulty == "medium" else spread_count_hard)
	var step = TAU / count
	_play_anim("spread_fire")
	for i in range(spread_ring_count):
		_particles_rings.append({
			"radius": 40.0,
			"alpha": 1.0,
			"color": spread_color,
			"max_radius": 250.0 + i * 40,
			"speed": 500.0 + i * 80
		})
	
	for i in range(count):
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position
		b.direction = Vector2.RIGHT.rotated(step * i + _spread_rotation_offset)
		b.speed = (280 + rng.randf_range(-40, 60)) * _endless_scale
	if spread_rotated:
		_spread_rotation_offset += deg_to_rad(15)

func _spawn_laser() -> void:
	if not player: return
	
	var count = laser_count_easy if _effective_difficulty == "easy" else (laser_count_medium if _effective_difficulty == "medium" else laser_count_hard)
	
	_play_anim("laser_charge")
	
	_draw_charging_laser = true
	_laser_target = player.global_position
	_laser_charge_progress = 0.0
	
	_particles_laser_charge.clear()
	for i in range(25):
		var angle = rng.randf() * TAU
		_particles_laser_charge.append({
			"angle": angle,
			"dist": rng.randf_range(30, 80),
			"life": laser_charge_time,
			"color": laser_color,
			"size": rng.randf_range(2.0, 5.0)
		})
	
	await get_tree().create_timer(laser_charge_time).timeout
	_draw_charging_laser = false
	
	_play_anim("laser_fire")
	
	for i in range(count):
		var target_pos = player.global_position
		var direction_to_player = (target_pos - global_position).normalized()
		
		var spread_angle = deg_to_rad(rng.randf_range(-25.0, 25.0))
		var final_direction = direction_to_player.rotated(spread_angle)
		
		var start_offset = Vector2(
			rng.randf_range(-laser_offset_range, laser_offset_range),
			rng.randf_range(-laser_offset_range, laser_offset_range)
		)
		
		var target_point = global_position + start_offset + final_direction * laser_length
		
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(
			global_position + start_offset,
			target_point
		)
		query.exclude = [self]
		
		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			target_point = result.position
			if result.collider.is_in_group("player") and result.collider.has_method("take_damage"):
				result.collider.take_damage(laser_damage)
		
		active_lasers.append({
			"origin": global_position + start_offset,
			"end": target_point,
			"lifetime": laser_lifetime,
			"timer": 0.0,
			"color": laser_color,
			"glow_color": laser_glow_color,
			"thickness": laser_thickness,
			"has_impact": not result.is_empty()
		})
		
		if i < count - 1:
			await get_tree().create_timer(0.04).timeout

func _process_lasers(delta: float) -> void:
	var to_remove = []
	for i in range(active_lasers.size()):
		active_lasers[i]["timer"] += delta
		if active_lasers[i]["timer"] >= active_lasers[i]["lifetime"]:
			to_remove.append(i)
	
	for i in to_remove:
		active_lasers.remove_at(i)

func _drop_mines() -> void:
	if not mine_scene: return
	var count = mine_count_easy if _effective_difficulty == "easy" else (mine_count_medium if _effective_difficulty == "medium" else mine_count_hard)
	_play_anim("mine_drop")
	
	for i in range(count):
		var pos = global_position + Vector2(rng.randf_range(-mine_spread_radius, mine_spread_radius), rng.randf_range(-mine_spread_radius, mine_spread_radius))
		_particles_mine_flash.append({
			"pos": pos,
			"radius": 30.0,
			"alpha": 1.0,
			"color": mine_color
		})
		_spawn_sparks(pos, 5, mine_color)
		var m = mine_scene.instantiate()
		get_parent().add_child(m)
		m.global_position = pos

func _rocket_barrage() -> void:
	if attacking: return
	attacking = true
	var count = rocket_count_easy if _effective_difficulty == "easy" else (rocket_count_medium if _effective_difficulty == "medium" else rocket_count_hard)
	var dmg = rocket_damage_easy if _effective_difficulty == "easy" else (rocket_damage_medium if _effective_difficulty == "medium" else rocket_damage_hard)
	dmg *= _endless_scale
	_play_anim("rocket_fire")

	var targets: Array[Vector2] = []
	for i in range(count):
		var t: Vector2
		if player and rng.randf() < 0.7:
			t = player.global_position + Vector2(rng.randf_range(-150, 150), rng.randf_range(-150, 150))
		else:
			t = global_position + Vector2(rng.randf_range(-400, 400), rng.randf_range(-400, 400))
		targets.append(t)
		
		_particles_rocket_markers.append({
			"pos": t,
			"alpha": 1.0,
			"color": rocket_color,
			"life": rocket_warning_time + 1.0
		})

	await get_tree().create_timer(rocket_warning_time).timeout

	for i in range(targets.size()):
		if explosion_scene:
			var e = explosion_scene.instantiate()
			get_parent().add_child(e)
			e.global_position = targets[i]
			e.scale = Vector2.ONE * (rocket_blast_radius / 70.0)
		if player and player.global_position.distance_to(targets[i]) < rocket_blast_radius:
			Global.player_hp -= dmg
			Global.hurt = true
		
		_spawn_explosion(targets[i], rocket_color)
		_spawn_sparks(targets[i], 20, rocket_color)

	if "screen_shake" in Global:
		Global.screen_shake(0.6, 20)
	await get_tree().create_timer(0.5).timeout
	attacking = false

func _orbital_attack() -> void:
	if attacking or not bullet_scene: return
	attacking = true
	_play_anim("orbital_spin")

	var bullets_per_ring = bullet_ring
	var rings: Array = []

	for ring_i in range(orbital_ring_count):
		var ring_bullets: Array = []
		for i in range(bullets_per_ring):
			var b = bullet_scene.instantiate()
			get_parent().add_child(b)
			b.global_position = global_position
			b.speed = 0
			ring_bullets.append(b)
		rings.append(ring_bullets)

	for i in range(5):
		_particles_rings.append({
			"radius": 80.0,
			"alpha": 0.8,
			"color": orbital_color,
			"max_radius": 250.0 + i * 60,
			"speed": 350.0
		})

	var elapsed = 0.0
	var orbit_r = 100.0 + orbital_ring_count * 30.0
	while elapsed < orbital_duration:
		for ring_i in range(rings.size()):
			for i in range(rings[ring_i].size()):
				var b = rings[ring_i][i]
				if not is_instance_valid(b): continue
				var angle = (TAU / rings[ring_i].size()) * i + deg_to_rad(orbital_speed_deg) * elapsed + ring_i * PI
				b.global_position = global_position + Vector2(cos(angle), sin(angle)) * (orbit_r + ring_i * 60)
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	for ring_arr in rings:
		for b in ring_arr:
			if not is_instance_valid(b): continue
			if player:
				b.direction = (player.global_position - b.global_position).normalized()
				b.speed = 300 * _endless_scale
			else:
				b.queue_free()

	await get_tree().create_timer(0.3).timeout
	attacking = false

func _vortex_attack() -> void:
	if attacking or not bullet_scene: return
	attacking = true
	var step = vortex_step_deg_easy if _effective_difficulty == "easy" else (vortex_step_deg_medium if _effective_difficulty == "medium" else vortex_step_deg_hard)

	_spawn_explosion(global_position, vortex_color)
	for i in range(6):
		_particles_rings.append({
			"radius": 50.0,
			"alpha": 1.0,
			"color": vortex_color,
			"max_radius": 450.0 + i * 80,
			"speed": 650.0 + i * 140
		})

	var elapsed = 0.0
	var rate = 0.14
	while elapsed < vortex_duration:
		for angle in range(0, 360, step):
			var b = bullet_scene.instantiate()
			get_parent().add_child(b)
			b.global_position = global_position
			b.direction = Vector2.RIGHT.rotated(deg_to_rad(angle + elapsed * 50))
			b.speed = (260 + rng.randf_range(-40, 80)) * _endless_scale
		await get_tree().create_timer(rate).timeout
		elapsed += rate
		if elapsed > vortex_duration * 0.5:
			rate = 0.08

	await get_tree().create_timer(0.3).timeout
	attacking = false

# ============================================================
# === FUNZIONI DI SUPPORTO EFFETTI ============================
# ============================================================
func _spawn_sparks(position: Vector2, count: int, color: Color) -> void:
	for i in range(count):
		var angle = rng.randf() * TAU
		var speed = rng.randf_range(100, 350)
		_particles_sparks.append({
			"pos": position,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": rng.randf_range(0.3, 0.9),
			"color": color
		})

func _spawn_explosion(position: Vector2, color: Color) -> void:
	_particles_explosion.append({
		"pos": position,
		"radius": 20.0,
		"alpha": 1.0,
		"color": color
	})

# ============================================================
# === SHIELD ==================================================
# ============================================================
func _update_shield_label() -> void:
	if has_node("Sprite2D/ShieldHPL1"): $Sprite2D/ShieldHPL1.text = str(_shield_hp_current)
	if has_node("Sprite2D/ShieldHPL2"): $Sprite2D/ShieldHPL2.text = str(_shield_hp_current)

func _on_shield_regen_timer_timeout() -> void:
	can_regen = true
	match _effective_difficulty:
		"easy":   _shield_hp_current = shield_hp_easy
		"medium": _shield_hp_current = shield_hp_medium
		"hard":   _shield_hp_current = shield_hp_hard
	_update_shield_label()
	_init_shield_particles()
	# Effetto rigenerazione scudo
	_particles_rings.append({
		"radius": 50.0,
		"alpha": 0.8,
		"color": Color(0.4, 0.6, 1.0, 0.6),
		"max_radius": 200.0,
		"speed": 400.0
	})

func _on_shield_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		var dmg := _get_bullet_damage(area)
		area.queue_free()
		_on_damage(int(dmg))
		_spawn_damage_popup(int(dmg))

# ============================================================
# === UTILITY =================================================
# ============================================================
func _scale(t: float) -> float:
	match _effective_difficulty:
		"easy": return t * 1.3
		"medium": return t
		"hard": return t * 0.6
		_: return t

func _play_anim(name: String) -> void:
	if anim and anim.has_animation(name) and anim.current_animation != name:
		anim.play(name)

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		var dmg := _get_bullet_damage(area)
		_on_damage(int(dmg))
		area.queue_free()
		_spawn_damage_popup(int(dmg))

func _get_bullet_damage(area: Area2D) -> float:
	if area.has_meta("damage"): return area.get_meta("damage")
	elif GlobalWeapons.current_weapon.has("damage"): return GlobalWeapons.current_weapon["damage"]
	return 10.0 * Global.player_damage

func _spawn_damage_popup(amount: int) -> void:
	if not is_inside_tree(): return
	var s = load("res://Gres/Scenes/UI/damage_label.tscn")
	if not s: return
	var lbl = s.instantiate()
	get_tree().get_root().add_child(lbl)
	lbl.show_damage(amount, global_position)

# ============================================================
# === MORTE (EPICA) ===========================================
# ============================================================
func _die() -> void:
	if can_die:
		can_die = false
		if has_node("HurtBox"):
			GlobalTweens.deactivate($HurtBox)
		
		# Esplosione di morte epica
		_spawn_death_explosion()
		
		$DeadTime.start()

func _spawn_death_explosion() -> void:
	# Esplosioni multiple concentriche
	for i in range(8):
		_particles_death_explosion.append({
			"radius": 30.0 + i * 20.0,
			"alpha": 1.0,
			"speed": 150.0 + i * 80.0,
			"life": 1.5 + i * 0.3
		})
	
	# Scintille massicce
	_spawn_sparks(global_position, 80, Color(1.0, 0.5, 0.0, 0.9))
	_spawn_sparks(global_position, 40, Color(1.0, 1.0, 0.0, 0.7))
	
	# Fulmini radiali
	for i in range(12):
		var angle = i * TAU / 12.0
		var end_pos = global_position + Vector2(cos(angle), sin(angle)) * 300.0
		_particles_lightning.append({
			"start": global_position,
			"end": end_pos,
			"life": 0.6,
			"color": Color(1.0, 0.3, 0.0, 0.9),
			"segments": 8
		})
	
	# Anelli d'urto
	for i in range(6):
		_particles_rings.append({
			"radius": 40.0,
			"alpha": 1.0,
			"color": Color(1.0, 0.2, 0.0, 0.8),
			"max_radius": 500.0 + i * 80,
			"speed": 600.0 + i * 150
		})
	
	if "screen_shake" in Global:
		Global.screen_shake(1.0, 30)

func _death_cleanup() -> void:
	GlobalStats.kill_boss_total += 1
	Global.boss_killed = true
	GlobalStats.gold += randi_range(gold_min, gold_max)
	var diff = _effective_difficulty
	Global.update_mission_progress(
		mission_key_easy if diff == "easy" else (mission_key_medium if diff == "medium" else mission_key_hard), 1)
	if randf() < (shard_chance_easy if diff == "easy" else (shard_chance_medium if diff == "medium" else shard_chance_hard)):
		_drop_shard()
	if randf() < (tablet_chance_easy if diff == "easy" else (tablet_chance_medium if diff == "medium" else tablet_chance_hard)):
		GlobalStats.tablet += 1
	if randf() < spin_gem_chance: Global.spin_gem += 1
	Global.register_found_weapon(legendary_weapon_drop, "legendary")
	if can_tp_scene: get_tree().change_scene_to_file(death_scene_path)
	$Dead.play("death")

func _drop_shard() -> void:
	match ["ice","magma","light","void"].pick_random():
		"ice":   GlobalStats.ice_shard += 1
		"magma": GlobalStats.magma_shard += 1
		"light": GlobalStats.light_shard += 1
		"void":  GlobalStats.void_shard += 1

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death": queue_free()

func _on_dead_animation_finished(anim_name: StringName) -> void:
	queue_free()
