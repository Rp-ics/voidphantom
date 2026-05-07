extends CharacterBody2D
class_name BloodMother

# ================================================================
# == BLOOD MOTHER — Boss biologico
# ================================================================

# ----------------------------------------------------------------
# CONFIG BASE
# ----------------------------------------------------------------
@export var max_hp:             int   = 14000
@export var move_speed:         float = 300.0
@export var phase2_threshold:   float = 0.6
@export var phase3_threshold:   float = 0.2
@export var drone_scene:        PackedScene
@export var cannon_scene:       PackedScene
@export var cannon_left_node:   NodePath
@export var cannon_right_node:  NodePath
@export var bullet_path:        String = "res://Gres/Scenes/enemies/bullets/mother_bullet.tscn"

# ----------------------------------------------------------------
# WAVE DIFFICULTY SCALING
# ----------------------------------------------------------------
@export_group("Wave Difficulty")
## easy: wave 5-10  |  medium: wave 15-25  |  hard: wave 30+
@export var wave_easy_min:   int = 5
@export var wave_easy_max:   int = 10
@export var wave_medium_min: int = 15
@export var wave_medium_max: int = 25
@export var wave_hard_min:   int = 30

## Moltiplicatori HP per wave dentro ogni fascia (lerp tra min e max)
@export var hp_easy_base:    int   = 5600
@export var hp_easy_peak:    int   = 7000
@export var hp_medium_base:  int   = 8500
@export var hp_medium_peak:  int   = 11000
@export var hp_hard_base:    int   = 14000
@export var hp_hard_peak:    int   = 20000

@export var speed_easy_base:   float = 300.0
@export var speed_easy_peak:   float = 340.0
@export var speed_medium_base: float = 360.0
@export var speed_medium_peak: float = 420.0
@export var speed_hard_base:   float = 400.0
@export var speed_hard_peak:   float = 520.0

# ----------------------------------------------------------------
# SKILL: SHOOT
# ----------------------------------------------------------------
@export_group("Skill: Shoot")
@export var shoot_base_interval:      float = 1.2
@export var shoot_phase2_interval:    float = 0.8
@export var shoot_phase3_interval:    float = 0.5
@export var shoot_spread_deg:         float = 25.0
@export var shoot_muzzle_nodes:       Array[String] = ["Muzzle2", "Muzzle3", "Muzzle4"]

# ----------------------------------------------------------------
# SKILL: SPIRAL BURST
# ----------------------------------------------------------------
@export_group("Skill: Spiral Burst")
@export var spiral_arms:              int   = 4
@export var spiral_steps:             int   = 8
@export var spiral_step_delay:        float = 0.06
@export var spiral_trigger_chance:    int   = 25   # % in phase3

# ----------------------------------------------------------------
# SKILL: DRONE SPAWN
# ----------------------------------------------------------------
@export_group("Skill: Drone Spawn")
@export var drone_spawn_interval_phase1: float = 6.0
@export var drone_spawn_interval_phase3: float = 2.0
@export var drone_spawn_offset_min:      float = 100.0
@export var drone_spawn_offset_max:      float = 200.0
@export var drone_wave_count_easy:       int   = 1
@export var drone_wave_count_medium:     int   = 2
@export var drone_wave_count_hard:       int   = 3

# ----------------------------------------------------------------
# SKILL: TELEPORT
# ----------------------------------------------------------------
@export_group("Skill: Teleport")
@export var teleport_radius_min:  float = 300.0
@export var teleport_radius_max:  float = 500.0
@export var teleport_windup:      float = 0.2

# ----------------------------------------------------------------
# SKILL: DASH (slide)
# ----------------------------------------------------------------
@export_group("Skill: Dash")
@export var dash_interval_min:    int   = 10
@export var dash_interval_max:    int   = 15
@export var dash_distance:        float = 600.0
@export var dash_speed:           float = 200.0
@export var dash_duration:        float = 5.0

# ----------------------------------------------------------------
# SKILL: CANNON
# ----------------------------------------------------------------
@export_group("Skill: Cannon")
@export var cannon_rapid_fire_count:     int   = 6
@export var cannon_rapid_fire_count_hard:int   = 10
@export var cannon_phase2_pattern:       String = "beam"   # "beam" | "missile"
@export var cannon_phase1_alt_chance:    int   = 50        # % chance cannone sinistro vs destro

# ----------------------------------------------------------------
# SKILL: OVERHEAT (phase3 self-damage)
# ----------------------------------------------------------------
@export_group("Skill: Overheat")
@export var overheat_interval:     float = 1.0
@export var overheat_hp_fraction:  float = 0.002   # % max_hp per tick

