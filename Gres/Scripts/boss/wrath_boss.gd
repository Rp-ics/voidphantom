extends CharacterBody2D
class_name GaiaWrath

# ============================================================
# === CONFIG BASE =============================================
# ============================================================
@export var speed: float = 300.0
@export var shield_hp: int = 100
@export var phase_two_threshold := 0.6
@export var phase_three_threshold := 0.25
@export var teleport_points: Array[Node2D]
@export var minion_scene: PackedScene
@export var bullet_scene: PackedScene
@export var explosion_scene: PackedScene
@export var laser_scene: PackedScene

# ============================================================
# === ATTACK CONFIG: VORTEX ===================================
# ============================================================
@export_group("Vortex Attack")
@export var vortex_duration: float = 6.0
@export var vortex_orbit_speed_start: float = 18.0
@export var vortex_orbit_speed_burst: float = 30.0
@export var vortex_fire_rate_start: float = 0.16
@export var vortex_fire_rate_burst: float = 0.10
@export var vortex_bullet_speed_min: float = 240.0
@export var vortex_bullet_speed_max: float = 370.0
@export var vortex_step_easy: int = 20
@export var vortex_step_medium: int = 15
@export var vortex_step_hard: int = 10
@export var vortex_lightning_every_n_rings: int = 8

# ============================================================
# === ATTACK CONFIG: CHARGE DASH ==============================
# ============================================================
@export_group("Charge Dash")
@export var charge_windup: float = 0.7
@export var charge_dash_speed_normal: float = 550.0
@export var charge_dash_speed_hard: float = 750.0
@export var charge_dash_duration: float = 0.5
@export var charge_dash_count_easy: int = 2
@export var charge_dash_count_medium: int = 3
@export var charge_dash_count_hard: int = 4
@export var charge_trail_count: int = 3
@export var charge_post_delay: float = 0.5

# ============================================================
# === ATTACK CONFIG: BASIC SHOOT ==============================
# ============================================================
@export_group("Basic Shoot")
@export var shoot_bullets_easy: int = 3
@export var shoot_bullets_medium: int = 5
@export var shoot_bullets_hard: int = 8
@export var shoot_spread_easy: float = 8.0
@export var shoot_spread_medium: float = 5.0
@export var shoot_spread_hard: float = 3.0
@export var shoot_fan_spacing: float = 7.0

# ============================================================
# === ATTACK CONFIG: CRIMSON CAGE =============================
# ============================================================
@export_group("Crimson Cage")
@export var cage_radius: float = 300.0
@export var cage_bullets_easy: int = 10
@export var cage_bullets_medium: int = 14
@export var cage_bullets_hard: int = 18
@export var cage_open_width_easy: int = 140
@export var cage_open_width_medium: int = 110
@export var cage_open_width_hard: int = 70
@export var cage_escape_time_easy: float = 3.0
@export var cage_escape_time_medium: float = 2.2
@export var cage_escape_time_hard: float = 1.4
@export var cage_implosion_duration: float = 0.6

# ============================================================
# === ATTACK CONFIG: GRAVITY PULL =============================
# ============================================================
@export_group("Gravity Pull")
@export var gravity_pull_windup: float = 0.5
@export var gravity_pull_duration_normal: float = 2.0
@export var gravity_pull_duration_hard: float = 2.8
@export var gravity_pull_force_easy: float = 180.0
@export var gravity_pull_force_medium: float = 260.0
@export var gravity_pull_force_hard: float = 360.0
@export var gravity_pull_post_delay: float = 0.5

# ============================================================
# === ATTACK CONFIG: DEATH BLOSSOM ============================
# ============================================================
@export_group("Death Blossom")
@export var blossom_rings_easy: int = 3
@export var blossom_rings_medium: int = 5
@export var blossom_rings_hard: int = 8
@export var blossom_step_normal: int = 20
@export var blossom_step_hard: int = 12
@export var blossom_bullet_speed_base: float = 200.0
@export var blossom_bullet_speed_per_ring: float = 30.0
@export var blossom_ring_delay: float = 0.22
@export var blossom_post_delay: float = 0.5

# ============================================================
# === ATTACK CONFIG: LIGHTNING STORM ==========================
# ============================================================
@export_group("Lightning Storm")
@export var storm_strikes_easy: int = 4
@export var storm_strikes_medium: int = 7
@export var storm_strikes_hard: int = 12
@export var storm_radius: float = 500.0
@export var storm_player_aim_chance: float = 0.6
@export var storm_player_jitter: float = 120.0
@export var storm_strike_interval: float = 0.12
@export var storm_post_delay: float = 0.3

# ============================================================
# === ATTACK CONFIG: SUMMON MINIONS ===========================
# ============================================================
@export_group("Summon Minions")
@export var minion_count_easy: int = 3
@export var minion_count_medium: int = 5
@export var minion_count_hard: int = 7
@export var minion_spawn_radius: float = 220.0

# ============================================================
# === ATTACK CONFIG: SPAWN LASERS =============================
# ============================================================
@export_group("Spawn Lasers")
@export var laser_count_easy: int = 2
@export var laser_count_medium: int = 3
@export var laser_count_hard: int = 5
@export var laser_spawn_radius: int = 300
@export var laser_rotation_speed_min: float = 0.8
@export var laser_rotation_speed_max: float = 1.2
@export var laser_hard_speed_bonus: float = 0.3

# ============================================================
# === ATTACK CONFIG: SPAWN EXPLOSIONS =========================
# ============================================================
@export_group("Spawn Explosions")
@export var explosion_count_easy: int = 3
@export var explosion_count_medium: int = 5
@export var explosion_count_hard: int = 8
@export var explosion_scatter_radius: int = 450
@export var explosion_scale_min: float = 0.8
@export var explosion_scale_max: float = 1.6

# ============================================================
# === ATTACK CONFIG: TELEPORT =================================
# ============================================================
@export_group("Teleport")
@export var teleport_radius_min: float = 350.0
@export var teleport_radius_max: float = 500.0
@export var teleport_windup: float = 0.45