# ----------------------------------------------------------------
# SKILL: SHIELD
# ----------------------------------------------------------------
@export_group("Skill: Shield")
@export var shield_cooldown:       float = 10.0
@export var shield_duration:       float = 6.0
@export var shield_phase2_cd:      float = 10.0
@export var shield_phase3_cd:      float = 6.0
@export var shield_phase3_dur:     float = 12.0

# ----------------------------------------------------------------
# PHASE TRANSITION SPEEDS
# ----------------------------------------------------------------
@export_group("Phase Transitions")
@export var phase2_speed_mult:     float = 1.5
@export var phase3_speed_mult:     float = 1.85
@export var phase2_pattern_interval: float = 0.9
@export var phase3_pattern_interval: float = 0.6

# ----------------------------------------------------------------
# DEATH FX CONFIG
# ----------------------------------------------------------------
@export_group("Death FX")
@export var death_wave_count:          int   = 5
@export var death_wave_interval:       float = 0.28
@export var death_explosion_count:     int   = 14
@export var death_explosion_duration:  float = 2.0
@export var death_ray_count:           int   = 24
@export var death_pulse_count:         int   = 6
@export var death_final_radius:        float = 350.0
@export var death_fade_duration:       float = 1.0
@export var death_spin_speed_start:    float = 15.0
@export var death_spin_speed_end:      float = 800.0
@export var death_spin_duration:       float = 1.5

# ================================================================
# == RUNTIME
# ================================================================
var invulnerable:      bool  = true
var enraged:           bool  = false
var can_rotate:        bool  = true
var can_phase_2:       bool  = true
var can_phase_3:       bool  = true
var can_shoot:         bool  = true
var can_teleport:      bool  = true
var is_dying:          bool  = false

var player:            Node  = null
var cannons:           Array = []
var bullet_scene:      PackedScene

var move_origin_speed: float = 300.0
var shoot_time:        float = 1.2
var shield_time:       float = 10.0
var shield_dur_time:   float = 6.0

var _draw_time:        float = 0.0
var _phase_color:      Color = Color(0.8, 0.0, 0.1, 1.0)
var _aura_node:        Node2D = null

# ================================================================
# == NODES
# ================================================================
@onready var t_phase_check = $Timers/Timer_phase_check
@onready var t_drone_spawn = $Timers/Timer_drone_spawn
@onready var t_pattern     = $Timers/Timer_pattern
@onready var t_shoot       = $Timers/Timer_shoot
@onready var core          = $Core
@onready var audio         = $boss_sounds
@onready var shield_timer      = $Timers/Timer_shield
@onready var shield_dur_timer  = $Timers/Timer_shield_dur

var supernova_scene = preload("res://Gres/Scenes/Effects/supernova.tscn")

# ================================================================
# == _READY
# ================================================================
func _ready() -> void:
	_apply_wave_difficulty()

	Global.blood_mother_hp = max_hp
	bullet_scene = load(bullet_path)

	player = get_tree().get_first_node_in_group("player")
	_init_cannons()

	t_shoot.wait_time = shoot_time;          t_shoot.start()
	t_phase_check.wait_time = 0.2;           t_phase_check.start()
	t_drone_spawn.wait_time = drone_spawn_interval_phase1; t_drone_spawn.start()
	t_pattern.wait_time     = 1.2;           t_pattern.start()

	$Timers/Timer_teleport.start()
	$Timers/Timer_dash.wait_time = randi_range(dash_interval_min, dash_interval_max)
	$Timers/Timer_dash.start()
	$Timers/Timer_supernova.start()

	invulnerable = true
	_on_timer_shield_timeout()
	_set_glow_intensity(0.1)

	set_process(true)
	_spawn_aura()


# ----------------------------------------------------------------
# Scala HP e velocità in base a Global.wave + Global.dificulty
# ----------------------------------------------------------------
func _apply_wave_difficulty() -> void:
	var wave: int = Global.wave if "wave" in Global else 1
	var diff: String = Global.dificulty

	match diff:
		"easy":
			var t = clamp(float(wave - wave_easy_min) / float(max(wave_easy_max - wave_easy_min, 1)), 0.0, 1.0)
			max_hp     = int(lerp(float(hp_easy_base),   float(hp_easy_peak),   t))
			move_speed = lerp(speed_easy_base, speed_easy_peak, t)
		"normal", "medium":
			var t = clamp(float(wave - wave_medium_min) / float(max(wave_medium_max - wave_medium_min, 1)), 0.0, 1.0)
			max_hp     = int(lerp(float(hp_medium_base), float(hp_medium_peak), t))
			move_speed = lerp(speed_medium_base, speed_medium_peak, t)
		"hard":
			# Sopra wave_hard_min scala indefinitamente (cap a 2x dopo +30 wave)
			var t = clamp(float(wave - wave_hard_min) / 30.0, 0.0, 1.0)
			max_hp     = int(lerp(float(hp_hard_base),  float(hp_hard_peak),   t))
			move_speed = lerp(speed_hard_base, speed_hard_peak, t)
		_:
			max_hp     = hp_easy_base
			move_speed = speed_easy_base

	move_origin_speed = move_speed
	shoot_time        = shoot_base_interval
	shield_time       = shield_cooldown
	shield_dur_time   = shield_duration


# ================================================================
# == PROCESS
# ================================================================
func _process(delta: float) -> void:
	_draw_time += delta
	queue_redraw()
	_update_visuals_draw(delta)


func _physics_process(_delta: float) -> void:
	if is_dying or not is_instance_valid(player): return
	if can_rotate:
		var dir = (player.global_position - global_position).normalized()
		rotation = lerp_angle(rotation, dir.angle(), 0.02)
	var move_dir = (player.global_position - global_position).normalized()
	velocity = move_dir * move_speed * 0.25
	move_and_slide()


# ================================================================
# == VISUALS DRAW
# ================================================================
func _update_visuals_draw(_delta: float) -> void:
	pass


func _draw() -> void:
	var t := _draw_time
	var p := sin(t * (3.5 + float(Global.state == "PHASE3") * 6.0)) * 0.5 + 0.5
	var col := _phase_color
	var r   := 36.0 + p * (8.0 if not enraged else 18.0)

	draw_circle(Vector2.ZERO, r, Color(col.r, col.g, col.b, 0.06 + p * 0.05))
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(col.r, col.g, col.b, 0.25 + p * 0.18), 2.5, true)

	var vein_count := 4 if Global.state != "PHASE3" else 8
	for vi in range(vein_count):
		var va := (TAU / vein_count) * vi + t * (0.8 if not enraged else 2.5)
		var vr := r * 0.55
		var vp := Vector2(cos(va), sin(va)) * vr
		draw_line(Vector2.ZERO, vp, Color(col.r + 0.2, col.g, col.b, 0.3 + p * 0.2), 1.8, true)
		draw_circle(vp, 3.5 + p * 2.0, Color(col.r, col.g, col.b, 0.65 + p * 0.2))

	if enraged:
		var fl = abs(sin(t * 20.0))
		draw_circle(Vector2.ZERO, 12.0 + fl * 8.0, Color(1.0, 0.0, 0.3, fl * 0.5))
		for ci in range(6):
			var ca := (TAU / 6.0) * ci + t * 8.0
			draw_circle(Vector2(cos(ca), sin(ca)) * (14.0 + fl * 4.0),
						3.0 * fl, Color(1.0, 0.4, 0.4, fl * 0.9))


# ================================================================
# == PHASE CHECK
# ================================================================
func _on_Timer_phase_check_timeout() -> void:
	if is_dying: return
	var ratio := float(Global.blood_mother_hp) / float(max_hp)

	if Global.mother_right_canon_damaged and Global.mother_left_canon_damaged:
		invulnerable = false
		if has_node("Shield"): $Shield.hide()
	else:
		invulnerable = true
		if has_node("Shield"): $Shield.show()

	if Global.state == "PHASE1" and ratio <= phase2_threshold and can_phase_2:
		can_phase_2 = false
		move_speed = move_origin_speed * phase2_speed_mult
		shield_dur_time = shield_phase2_cd; shield_time = shield_phase2_cd
		shoot_time = shoot_phase2_interval
		if has_node("phaser"): $phaser.play("phase_2")
		if has_node("StopArea/coll"): GlobalTweens.deactivate($StopArea/coll)
		if has_node("Timers/TimerActivateStop"): $Timers/TimerActivateStop.start()
		_enter_phase2()

	elif Global.state == "PHASE2" and ratio <= phase3_threshold and can_phase_3:
		can_phase_3 = false
		move_speed = move_origin_speed * phase3_speed_mult
		shield_dur_time = shield_phase3_dur; shield_time = shield_phase3_cd
		shoot_time = shoot_phase3_interval
		if has_node("phaser"): $phaser.play("phase_3")
		_enter_phase3()

	t_phase_check.start()