# ============================================================
# === ATTACK CONFIG: PHASE TRANSITIONS ========================
# ============================================================
@export_group("Phase Transitions")
@export var phase2_shockwave_color: Color = Color(1.0, 0.3, 0.0)
@export var phase2_shockwave_radius: float = 400.0
@export var phase2_crack_count: int = 8
@export var phase2_eye_open_duration: float = 1.5
@export var phase3_shockwave_color: Color = Color(1.0, 0.0, 0.0)
@export var phase3_shockwave_radius: float = 600.0
@export var phase3_crack_count: int = 16
@export var phase3_eye_open_duration: float = 0.8

# ============================================================
# === ATTACK CONFIG: ATTACK DELAYS ============================
# ============================================================
@export_group("Attack Timing")
@export var attack_delay: float = 2.5
@export var phase1_charge_chance: float = 0.007
@export var phase1_summon_chance: float = 0.003
@export var phase2_teleport_chance: float = 0.012
@export var phase2_vortex_chance: float = 0.025
@export var phase3_laser_chance: float = 0.03
@export var phase3_explosion_chance: float = 0.02
@export var phase3_gravity_chance: float = 0.015
@export var phase3_blossom_chance: float = 0.008
@export var phase3_storm_chance: float = 0.004
@export var phase3_teleport_chance: float = 0.010

# ============================================================
# === DEATH FX CONFIG =========================================
# ============================================================
@export_group("Death FX")
@export var death_shockwave_count: int = 5
@export var death_shockwave_interval: float = 0.35
@export var death_shockwave_max_radius: float = 800.0
@export var death_explosion_count: int = 12
@export var death_crack_count: int = 24
@export var death_lightning_bursts: int = 4
@export var death_total_duration: float = 3.5
@export var death_flash_count: int = 10
@export var death_fade_duration: float = 1.2

# ============================================================
# === RUNTIME =================================================
# ============================================================
var phase: int = 1
var attacking: bool = false
var can_move: bool = true
var can_teleport: bool = true
var player: Node2D
var rng := RandomNumberGenerator.new()
var can_regen: bool = true

# --- DRAW FX state ---
var _draw_aura_radius: float = 0.0
var _draw_aura_color: Color = Color(0.8, 0.1, 0.1, 0.0)
var _draw_rings: Array = []
var _draw_cracks: Array = []
var _draw_shockwave_radius: float = 0.0
var _draw_shockwave_alpha: float = 0.0
var _draw_shockwaves: Array = []   # multipli simultanei: [{radius, alpha, color}]
var _draw_eye_open: float = 0.0
var _draw_lightning_bolts: Array = []
var _draw_phase: int = 1
var _draw_rage_pulse: float = 0.0
var _is_dying: bool = false

# ============================================================
# === NODES ===================================================
# ============================================================
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var animfx: AnimationPlayer = $AnimFX
@onready var vortexfx: AnimationPlayer = $VortexFX
@onready var sprite: Sprite2D = $Sprite2D
@onready var fire_timer: Timer = $FireTimer
@onready var teleport_timer: Timer = $TeleportTimer

# ============================================================
# === READY ===================================================
# ============================================================
func _ready() -> void:
	match Global.dificulty:
		'easy':
			Global.wrath_max_hp = 8500
			speed = 250
			shield_hp = 100
			vortex_duration = 6.0
			attack_delay = 3.0
		'medium':
			Global.wrath_max_hp = 12600
			speed = 300
			shield_hp = 500
			vortex_duration = 7.5
			attack_delay = 2.2
		'hard':
			Global.wrath_max_hp = 18000
			speed = 360
			shield_hp = 1500
			vortex_duration = 9.0
			attack_delay = 1.4

	$Sprite2D/ShieldHPL1.text = str(shield_hp)
	$Sprite2D/ShieldHPL2.text = str(shield_hp)
	Global.wrath_hp = Global.wrath_max_hp
	player = get_tree().get_first_node_in_group("player")
	fire_timer.start()
	teleport_timer.wait_time = 10.0
	teleport_timer.start()

	_fx_start_passive_aura()

# ============================================================
# === PROCESS =================================================
# ============================================================
func _physics_process(delta: float) -> void:
	$HP.max_value = Global.wrath_max_hp
	$HP.value = Global.wrath_hp
	if _is_dying:
		return

	if Input.is_action_just_pressed("ui_accept"):
		Global.player_hp = Global.player_max_hp

	if phase == 3:
		_draw_rage_pulse = fmod(_draw_rage_pulse + delta * 3.0, TAU)

	match phase:
		1: _phase_one_behavior(delta)
		2: _phase_two_behavior(delta)
		3: _phase_three_behavior(delta)

	queue_redraw()