# ================================================================
# == TRANSIZIONI
# ================================================================
func _enter_phase2() -> void:
	Global.state = "PHASE2"
	invulnerable = true
	_phase_color = Color(0.6, 0.0, 0.0, 1.0)
	_spawn_aura()

	var pfx := _PhaseTransFX.new(); pfx.fx_col = _phase_color; add_child(pfx)

	if core and core.has_method("open_core"): core.call_deferred("open_core")
	for c in cannons:
		if c.has_method("set_shielded"): c.set_shielded(false)

	t_pattern.wait_time = phase2_pattern_interval; t_pattern.start()
	_set_glow_intensity(0.5)
	if audio: audio.play()

	await get_tree().create_timer(1.2).timeout
	invulnerable = false


func _enter_phase3() -> void:
	Global.state = "PHASE3"
	enraged      = true
	_phase_color = Color(1.0, 0.0, 0.4, 1.0)
	_spawn_aura()

	var pfx := _PhaseTransFX.new(); pfx.fx_col = _phase_color; add_child(pfx)

	_set_glow_intensity(1.0)
	t_pattern.wait_time = phase3_pattern_interval; t_pattern.start()
	t_drone_spawn.wait_time = drone_spawn_interval_phase3; t_drone_spawn.start()
	_start_self_overheat()


func _start_self_overheat() -> void:
	var ot := Timer.new()
	ot.one_shot = false; ot.wait_time = overheat_interval
	add_child(ot); ot.start()
	ot.connect("timeout", Callable(self, "_on_overheat_tick"))


func _on_overheat_tick() -> void:
	if Global.state != "PHASE3": return
	_apply_damage(int(max_hp * overheat_hp_fraction))


# ================================================================
# == DAMAGE
# ================================================================
func take_damage(amount: int, _source: Node = null) -> void:
	if invulnerable or is_dying: return
	_apply_damage(amount)


func _apply_damage(amount: int) -> void:
	Global.blood_mother_hp -= amount
	_spawn_damage_effects(amount)
	spawn_damage_popup(amount)

	var hfx := _HitFX.new(); hfx.hit_col = _phase_color; add_child(hfx)

	if Global.blood_mother_hp <= 0:
		Global.blood_mother_hp = 0
		_die()
	else:
		var ratio := float(Global.blood_mother_hp) / float(max_hp)
		_set_glow_intensity(clamp(1.0 - ratio, 0.1, 1.0))


func _spawn_damage_effects(amount: int) -> void:
	var effect_scene = load("res://Gres/Scenes/Effects/expl_boss.tscn")
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)
	var dir := Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
	effect.global_position = global_position + dir * randf_range(20.0, 50.0)
	effect.scale = Vector2.ONE * randf_range(0.8, 1.5)


func spawn_damage_popup(amount: int) -> void:
	var lbl := preload("res://Gres/Scenes/UI/damage_label.tscn").instantiate()
	get_tree().current_scene.add_child(lbl)
	lbl.show_damage(amount, global_position)


# ================================================================
# == ATTACK PATTERN
# ================================================================
func _on_Timer_drone_spawn_timeout() -> void:
	if is_dying: return
	_spawn_drone()

func _on_Timer_pattern_timeout() -> void:
	if is_dying: return
	_execute_pattern()

func _execute_pattern() -> void:
	var r := randi() % 100
	match Global.state:
		"PHASE1":
			if r < cannon_phase1_alt_chance: _fire_cannon_alternate()
			else:                             _fire_center_laser()
		"PHASE2":
			_fire_cannon_simultaneous()
			_spawn_plasma_ring()
		"PHASE3":
			_fire_cannon_rapid()
			_core_pulse_attack()
			if r < spiral_trigger_chance: _spiral_burst_attack()

func _fire_cannon_alternate() -> void:
	if cannons.size() < 2:
		for c in cannons:
			if c: c.call("charge_and_fire", "beam")
		return
	if randi() % 2 == 0: cannons[0].call("charge_and_fire", "beam")
	else:                 cannons[1].call("charge_and_fire", "missile")

func _fire_cannon_simultaneous() -> void:
	for c in cannons: c.call_deferred("charge_and_fire", cannon_phase2_pattern)

func _fire_cannon_rapid() -> void:
	var count := cannon_rapid_fire_count_hard if Global.dificulty == "hard" else cannon_rapid_fire_count
	for c in cannons: c.call_deferred("rapid_fire", count)

func _fire_center_laser() -> void:
	if core and core.has_method("fire_center_laser"): core.call("fire_center_laser")

func _spawn_plasma_ring() -> void:
	var ring_count := 3
	match Global.dificulty:
		"normal", "medium": ring_count = 4
		"hard":             ring_count = 6
	if core and core.has_method("spawn_plasma_ring"): core.call_deferred("spawn_plasma_ring", ring_count)