# ============================================================
# === DRAW (EFFETTI EPICI) ====================================
# ============================================================
func _draw() -> void:
	# --- 1. AURA PASSIVA ---
	if _draw_aura_color.a > 0.01:
		for ring in range(3):
			var r = _draw_aura_radius * (1.0 - ring * 0.2)
			var c = _draw_aura_color
			c.a *= (1.0 - ring * 0.3)
			draw_arc(Vector2.ZERO, r, 0, TAU, 64, c, 3.0 - ring * 0.5, true)

	# --- 2. SHOCKWAVE SINGOLA (legacy) ---
	if _draw_shockwave_alpha > 0.01:
		var c = Color(1.0, 0.4, 0.1, _draw_shockwave_alpha)
		draw_arc(Vector2.ZERO, _draw_shockwave_radius, 0, TAU, 80, c, 4.0, false)
		var c2 = Color(1.0, 0.8, 0.2, _draw_shockwave_alpha * 0.4)
		draw_arc(Vector2.ZERO, _draw_shockwave_radius * 0.85, 0, TAU, 80, c2, 2.0, false)

	# --- 2b. SHOCKWAVE MULTIPLE (morte) ---
	for sw in _draw_shockwaves:
		if sw["alpha"] > 0.01:
			var c = sw["color"]
			c.a = sw["alpha"]
			draw_arc(Vector2.ZERO, sw["radius"], 0, TAU, 96, c, 5.0, false)
			var c2 = sw["color"]
			c2.a = sw["alpha"] * 0.35
			draw_arc(Vector2.ZERO, sw["radius"] * 0.8, 0, TAU, 96, c2, 2.5, false)

	# --- 3. RINGS DI ENERGIA ---
	for ring_data in _draw_rings:
		var c = ring_data["color"]
		c.a = ring_data["alpha"]
		draw_arc(Vector2.ZERO, ring_data["radius"], 0, TAU, 72, c, 2.5, false)

	# --- 4. CREPE ENERGIA (FASE 2+) ---
	if _draw_phase >= 2:
		for crack in _draw_cracks:
			var c = crack["color"]
			c.a = crack["alpha"]
			draw_line(crack["from"], crack["to"], c, 1.5)

	# --- 5. OCCHIO DEL BOSS (FASE 3) ---
	if _draw_phase >= 3 and _draw_eye_open > 0.01:
		_draw_boss_eye()

	# --- 6. RAGE PULSE FASE 3 ---
	if _draw_phase >= 3:
		var pulse = abs(sin(_draw_rage_pulse))
		var rp_c = Color(1.0, 0.0, 0.0, pulse * 0.35)
		draw_arc(Vector2.ZERO, 90 + pulse * 20, 0, TAU, 64, rp_c, 6.0, false)
		var rp_c2 = Color(0.8, 0.0, 0.2, pulse * 0.15)
		draw_circle(Vector2.ZERO, 85 + pulse * 15, rp_c2)

	# --- 7. FULMINI ---
	for bolt in _draw_lightning_bolts:
		if bolt["alpha"] <= 0.01:
			continue
		var bc = bolt["color"]
		bc.a = bolt["alpha"]
		var pts: Array = bolt["points"]
		for i in range(pts.size() - 1):
			draw_line(pts[i], pts[i + 1], bc, rng.randf_range(1.0, 3.0))

func _draw_boss_eye() -> void:
	var ey = _draw_eye_open
	draw_ellipse_approx(Vector2(0, -30), Vector2(28 * ey, 14 * ey), Color(0.95, 0.95, 0.95, ey))
	draw_circle(Vector2(0, -30), 10 * ey, Color(0.9, 0.05, 0.05, ey))
	draw_circle(Vector2(0, -30), 5 * ey, Color(0.0, 0.0, 0.0, ey))
	draw_arc(Vector2(0, -30), 12 * ey, 0, TAU, 32, Color(1.0, 0.0, 0.0, ey * 0.5), 3.0, false)

func draw_ellipse_approx(center: Vector2, radii: Vector2, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(32):
		var a = (TAU / 32.0) * i
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, color)

# ============================================================
# === SCALING DIFFICOLTÀ =====================================
# ============================================================
func _scale(t: float) -> float:
	match Global.dificulty:
		"easy":   return t * 1.3
		"medium": return t
		"hard":   return t * 0.6
		_:        return t

func _bullet_count_base(n: int) -> int:
	match Global.dificulty:
		"easy":   return n
		"medium": return n + 2
		"hard":   return n + 5
		_:        return n

func _damage_multiplier() -> float:
	match Global.dificulty:
		"easy":   return 1.0
		"medium": return 1.4
		"hard":   return 2.0
		_:        return 1.0

# ============================================================
# === PHASE BEHAVIORS =========================================
# ============================================================
func _phase_one_behavior(_delta: float) -> void:
	if not can_move:
		return
	if player:
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()

	if rng.randf() < phase1_charge_chance:
		_charge_attack()
	if rng.randf() < phase1_summon_chance:
		_summon_minions()

func _phase_two_behavior(_delta: float) -> void:
	if attacking:
		return
	if rng.randf() < phase2_teleport_chance:
		_teleport_random()
	if rng.randf() < phase2_vortex_chance:
		_start_vortex_attack()
	else:
		_basic_shoot()

func _phase_three_behavior(_delta: float) -> void:
	if attacking:
		return
	if rng.randf() < phase3_laser_chance:
		_spawn_lasers()
	if rng.randf() < phase3_explosion_chance:
		_spawn_explosions()
	if rng.randf() < phase3_gravity_chance:
		_gravity_pull()
	if rng.randf() < phase3_blossom_chance:
		_death_blossom()
	if rng.randf() < phase3_storm_chance:
		_summon_lightning_storm()
	if rng.randf() < phase3_teleport_chance:
		_teleport_random()

# ============================================================
# === TRANSIZIONI FASE ========================================
# ============================================================
func _on_damage(amount: int) -> void:
	Global.wrath_hp -= amount
	if Global.wrath_hp <= 0:
		_die()
		return

	var ratio = float(Global.wrath_hp) / float(Global.wrath_max_hp)
	if phase == 1 and ratio <= phase_two_threshold:
		_enter_phase_two()
	elif phase == 2 and ratio <= phase_three_threshold:
		$Vortex.hide()
		_enter_phase_three()

func _enter_phase_two() -> void:
	phase = 2
	_draw_phase = 2
	match Global.dificulty:
		'easy':   speed = 280
		'medium': speed = 330
		'hard':   speed = 400

	_fx_shockwave(phase2_shockwave_color, phase2_shockwave_radius)
	_fx_spawn_cracks(phase2_crack_count, Color(1.0, 0.4, 0.1, 0.9))
	_fx_open_eye(phase2_eye_open_duration)

	$RotateTimer.stop()
	anim.play("transform_phase2")
	can_move = false
	await anim.animation_finished
	can_move = true

func _enter_phase_three() -> void:
	phase = 3
	_draw_phase = 3
	match Global.dificulty:
		'easy':   speed = 300
		'medium': speed = 350
		'hard':   speed = 420

	_fx_shockwave(phase3_shockwave_color, phase3_shockwave_radius)
	_fx_spawn_cracks(phase3_crack_count, Color(0.9, 0.0, 0.0, 1.0))
	_fx_summon_ring_burst(Color(1.0, 0.0, 0.1))
	_fx_open_eye(phase3_eye_open_duration)
	_draw_aura_color = Color(0.9, 0.0, 0.0, 0.7)

	anim.play("transform_phase3")
	await anim.animation_finished
	can_move = true