func _core_pulse_attack() -> void:
	if core and core.has_method("pulse_shock"): core.call_deferred("pulse_shock")

func _spiral_burst_attack() -> void:
	if not bullet_scene: return
	for step in range(spiral_steps):
		for arm in range(spiral_arms):
			var a := (TAU / spiral_arms) * arm + (TAU / spiral_steps) * step
			var b := bullet_scene.instantiate()
			get_parent().add_child(b)
			b.global_position = global_position
			b.direction = Vector2.RIGHT.rotated(a)
		await get_tree().create_timer(spiral_step_delay).timeout


func _spawn_drone() -> void:
	if not drone_scene: return
	var count := drone_wave_count_easy
	match Global.dificulty:
		"normal", "medium": count = drone_wave_count_medium
		"hard":             count = drone_wave_count_hard
	for _i in range(count):
		var d := drone_scene.instantiate()
		get_parent().add_child(d)
		var dir := Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
		d.global_position = global_position + dir * randf_range(drone_spawn_offset_min, drone_spawn_offset_max)
		if d.has_method("set_target"): d.set_target(player)
	t_drone_spawn.start()


func _supernova() -> void:
	var s := supernova_scene.instantiate()
	get_parent().add_child(s); s.global_position = global_position


func _teleport() -> void:
	var tfx := _TeleportFX.new(); tfx.tp_col = _phase_color; add_child(tfx)
	await get_tree().create_timer(teleport_windup).timeout
	if is_instance_valid(player):
		var a := randf() * TAU
		global_position = player.global_position + Vector2(cos(a), sin(a)) * randf_range(teleport_radius_min, teleport_radius_max)
	var tfx2 := _TeleportFX.new(); tfx2.tp_col = _phase_color; tfx2.is_arrival = true; add_child(tfx2)


# ================================================================
# == SHOOT
# ================================================================
func _spawn_from_point(spawn_pos: Vector2, scene: PackedScene) -> void:
	if not scene: return
	var bullet := scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	var spread := 2.0
	bullet.global_position = spawn_pos + Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
	var dir: Vector2
	if has_node("dir"): dir = ($dir.global_position - spawn_pos).normalized()
	else:               dir = Vector2(0, -1).rotated(global_rotation)
	dir = dir.rotated(deg_to_rad(randf_range(-shoot_spread_deg, shoot_spread_deg)))
	bullet.rotation = dir.angle()
	if bullet.has_method("set_direction"): bullet.set_direction(dir)


func shoot() -> void:
	if not can_shoot: return
	can_shoot = false
	_spawn_from_point($Muzzle.global_position, bullet_scene)
	for mn in shoot_muzzle_nodes:
		if has_node(mn): _spawn_from_point(get_node(mn).global_position, bullet_scene)


# ================================================================
# == HURT / SEGNALI
# ================================================================
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if not area.is_in_group("p_bullet"): return
	area.queue_free()
	if not invulnerable:
		var dmg := _get_bullet_damage(area)
		take_damage(int(dmg))


func _get_bullet_damage(area) -> float:
	if area.has_meta("damage"):                    return area.get_meta("damage")
	if GlobalWeapons.current_weapon.has("damage"): return GlobalWeapons.current_weapon["damage"]
	return 10.0 * Global.player_damage


func _on_stop_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_teleport()
		if has_node("StopArea/coll"):            GlobalTweens.deactivate($StopArea/coll)
		if has_node("Timers/TimerActivateStop"): $Timers/TimerActivateStop.start()


func _on_timer_shield_timeout() -> void:
	GlobalTweens.fade($Shield, 0.0, 1.0, 0.5)

func _on_timer_shield_dur_timeout() -> void:
	GlobalTweens.fade($Shield, 1.0, 0.0, 0.5)

func _on_timer_shoot_timeout() -> void:
	can_shoot = true; t_shoot.wait_time = shoot_time; t_shoot.start(); shoot()

func _on_timer_teleport_timeout() -> void:
	if Global.state == "PHASE2": _teleport()
	$Timers/Timer_teleport.start()

func _on_timer_dash_timeout() -> void:
	if randi() % 100 < 50: GlobalTweens.slide_out(self, Vector2(dash_distance, dash_distance), dash_speed, dash_duration)
	else:                   GlobalTweens.slide_in(self,  Vector2(dash_distance, dash_distance), dash_speed, dash_duration)
	$Timers/Timer_dash.wait_time = randi_range(dash_interval_min, dash_interval_max)
	$Timers/Timer_dash.start()