# ============================================================
# === ATTACCHI ================================================
# ============================================================
func _bullet_setup(bullet: Node, dir: Vector2, spd: float = 0.0) -> void:
	if bullet.has_method("setup"):
		bullet.setup(dir, spd)

# --- CHARGE ATTACK ---
func _charge_attack() -> void:
	if not can_move or attacking or not player:
		return
	attacking = true
	can_move = false

	_fx_charge_up(Color(1.0, 0.5, 0.1), _scale(charge_windup))

	if animfx.has_animation("charge"):
		animfx.play("charge")
	if GlobalTweens:
		GlobalTweens.glitch_flash(self, 8, 0.1)

	await get_tree().create_timer(_scale(charge_windup)).timeout

	var dash_count: int
	match Global.dificulty:
		"easy":   dash_count = charge_dash_count_easy
		"hard":   dash_count = charge_dash_count_hard
		_:        dash_count = charge_dash_count_medium

	for i in range(dash_count):
		if not is_instance_valid(player):
			break
		var dir = (player.global_position - global_position).normalized()
		await _perform_single_dash(dir)
		await get_tree().create_timer(0.18).timeout

	_fx_shockwave(Color(1.0, 0.4, 0.0), 250.0)
	await get_tree().create_timer(_scale(charge_post_delay)).timeout
	can_move = true
	attacking = false

func _perform_single_dash(dir: Vector2) -> void:
	var dash_speed := charge_dash_speed_hard if Global.dificulty == "hard" else charge_dash_speed_normal
	var dash_timer := 0.0

	for g in range(charge_trail_count):
		await get_tree().create_timer(0.04 * g).timeout
		var trail := Sprite2D.new()
		trail.texture = sprite.texture
		var hue = 0.05 + g * 0.03
		trail.modulate = Color(1.0, hue, 0.0, 0.5 - g * 0.1)
		trail.scale = sprite.scale * (0.95 - g * 0.08)
		trail.rotation = sprite.rotation
		trail.global_position = global_position
		get_parent().add_child(trail)
		_fade_trail(trail, 0.25)

	while dash_timer < charge_dash_duration:
		velocity = dir * dash_speed
		move_and_slide()
		await get_tree().process_frame
		dash_timer += get_process_delta_time()

	velocity = Vector2.ZERO

	_fx_shockwave(Color(1.0, 0.3, 0.0), 180.0)
	_fx_lightning_burst(4, Color(1.0, 0.8, 0.1))
	if GlobalTweens:
		GlobalTweens.glitch_flash(self, 6, 0.07)

func _fade_trail(trail: Sprite2D, duration: float) -> void:
	var elapsed := 0.0
	var start_alpha = trail.modulate.a
	while elapsed < duration and is_instance_valid(trail):
		trail.modulate.a = lerp(start_alpha, 0.0, elapsed / duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if is_instance_valid(trail):
		trail.queue_free()

func _summon_minions() -> void:
	var count: int
	match Global.dificulty:
		"easy":  count = minion_count_easy
		"hard":  count = minion_count_hard
		_:       count = minion_count_medium
	for i in range(count):
		var m = minion_scene.instantiate()
		get_parent().add_child(m)
		var angle = (TAU / count) * i
		m.global_position = global_position + Vector2(cos(angle), sin(angle)) * minion_spawn_radius
	_fx_summon_ring_burst(Color(0.8, 0.0, 1.0))

func _basic_shoot() -> void:
	if not player:
		return
	var count: int
	var spread: float
	match Global.dificulty:
		"easy":   count = shoot_bullets_easy;   spread = shoot_spread_easy
		"hard":   count = shoot_bullets_hard;   spread = shoot_spread_hard
		_:        count = shoot_bullets_medium; spread = shoot_spread_medium
	for i in range(count):
		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		var dir = (player.global_position - global_position).normalized()
		var final_dir = dir.rotated(deg_to_rad(rng.randf_range(-spread, spread) + (i - count/2) * shoot_fan_spacing))
		_bullet_setup(bullet, final_dir, 0.0)

func _start_vortex_attack() -> void:
	attacking = true
	vortexfx.play("vortex_start")
	await vortexfx.animation_finished

	var elapsed := 0.0
	var orbit_speed := vortex_orbit_speed_start
	var vortex_rate := vortex_fire_rate_start
	var burst_ready := false
	var rings_fired := 0

	_fx_summon_ring_burst(Color(1.0, 0.2, 0.0))
	_fx_open_eye(0.3)

	while elapsed < vortex_duration:
		var step: int
		match Global.dificulty:
			"easy": step = vortex_step_easy
			"hard": step = vortex_step_hard
			_:      step = vortex_step_medium
		for angle in range(0, 360, step):
			var b = bullet_scene.instantiate()
			get_parent().add_child(b)
			b.global_position = global_position
			var offset_angle = deg_to_rad(angle + rng.randi_range(-4, 4))
			var dir = Vector2.RIGHT.rotated(offset_angle)
			var spd = rng.randf_range(vortex_bullet_speed_min, vortex_bullet_speed_max)
			_bullet_setup(b, dir, spd)

		await get_tree().create_timer(vortex_rate).timeout
		sprite.rotation += deg_to_rad(orbit_speed)
		elapsed += vortex_rate
		rings_fired += 1

		if elapsed > vortex_duration * 0.5 and not burst_ready:
			orbit_speed = vortex_orbit_speed_burst
			vortex_rate = vortex_fire_rate_burst
			burst_ready = true
			_fx_shockwave(Color(1.0, 0.0, 0.0), 350.0)

		if rings_fired % vortex_lightning_every_n_rings == 0:
			_fx_lightning_burst(3, Color(1.0, 0.6, 0.0))

	if player:
		await _crimson_cage_attack()

	vortexfx.play("vortex_end")
	await vortexfx.animation_finished
	attacking = false

func _crimson_cage_attack() -> void:
	sprite.rotation = 0
	if not player:
		return
	attacking = true

	var center = player.global_position
	var bullets: Array[Node] = []
	var open_angle = rng.randi_range(0, 360)
	var open_width: int
	var bullet_count: int
	match Global.dificulty:
		"easy": open_width = cage_open_width_easy;   bullet_count = cage_bullets_easy
		"hard": open_width = cage_open_width_hard;   bullet_count = cage_bullets_hard
		_:      open_width = cage_open_width_medium; bullet_count = cage_bullets_medium

	for i in range(bullet_count):
		var angle = (360.0 / bullet_count) * i
		if angle > open_angle and angle < open_angle + open_width:
			continue
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)
		var dir = Vector2.RIGHT.rotated(deg_to_rad(angle))
		b.global_position = center + dir * cage_radius
		_bullet_setup(b, -dir, 0.0)
		bullets.append(b)

	if GlobalTweens:
		GlobalTweens.glitch_flash(self, 12, 0.15)
	_fx_shockwave(Color(0.8, 0.0, 0.0), 320.0)

	var escape_time: float
	match Global.dificulty:
		"easy": escape_time = cage_escape_time_easy
		"hard": escape_time = cage_escape_time_hard
		_:      escape_time = cage_escape_time_medium
	await get_tree().create_timer(escape_time).timeout

	for b in bullets:
		if is_instance_valid(b):
			var to_center = center - b.global_position
			var dist = to_center.length()
			if dist > 0.01:
				var impl_dir = to_center.normalized()
				var impl_speed = dist / cage_implosion_duration
				_bullet_setup(b, impl_dir, impl_speed)

	await get_tree().create_timer(cage_implosion_duration + 0.05).timeout

	var e = explosion_scene.instantiate()
	get_parent().add_child(e)
	e.global_position = center
	e.scale = Vector2.ONE * 2.5
	e.modulate = Color(1.0, 0.1, 0.0)
	_fx_shockwave(Color(1.0, 0.0, 0.0), 500.0)
	_fx_lightning_burst(6, Color(1.0, 0.3, 0.0))

	for b in bullets:
		if is_instance_valid(b):
			b.queue_free()

	attacking = false