func _on_timer_supernova_timeout() -> void:
	if Global.state == "PHASE3": _supernova()
	$Timers/Timer_supernova.start()

func _on_timer_activate_stop_timeout() -> void:
	if has_node("StopArea/coll"): GlobalTweens.activate($StopArea/coll)


# ================================================================
# == HELPERS
# ================================================================
func _init_cannons() -> void:
	if has_node(cannon_left_node):
		cannons.append(get_node(cannon_left_node))
	elif cannon_scene:
		var cL := cannon_scene.instantiate(); add_child(cL); cL.position = Vector2(-150, -20); cannons.append(cL)
	if has_node(cannon_right_node):
		cannons.append(get_node(cannon_right_node))
	elif cannon_scene:
		var cR := cannon_scene.instantiate(); add_child(cR); cR.position = Vector2(150, -20); cannons.append(cR)
	for c in cannons:
		if c.has_method("set_player"): c.set_player(player)


func _set_glow_intensity(i: float) -> void:
	return
	var spr := $Body if has_node("Body") else null
	if spr and spr.material and spr.material.has_parameter("glow_intensity"):
		spr.material.set("shader_param/glow_intensity", i)


func _spawn_aura() -> void:
	if is_instance_valid(_aura_node): _aura_node.queue_free()
	_aura_node = _BossAuraFX.new()
	_aura_node.aura_col = _phase_color
	add_child(_aura_node)


# ================================================================
# == LOOT
# ================================================================
func _give_loot() -> void:
	var reward = randi_range(200, 400)
	GlobalStats.gold += reward
	Global.update_mission_progress("rich_game_1", reward)
	Global.update_mission_progress("rich_game_2", reward)
	Global.update_mission_progress("rich_game_3", reward)

	var diff := Global.dificulty
	var shard_c  = {"easy": 10, "normal": 15, "hard": 20}.get(diff, 10)
	var tablet_c = {"easy": 50, "normal": 70, "hard": 90}.get(diff, 50)
	var mk = {"easy": "boss_killer_1", "normal": "boss_killer_2", "hard": "boss_killer_3"}.get(diff, "")
	if mk != "": Global.update_mission_progress(mk, 1)
	if randi() % 100 < shard_c:
		match ["ice", "magma", "light", "void"].pick_random():
			"ice":   GlobalStats.ice_shard  += 1
			"magma": GlobalStats.magma_shard += 1
			"light": GlobalStats.light_shard += 1
			"void":  GlobalStats.void_shard  += 1
	if randi() % 100 < tablet_c: GlobalStats.tablet += 1
	if diff != "easy" and randi() % 1000 < 1: Global.spin_gem += 1
	match diff:
		"easy":
			if randi() % 100 < 2: Global.wrath_icons["easy"] = true
		"normal":
			if randi() % 100 < 2: Global.wrath_icons["easy"]   = true
			if randi() % 100 < 5: Global.wrath_icons["normal"] = true
		"hard":
			if randi() % 100 < 2:  Global.wrath_icons["easy"]   = true
			if randi() % 100 < 5:  Global.wrath_icons["normal"] = true
			if randi() % 100 < 10: Global.wrath_icons["hard"]   = true


# ================================================================
# == MORTE
# ================================================================
func _die() -> void:
	if is_dying: return
	is_dying = true
	invulnerable = true
	Global.state = "DYING"
	GlobalStats.kill_boss_total += 1
	Global.boss_killed = true

	# Blocca tutto
	set_physics_process(false)
	if has_node("HurtBox"):
		$HurtBox.set_deferred("monitoring", false)
		$HurtBox.set_deferred("monitorable", false)
	for c in cannons:
		if c and c.has_method("shutdown"): c.shutdown()

	_give_loot()
	Global.register_found_weapon("BLOOD_NEXUS", "legendary")

	_perform_death_animation()


func _perform_death_animation() -> void:
	# ---- FASE 1: il core implode ----
	if core and core.has_method("implode"): core.call_deferred("implode")

	# ---- FASE 2: FX esistente _DeathFX (NON TOCCATO) ----
	var dfx := _DeathFX.new()
	dfx.death_col = _phase_color
	get_parent().add_child(dfx)
	dfx.global_position = global_position

	# ---- FASE 3: esplosioni progressive ----
	var expl_scene = load("res://Gres/Scenes/Effects/expl_boss.tscn")
	for i in range(death_explosion_count):
		await get_tree().create_timer(death_explosion_duration / death_explosion_count).timeout
		if not is_instance_valid(self): return
		if expl_scene:
			var e = expl_scene.instantiate()
			get_parent().add_child(e)
			var d2 := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			e.global_position = global_position + d2 * randf_range(15.0, 90.0)
			e.scale = Vector2.ONE * randf_range(0.7, 2.2)
			e.modulate = Color(randf_range(0.8, 1.0), randf_range(0.0, 0.3), randf_range(0.1, 0.5))

	# ---- FASE 4: onde di shockwave multiple ----
	for wi in range(death_wave_count):
		if not is_instance_valid(self): return
		var wave_fx := _DeathShockwave.new()
		wave_fx.wave_col = _phase_color
		wave_fx.wave_index = wi
		wave_fx.max_radius = death_final_radius * (0.5 + wi * 0.15)
		get_parent().add_child(wave_fx)
		wave_fx.global_position = global_position
		await get_tree().create_timer(death_wave_interval).timeout

	# Onda bianca finale
	if is_instance_valid(self):
		var final_wave := _DeathShockwave.new()
		final_wave.wave_col = Color(1.0, 1.0, 1.0, 1.0)
		final_wave.max_radius = death_final_radius * 1.8
		final_wave.width_start = 10.0
		get_parent().add_child(final_wave)
		final_wave.global_position = global_position

	# ---- FASE 5: rotazione frenetica + dissolvenza ----
	if audio:
		var expl_path := "res://Gres/Music/SE/fx/explosion_1.ogg"
		if ResourceLoader.exists(expl_path):
			audio.stream = load(expl_path)
		audio.play()

	var spin_elapsed := 0.0
	while spin_elapsed < death_spin_duration and is_instance_valid(self):
		var t := spin_elapsed / death_spin_duration
		var spd = lerp(death_spin_speed_start, death_spin_speed_end, pow(t, 2.0))
		rotation += deg_to_rad(spd * get_process_delta_time() * 60.0)
		# Dissolvenza contestuale alla rotazione
		modulate.a = lerp(1.0, 0.0, t)
		queue_redraw()
		await get_tree().process_frame
		spin_elapsed += get_process_delta_time()

	# ---- FINE: scompare ----
	if is_instance_valid(self):
		queue_free()


# ================================================================
# == FX DRAW CLASSES (ORIGINALI NON TOCCATE)
# ================================================================

class _BossAuraFX extends Node2D:
	var aura_col: Color = Color(0.8, 0.0, 0.1)
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 3.0) * 0.5 + 0.5
		var r := 36.0 + p * 10.0
		draw_circle(Vector2.ZERO, r * 1.2, Color(aura_col.r, aura_col.g, aura_col.b, 0.07))
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(aura_col.r, aura_col.g, aura_col.b, 0.28 + p * 0.18), 3.0, true)
		for oi in range(3):
			var oa := _t * (1.2 + oi * 0.5) + oi * TAU / 3.0
			var op := Vector2(cos(oa), sin(oa)) * (r * (0.5 + oi * 0.15))
			draw_circle(op, 4.0, Color(1.0, 0.3, 0.3, 0.85))


class _PhaseTransFX extends Node2D:
	var fx_col: Color = Color(0.6, 0.0, 0.0)
	var _age: float = 0.0; var _dur: float = 1.8
	func _process(delta): _age += delta; queue_redraw(); if _age >= _dur: queue_free()
	func _draw():
		var t := _age/_dur; var inv := 1.0-t
		var r = lerp(8.0, 280.0, pow(t, 0.5))
		draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(fx_col.r, fx_col.g, fx_col.b, inv*0.88),
				 lerp(7.0, 0.5, t), true)
		for ri in range(12):
			var ra := (TAU/12.0)*ri + _age*3.0
			draw_line(Vector2.ZERO, Vector2(cos(ra), sin(ra)) * r * 0.55,
					  Color(fx_col.r, fx_col.g, fx_col.b, inv*0.5), 2.0, true)
		if t < 0.1:
			draw_circle(Vector2.ZERO, lerp(50.0, 0.0, t/0.1), Color(1.0, 1.0, 1.0, (1.0-t/0.1)*0.85))


class _HitFX extends Node2D:
	var hit_col: Color = Color(0.8, 0.0, 0.1)
	var _age: float = 0.0; var _shards: Array = []
	func _ready():
		for _i in range(8):
			var a := randf()*TAU
			_shards.append({"dir":Vector2(cos(a),sin(a)), "len":randf_range(10.0,22.0)})
	func _process(delta): _age += delta; queue_redraw(); if _age >= 0.28: queue_free()
	func _draw():
		var t := _age/0.28; var inv := 1.0-t
		draw_arc(Vector2.ZERO, lerp(8.0,44.0,pow(t,0.5)), 0, TAU, 32,
				 Color(hit_col.r, hit_col.g, hit_col.b, inv*0.8), lerp(4.0,0.5,t), true)
		for sh in _shards:
			draw_line(Vector2.ZERO, sh.dir*sh.len*min(t*2.5,1.0),
					  Color(hit_col.r, hit_col.g, hit_col.b, inv*0.7), 1.8, true)