func _teleport_random() -> void:
	if not can_teleport:
		return
	var radius = randf_range(teleport_radius_min, teleport_radius_max)
	var angle = randf_range(0, TAU)
	var offset = Vector2(cos(angle), sin(angle)) * radius
	var target_pos = (player.global_position if player else global_position) + offset

	_fx_summon_ring_burst(Color(0.5, 0.0, 1.0))
	if GlobalTweens:
		GlobalTweens.quantum_jump(self, Vector2(randi_range(2, 4), randi_range(2, 4)), 0.4)
	await get_tree().create_timer(teleport_windup).timeout
	global_position = target_pos
	_fx_shockwave(Color(0.5, 0.0, 1.0), 200.0)

	teleport_timer.start()

func _spawn_lasers() -> void:
	var count: int
	match Global.dificulty:
		"easy": count = laser_count_easy
		"hard": count = laser_count_hard
		_:      count = laser_count_medium
	for i in range(count):
		var l = laser_scene.instantiate()
		get_parent().add_child(l)
		l.global_position = global_position + Vector2(rng.randi_range(-laser_spawn_radius, laser_spawn_radius), rng.randi_range(-laser_spawn_radius, laser_spawn_radius))
		var base_spd = rng.randf_range(-laser_rotation_speed_max, laser_rotation_speed_max)
		l.rotation_speed = base_spd * (1.0 + (laser_hard_speed_bonus if Global.dificulty == "hard" else 0.0))

func _spawn_explosions() -> void:
	var count: int
	match Global.dificulty:
		"easy": count = explosion_count_easy
		"hard": count = explosion_count_hard
		_:      count = explosion_count_medium
	for i in range(count):
		var e = explosion_scene.instantiate()
		get_parent().add_child(e)
		e.global_position = global_position + Vector2(rng.randi_range(-explosion_scatter_radius, explosion_scatter_radius), rng.randi_range(-explosion_scatter_radius, explosion_scatter_radius))
		e.scale = Vector2.ONE * rng.randf_range(explosion_scale_min, explosion_scale_max)

func _gravity_pull() -> void:
	if not player or attacking:
		return
	attacking = true

	_fx_gravity_rings()
	await get_tree().create_timer(gravity_pull_windup).timeout

	var pull_duration: float = gravity_pull_duration_hard if Global.dificulty == "hard" else gravity_pull_duration_normal
	var pull_force: float
	match Global.dificulty:
		"easy": pull_force = gravity_pull_force_easy
		"hard": pull_force = gravity_pull_force_hard
		_:      pull_force = gravity_pull_force_medium
	var elapsed = 0.0

	while elapsed < pull_duration:
		if is_instance_valid(player):
			var dir = (global_position - player.global_position).normalized()
			if player.has_method("apply_external_force"):
				player.apply_external_force(dir * pull_force)
			else:
				player.global_position += dir * pull_force * get_process_delta_time()
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	_fx_shockwave(Color(0.5, 0.0, 1.0), 300.0)
	_fx_lightning_burst(5, Color(0.8, 0.0, 1.0))
	var e = explosion_scene.instantiate()
	get_parent().add_child(e)
	e.global_position = global_position
	e.scale = Vector2.ONE * 1.8
	e.modulate = Color(0.6, 0.0, 1.0)

	await get_tree().create_timer(gravity_pull_post_delay).timeout
	attacking = false

func _death_blossom() -> void:
	if attacking:
		return
	attacking = true

	_fx_shockwave(Color(1.0, 0.0, 0.2), 280.0)
	_fx_open_eye(0.2)

	var rings: int
	var base_step: int
	match Global.dificulty:
		"easy": rings = blossom_rings_easy; base_step = blossom_step_normal
		"hard": rings = blossom_rings_hard; base_step = blossom_step_hard
		_:      rings = blossom_rings_medium; base_step = blossom_step_normal

	for ring_i in range(rings):
		var rotation_offset = (360.0 / rings) * ring_i * 0.5
		for angle in range(0, 360, base_step):
			var b = bullet_scene.instantiate()
			get_parent().add_child(b)
			b.global_position = global_position
			var dir = Vector2.RIGHT.rotated(deg_to_rad(angle + rotation_offset))
			var spd = blossom_bullet_speed_base + ring_i * blossom_bullet_speed_per_ring
			_bullet_setup(b, dir, spd)
		await get_tree().create_timer(blossom_ring_delay).timeout

	await get_tree().create_timer(blossom_post_delay).timeout
	attacking = false