class _TeleportFX extends Node2D:
	var tp_col: Color = Color(0.8, 0.0, 0.1); var is_arrival: bool = false
	var _age: float = 0.0
	func _process(delta): _age += delta; queue_redraw(); if _age >= 0.35: queue_free()
	func _draw():
		var t := _age/0.35; var p := t if is_arrival else (1.0-t)
		var r = lerp(5.0, 55.0, p)
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(tp_col.r, tp_col.g, tp_col.b, (1.0-p)*0.85),
				 lerp(4.0, 0.5, p), true)
		for ri in range(8):
			var ra := (TAU/8.0)*ri + _age*(8.0 if is_arrival else -8.0)
			draw_line(Vector2.ZERO, Vector2(cos(ra), sin(ra))*r*0.7,
					  Color(tp_col.r, tp_col.g, tp_col.b, (1.0-p)*0.5), 1.5, true)


class _DeathFX extends Node2D:
	var death_col: Color = Color(1.0, 0.0, 0.3)
	var _age: float = 0.0; var _rays: Array = []
	func _ready():
		for _i in range(18):
			var a := randf()*TAU
			_rays.append({"dir":Vector2(cos(a),sin(a)), "len":randf_range(50.0,200.0), "spd":randf_range(0.7,1.5)})
	func _process(delta): _age += delta; queue_redraw(); if _age >= 2.0: queue_free()
	func _draw():
		var t := _age/2.0; var inv := 1.0-t
		for wi in range(4):
			var ph = fmod(t*1.6+float(wi)*0.25, 1.0)
			var wr = lerp(0.0, 280.0, pow(ph, 0.5))
			draw_arc(Vector2.ZERO, wr, 0, TAU, 48,
					 Color(death_col.r, death_col.g, death_col.b, (1.0-ph)*0.9), lerp(6.0,0.3,ph), true)
		for ray in _rays:
			var tip = ray.dir * ray.len * min(t*ray.spd*2.5, 1.0)
			draw_line(Vector2.ZERO, tip, Color(death_col.r, death_col.g, death_col.b, inv*0.8), 2.5, true)
		if t < 0.4:
			draw_circle(Vector2.ZERO, lerp(45.0,0.0,t/0.4), Color(1.0,1.0,1.0,(1.0-t/0.4)*0.9))


# ================================================================
# == NUOVA FX CLASSE: SHOCKWAVE MORTE
# ================================================================
class _DeathShockwave extends Node2D:
	var wave_col:    Color = Color(1.0, 0.0, 0.3)
	var wave_index:  int   = 0
	var max_radius:  float = 300.0
	var width_start: float = 7.0
	var _age:        float = 0.0
	var _dur:        float = 0.65

	func _process(delta):
		_age += delta
		queue_redraw()
		if _age >= _dur: queue_free()

	func _draw():
		var t   := _age / _dur
		var inv := 1.0 - t
		var r   = lerp(8.0, max_radius, pow(t, 0.45))
		var w   = lerp(width_start, 0.3, t)

		# Onda principale
		draw_arc(Vector2.ZERO, r, 0, TAU, 72,
				 Color(wave_col.r, wave_col.g, wave_col.b, inv * 0.95), w, true)
		# Onda interna sfumata
		draw_arc(Vector2.ZERO, r * 0.82, 0, TAU, 72,
				 Color(wave_col.r, wave_col.g, wave_col.b, inv * 0.4), w * 0.5, true)
		# Raggi esplosivi
		var ray_count := 12 + wave_index * 4
		for ri in range(ray_count):
			var ra := (TAU / ray_count) * ri + _age * (2.0 + wave_index * 0.8)
			var inner = r * 0.6
			var outer = r * (0.85 + randf() * 0.15)
			draw_line(
				Vector2(cos(ra), sin(ra)) * inner,
				Vector2(cos(ra), sin(ra)) * outer,
				Color(wave_col.r + 0.2, wave_col.g, wave_col.b, inv * 0.7),
				lerp(2.5, 0.3, t), true
			)
		# Flash centrale iniziale
		if t < 0.15:
			draw_circle(Vector2.ZERO, lerp(35.0, 0.0, t / 0.15),
						Color(1.0, 1.0, 1.0, (1.0 - t / 0.15) * 0.85))