func _summon_lightning_storm() -> void:
	if attacking:
		return
	attacking = true

	var strike_count: int
	match Global.dificulty:
		"easy": strike_count = storm_strikes_easy
		"hard": strike_count = storm_strikes_hard
		_:      strike_count = storm_strikes_medium

	_fx_lightning_burst(strike_count, Color(1.0, 1.0, 0.3))
	await get_tree().create_timer(_scale(0.8)).timeout

	for i in range(strike_count):
		var target: Vector2
		if player and rng.randf() < storm_player_aim_chance:
			target = player.global_position + Vector2(
				rng.randf_range(-storm_player_jitter, storm_player_jitter),
				rng.randf_range(-storm_player_jitter, storm_player_jitter)
			)
		else:
			target = global_position + Vector2(
				rng.randf_range(-storm_radius, storm_radius),
				rng.randf_range(-storm_radius, storm_radius)
			)

		_fx_draw_lightning_to(target, Color(1.0, 0.9, 0.2))

		var e = explosion_scene.instantiate()
		get_parent().add_child(e)
		e.global_position = target
		e.scale = Vector2.ONE * rng.randf_range(0.7, 1.3)
		e.modulate = Color(1.0, 0.9, 0.1)

		await get_tree().create_timer(storm_strike_interval).timeout

	await get_tree().create_timer(storm_post_delay).timeout
	attacking = false

# ============================================================
# === FX HELPERS ==============================================
# ============================================================
func _fx_start_passive_aura() -> void:
	var fade_duration := 1.5
	var elapsed := 0.0
	while elapsed < fade_duration:
		_draw_aura_color.a = lerp(0.0, 0.45, elapsed / fade_duration)
		_draw_aura_radius = lerp(0.0, 95.0, elapsed / fade_duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_draw_aura_color.a = 0.45
	_draw_aura_radius = 95.0

	while true:
		elapsed = 0.0
		while elapsed < 1.0:
			_draw_aura_radius = lerp(95.0, 110.0, elapsed / 1.0)
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		_draw_aura_radius = 110.0

		elapsed = 0.0
		while elapsed < 1.0:
			_draw_aura_radius = lerp(110.0, 90.0, elapsed / 1.0)
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		_draw_aura_radius = 90.0

func _fx_shockwave(color: Color, max_radius: float) -> void:
	_draw_shockwave_radius = 10.0
	_draw_shockwave_alpha = 0.9
	var duration := 0.5
	var elapsed := 0.0
	while elapsed < duration:
		_draw_shockwave_radius = lerp(10.0, max_radius, elapsed / duration)
		_draw_shockwave_alpha = lerp(0.9, 0.0, elapsed / duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_draw_shockwave_alpha = 0.0

func _fx_shockwave_multi(color: Color, max_radius: float, duration: float) -> void:
	var sw = {"radius": 10.0, "alpha": 1.0, "color": color}
	_draw_shockwaves.append(sw)
	var elapsed := 0.0
	while elapsed < duration:
		sw["radius"] = lerp(10.0, max_radius, elapsed / duration)
		sw["alpha"] = lerp(1.0, 0.0, elapsed / duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if sw in _draw_shockwaves:
		_draw_shockwaves.erase(sw)

func _fx_spawn_cracks(count: int, color: Color) -> void:
	for i in range(count):
		var angle = rng.randf() * TAU
		var length = rng.randf_range(40.0, 100.0)
		var from_pt = Vector2(cos(angle), sin(angle)) * 40.0
		var to_pt = from_pt + Vector2(cos(angle + rng.randf_range(-0.5, 0.5)), sin(angle + rng.randf_range(-0.5, 0.5))) * length
		var crack = {"from": from_pt, "to": to_pt, "alpha": 1.0, "color": color}
		_draw_cracks.append(crack)
		_fade_crack(crack, 4.0)

func _fade_crack(crack: Dictionary, duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and crack in _draw_cracks:
		crack["alpha"] = lerp(1.0, 0.0, elapsed / duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if crack in _draw_cracks:
		_draw_cracks.erase(crack)

func _fx_open_eye(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		_draw_eye_open = lerp(0.0, 1.0, elapsed / duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_draw_eye_open = 1.0
	await get_tree().create_timer(2.0).timeout
	var close_duration := duration * 0.5
	elapsed = 0.0
	while elapsed < close_duration:
		_draw_eye_open = lerp(1.0, 0.0, elapsed / close_duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_draw_eye_open = 0.0

func _fx_summon_ring_burst(color: Color) -> void:
	for i in range(3):
		var ring = {"radius": 30.0 + i * 20, "alpha": 0.9, "color": color}
		_draw_rings.append(ring)
		_animate_ring_out(ring, 200.0 + i * 50, 0.6)

func _animate_ring_out(ring: Dictionary, target_radius: float, duration: float) -> void:
	var elapsed := 0.0
	var start_radius = ring["radius"]
	var start_alpha = ring["alpha"]
	while elapsed < duration and ring in _draw_rings:
		ring["radius"] = lerp(start_radius, target_radius, elapsed / duration)
		ring["alpha"] = lerp(start_alpha, 0.0, elapsed / duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if ring in _draw_rings:
		_draw_rings.erase(ring)

func _animate_ring_gravity(ring: Dictionary, duration: float, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if ring not in _draw_rings:
		return
	var elapsed := 0.0
	var start_radius = ring["radius"]
	while elapsed < duration and ring in _draw_rings:
		ring["radius"] = lerp(start_radius, 30.0, elapsed / duration)
		ring["alpha"] = lerp(0.7, 0.0, elapsed / duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if ring in _draw_rings:
		_draw_rings.erase(ring)

func _fx_gravity_rings() -> void:
	for i in range(5):
		var ring = {"radius": 400.0 - i * 50, "alpha": 0.7, "color": Color(0.5, 0.0, 1.0, 0.7)}
		_draw_rings.append(ring)
		_animate_ring_gravity(ring, 1.8, i * 0.15)

func _fx_lightning_burst(count: int, color: Color) -> void:
	for i in range(count):
		var angle = rng.randf() * TAU
		var points: Array[Vector2] = []
		var cursor = Vector2.ZERO
		var length = rng.randf_range(60.0, 160.0)
		var segments = rng.randi_range(4, 8)
		for s in range(segments):
			cursor += Vector2(cos(angle + rng.randf_range(-0.6, 0.6)), sin(angle + rng.randf_range(-0.6, 0.6))) * (length / segments)
			points.append(cursor)
		var bolt = {"points": points, "alpha": 1.0, "color": color}
		_draw_lightning_bolts.append(bolt)
		_fade_bolt(bolt, 0.3)

func _fade_bolt(bolt: Dictionary, duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and bolt in _draw_lightning_bolts:
		bolt["alpha"] = lerp(1.0, 0.0, elapsed / duration)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if bolt in _draw_lightning_bolts:
		_draw_lightning_bolts.erase(bolt)

func _fx_draw_lightning_to(world_target: Vector2, color: Color) -> void:
	var local_target = to_local(world_target)
	var points: Array[Vector2] = []
	var segments = rng.randi_range(5, 10)
	for s in range(segments + 1):
		var t = float(s) / float(segments)
		var base_pt = local_target * t
		var jitter = Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30)) * (1.0 - t)
		points.append(base_pt + jitter)
	var bolt = {"points": points, "alpha": 1.0, "color": color}
	_draw_lightning_bolts.append(bolt)
	_fade_bolt(bolt, 0.4)

func _fx_charge_up(color: Color, duration: float) -> void:
	for i in range(4):
		var ring = {"radius": 200.0 - i * 30, "alpha": 0.0, "color": color}
		_draw_rings.append(ring)
		await get_tree().create_timer(i * 0.1).timeout
		_animate_ring_in(ring, duration * 0.8)

func _animate_ring_in(ring: Dictionary, duration: float) -> void:
	var appear_time := 0.1
	var elapsed := 0.0
	while elapsed < appear_time and ring in _draw_rings:
		ring["alpha"] = lerp(0.0, 0.8, elapsed / appear_time)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if ring not in _draw_rings:
		return

	var shrink_time := duration
	elapsed = 0.0
	var start_radius = ring["radius"]
	while elapsed < shrink_time and ring in _draw_rings:
		ring["radius"] = lerp(start_radius, 20.0, elapsed / shrink_time)
		ring["alpha"] = lerp(0.8, 0.0, elapsed / shrink_time)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if ring in _draw_rings:
		_draw_rings.erase(ring)

# ============================================================
# === DEATH ===================================================
# ============================================================
func _die() -> void:
	if _is_dying:
		return
	_is_dying = true
	$death.play("death")
	_perform_death_rewards()
	_perform_death_animation()

func _perform_death_rewards() -> void:
	GlobalStats.kill_boss_total += 1
	Global.boss_killed = true
	var reward = randi_range(200, 800)
	GlobalStats.gold += reward
	Global.update_mission_progress("rich_game_1", reward)
	Global.update_mission_progress("rich_game_2", reward)
	Global.update_mission_progress("rich_game_3", reward)

	if Global.dificulty == "easy":
		Global.update_mission_progress("boss_killer_1", 1)
		if randi() % 100 < 10:
			_drop_random_shard()
		if randi() % 100 < 50:
			GlobalStats.tablet += 1
		if randi() % 100 < 2:
			Global.wrath_icons['easy'] = true

	elif Global.dificulty == "normal":
		Global.update_mission_progress("boss_killer_2", 1)
		if randi() % 100 < 15:
			_drop_random_shard()
		if randi() % 100 < 70:
			GlobalStats.tablet += 1
		if randi() % 100 < 2:
			Global.wrath_icons['easy'] = true
		if randi() % 100 < 5:
			Global.wrath_icons['normal'] = true
		if randi() % 1000 < 1:
			Global.spin_gem += 1

	elif Global.dificulty == "hard":
		Global.update_mission_progress("boss_killer_3", 1)
		if randi() % 100 < 20:
			_drop_random_shard()
		if randi() % 100 < 90:
			GlobalStats.tablet += 1
		if randi() % 100 < 2:
			Global.wrath_icons['easy'] = true
		if randi() % 100 < 5:
			Global.wrath_icons['normal'] = true
		if randi() % 100 < 10:
			Global.wrath_icons['hard'] = true
		if randi() % 1000 < 1:
			Global.spin_gem += 1

	Global.register_found_weapon("GAEA CORE", "legendary")

func _perform_death_animation() -> void:
	# --- FASE 1: APERTURA OCCHIO DRAMMATICA ---
	_draw_phase = 3
	_fx_open_eye(0.4)
	_fx_spawn_cracks(death_crack_count, Color(1.0, 0.0, 0.0, 1.0))
	_fx_lightning_burst(death_lightning_bursts, Color(1.0, 0.9, 0.1))

	# Aura diventa rossa intensa
	var aura_elapsed := 0.0
	while aura_elapsed < 0.5:
		_draw_aura_color = Color(
			lerp(_draw_aura_color.r, 1.0, aura_elapsed / 0.5),
			0.0,
			0.0,
			lerp(_draw_aura_color.a, 0.9, aura_elapsed / 0.5)
		)
		_draw_aura_radius = lerp(_draw_aura_radius, 140.0, aura_elapsed / 0.5)
		queue_redraw()
		await get_tree().process_frame
		aura_elapsed += get_process_delta_time()

	# --- FASE 2: ESPLOSIONI CASUALI PROGRESSIVE ---
	for i in range(death_explosion_count):
		var e = explosion_scene.instantiate()
		get_parent().add_child(e)
		var dir = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		e.global_position = global_position + dir * rng.randf_range(20.0, 80.0)
		e.scale = Vector2.ONE * rng.randf_range(0.8, 2.0)
		e.modulate = Color(1.0, rng.randf_range(0.0, 0.4), 0.0)
		await get_tree().create_timer(death_total_duration / death_explosion_count).timeout

	# --- FASE 3: SHOCKWAVE MULTIPLI CONCENTRICI ---
	var shockwave_colors := [
		Color(1.0, 0.0, 0.0),
		Color(1.0, 0.4, 0.0),
		Color(1.0, 1.0, 0.2),
		Color(0.5, 0.0, 1.0),
		Color(1.0, 1.0, 1.0),
	]
	for i in range(death_shockwave_count):
		var col = shockwave_colors[i % shockwave_colors.size()]
		var max_r = death_shockwave_max_radius * (0.4 + i * 0.15)
		_fx_shockwave_multi(col, max_r, 0.7)
		_fx_lightning_burst(3, col)
		if i == death_shockwave_count - 1:
			# Ultimo shockwave: enorme flash bianco
			_fx_shockwave_multi(Color(1.0, 1.0, 1.0, 1.0), death_shockwave_max_radius, 0.9)
			_fx_lightning_burst(8, Color(1.0, 1.0, 1.0))
		await get_tree().create_timer(death_shockwave_interval).timeout

	# --- FASE 4: FLASH BIANCO + ROTAZIONE MORENTE ---
	if GlobalTweens:
		GlobalTweens.glitch_flash(self, death_flash_count, 0.08)

	var spin_elapsed := 0.0
	var spin_duration := 1.2
	while spin_elapsed < spin_duration:
		sprite.rotation += deg_to_rad(lerp(20.0, 720.0, spin_elapsed / spin_duration) * get_process_delta_time() * 60.0)
		queue_redraw()
		await get_tree().process_frame
		spin_elapsed += get_process_delta_time()

	# --- FASE 5: ESPLOSIONE FINALE DEVASTANTE ---
	_fx_spawn_cracks(death_crack_count * 2, Color(1.0, 0.0, 0.0, 1.0))
	_fx_summon_ring_burst(Color(1.0, 0.0, 0.0))
	_fx_summon_ring_burst(Color(1.0, 1.0, 1.0))

	var final_e = explosion_scene.instantiate()
	get_parent().add_child(final_e)
	final_e.global_position = global_position
	final_e.scale = Vector2.ONE * 4.0
	final_e.modulate = Color(1.0, 0.3, 0.0)

	_fx_shockwave_multi(Color(1.0, 1.0, 1.0), death_shockwave_max_radius * 1.5, 1.0)
	_fx_lightning_burst(12, Color(1.0, 0.8, 0.0))

	# --- FASE 6: DISSOLVENZA ---
	var fade_elapsed := 0.0
	var start_mod = sprite.modulate
	while fade_elapsed < death_fade_duration:
		var t = fade_elapsed / death_fade_duration
		sprite.modulate.a = lerp(start_mod.a, 0.0, t)
		_draw_aura_color.a = lerp(0.9, 0.0, t)
		queue_redraw()
		await get_tree().process_frame
		fade_elapsed += get_process_delta_time()

	queue_free()

func _drop_random_shard() -> void:
	var shards = ["ice", "magma", "light", "void"]
	match shards.pick_random():
		"ice":   GlobalStats.ice_shard += 1
		"magma": GlobalStats.magma_shard += 1
		"light": GlobalStats.light_shard += 1
		"void":  GlobalStats.void_shard += 1

# ============================================================
# === SHIELD / HIT ============================================
# ============================================================
func _on_shield_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Global.hurt = true
		Global.player_hp -= 20 * _damage_multiplier()

func spawn_damage_popup(amount: int) -> void:
	if not is_inside_tree():
		return
	var dmg_label_scene = preload("res://Gres/Scenes/UI/damage_label.tscn")
	var dmg_label = dmg_label_scene.instantiate()
	var root = get_tree().get_root()
	if root == null:
		return
	root.add_child(dmg_label)
	dmg_label.show_damage(amount, global_position)

func _on_shield_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		var dmg := _get_bullet_damage(area)
		area.queue_free()
		if shield_hp > 0:
			shield_hp -= dmg
		else:
			_spawn_damage_effects(dmg)
			_on_damage(dmg)
			if can_regen:
				can_regen = false
				$ShieldRegenTimer.start()
		spawn_damage_popup(dmg)
		$Sprite2D/ShieldHPL1.text = str(shield_hp)
		$Sprite2D/ShieldHPL2.text = str(shield_hp)
		if shield_hp <= 0 and can_regen:
			shield_hp = 0
			can_regen = false
			$ShieldRegenTimer.start()

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		var dmg := _get_bullet_damage(area)
		_spawn_damage_effects(dmg)
		_on_damage(dmg)
		area.queue_free()
		spawn_damage_popup(dmg)

func _get_bullet_damage(area: Area2D) -> float:
	if area.has_meta("damage"):
		return area.get_meta("damage")
	elif GlobalWeapons.current_weapon.has("damage"):
		return GlobalWeapons.current_weapon["damage"]
	return 10.0 * Global.player_damage

func _spawn_damage_effects(amount: float) -> void:
	var effect_scene = load("res://Gres/Scenes/Effects/expl_boss.tscn")
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)
	var dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	effect.global_position = global_position + dir * randf_range(20.0, 55.0)
	effect.scale = Vector2.ONE * clamp(amount / 100.0, 0.3, 1.2)
	_fx_lightning_burst(2, Color(1.0, 0.2, 0.0))

func _on_shield_regen_timer_timeout() -> void:
	can_regen = true
	match Global.dificulty:
		'easy':   shield_hp = 100
		'medium': shield_hp = 500
		'hard':   shield_hp = 1500
	$Sprite2D/ShieldHPL1.text = str(shield_hp)
	$Sprite2D/ShieldHPL2.text = str(shield_hp)

func _on_rotate_timer_timeout() -> void:
	can_teleport = false
	GlobalTweens.rotate(self, 360 * 4 if randi() % 100 < 50 else -360 * 4, 6.0)
	$axes.play("loop")
	can_move = true
	if phase == 1:
		$RotateTimer.start()
