## BossTemplate_Phantom.gd
## ============================================================
## ARCHETIPO: Boss Elusivo — sparisce, si sdoppia, attacca dal nulla.
## OTTIMIZZATO per PC deboli: minime draw call, particelle GPU.
## NOTA: _draw() usata solo per l’effetto della Raffica Esplosiva.
## ============================================================
extends CharacterBody2D
class_name BossTemplate_Phantom

# ============================================================
# === IDENTITÀ ================================================
# ============================================================
@export_group("Boss Identity")
@export var boss_name: String = "Phantom Boss"
@export var hp_key: String = "phantom_hp"
@export var mission_key_easy: String = "boss_killer_1"
@export var mission_key_medium: String = "boss_killer_2"
@export var mission_key_hard: String = "boss_killer_3"
@export var legendary_weapon_drop: String = "PHANTOM CORE"
@export var death_scene_path: String = "res://Gres/Scenes/Story/boss_dead_scene.tscn"
@export var texture_phase_1: Texture
@export var texture_phase_2: Texture
@export var texture_phase_3: Texture

# ============================================================
# === HP ======================================================
# ============================================================
@export_group("Health")
@export var hp_easy: int = 7500
@export var hp_medium: int = 11500
@export var hp_hard: int = 17000
@export var damage_reduction_visible: float = 0.0
@export var invincible_while_invisible: bool = true

# ============================================================
# === INVISIBILITÀ ============================================
# ============================================================
@export_group("Invisibility")
@export var use_invisibility: bool = true
@export var visible_time_easy: float = 4.0
@export var visible_time_medium: float = 2.8
@export var visible_time_hard: float = 1.8
@export var invisible_time_easy: float = 3.0
@export var invisible_time_medium: float = 4.0
@export var invisible_time_hard: float = 5.5
@export var invisible_alpha: float = 0.08
@export var attack_while_invisible: bool = true

# ============================================================
# === CLONI ===================================================
# ============================================================
@export_group("Clones")
@export var use_clones: bool = true
@export var clone_scene: PackedScene
@export var clone_count_easy: int = 1
@export var clone_count_medium: int = 2
@export var clone_count_hard: int = 4
@export var clone_spawn_radius: float = 300.0
@export var clone_phase: int = 2
@export var clone_death_burst: bool = false
@export var bullet_scene: PackedScene

# ============================================================
# === TELEPORT ================================================
# ============================================================
@export_group("Teleport")
@export var use_teleport: bool = true
@export var teleport_probability: float = 0.012
@export var teleport_radius_min: float = 200.0
@export var teleport_radius_max: float = 450.0
@export var teleport_behind_player: bool = false
@export var teleport_points: Array[Node2D]

# ============================================================
# === ATTACCHI ================================================
# ============================================================
@export_group("Attacks - Shadow Strike")
@export var use_shadow_strike: bool = true
@export var shadow_strike_probability: float = 0.006
@export var shadow_strike_damage_easy: float = 25.0
@export var shadow_strike_damage_medium: float = 40.0
@export var shadow_strike_damage_hard: float = 65.0
@export var shadow_strike_range: float = 80.0
@export var explosion_scene: PackedScene

@export_group("Attacks - Mirror Dash")
@export var use_mirror_dash: bool = true
@export var mirror_dash_probability: float = 0.005
@export var mirror_dash_speed: float = 700.0
@export var mirror_dash_count_easy: int = 1
@export var mirror_dash_count_medium: int = 2
@export var mirror_dash_count_hard: int = 3

@export_group("Attacks - Soul Arrows")
@export var use_soul_arrows: bool = true
@export var soul_arrow_probability: float = 0.008
@export var soul_arrow_count_easy: int = 2
@export var soul_arrow_count_medium: int = 4
@export var soul_arrow_count_hard: int = 6
@export var soul_arrow_homing_strength: float = 0.05

@export_group("Attacks - Void Cage")
@export var use_void_cage: bool = false
@export var void_cage_probability: float = 0.003
@export var void_cage_open_width_easy: int = 140
@export var void_cage_open_width_medium: int = 100
@export var void_cage_open_width_hard: int = 60

# === ATTACCO RAFFICA ESPLOSIVA =================================
@export_group("Attacks - Explosive Barrage")
@export var use_explosive_barrage: bool = true
@export var explosive_barrage_probability_easy: float = 0.004
@export var explosive_barrage_probability_medium: float = 0.006
@export var explosive_barrage_probability_hard: float = 0.009
@export var explosive_barrage_allow_invisible: bool = false

@export var explosive_barrage_duration_easy: float = 5.0
@export var explosive_barrage_duration_medium: float = 4.5
@export var explosive_barrage_duration_hard: float = 4.0

@export var explosive_barrage_bullets_per_burst_easy: int = 8
@export var explosive_barrage_bullets_per_burst_medium: int = 12
@export var explosive_barrage_bullets_per_burst_hard: int = 16

@export var explosive_barrage_bullet_speed_easy: float = 150.0
@export var explosive_barrage_bullet_speed_medium: float = 180.0
@export var explosive_barrage_bullet_speed_hard: float = 210.0

@export var explosive_barrage_burst_interval: float = 0.15
@export var explosive_barrage_rotation_speed: float = 2.5

# Nuovi: scena specifica e raggio dell’anello
@export var explosive_barrage_bullet_scene: PackedScene   # se vuoto, usa bullet_scene
@export var explosive_barrage_radius: float = 100.0

# ============================================================
# === COLORE / STILE ==========================================
# ============================================================
@export_group("Visual Style")
@export var aura_color_p1: Color = Color(0.3, 0.0, 0.5, 0.5)
@export var aura_color_p2: Color = Color(0.5, 0.0, 0.8, 0.65)
@export var aura_color_p3: Color = Color(0.8, 0.0, 0.3, 0.8)
@export var trail_color: Color = Color(0.6, 0.0, 1.0, 0.5)

# ============================================================
# === DROPS ===================================================
# ============================================================
@export_group("Drops")
@export var gold_min: int = 160
@export var gold_max: int = 620
@export var shard_chance_easy: float = 0.11
@export var shard_chance_medium: float = 0.17
@export var shard_chance_hard: float = 0.23
@export var tablet_chance_easy: float = 0.52
@export var tablet_chance_medium: float = 0.73
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
var is_invisible: bool = false
var is_invincible: bool = false
var use_phase_two: bool = false
var use_phase_three: bool = false
var _barraging: bool = false
var _barrage_draw_progress: float = 0.0

var player: Node2D
var rng := RandomNumberGenerator.new()
var _max_hp: int = 0
var _current_hp: int = 0
var _clones: Array = []
var _soul_arrows: Array = []

# ============================================================
# === NODI ====================================================
# ============================================================
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

@onready var aura_particles: GPUParticles2D = $AuraParticles if has_node("AuraParticles") else null
@onready var shockwave_particles: GPUParticles2D = $ShockwaveParticles if has_node("ShockwaveParticles") else null
@onready var ghost_trail_particles: GPUParticles2D = $GhostTrailParticles if has_node("GhostTrailParticles") else null
@onready var explosion_particles: GPUParticles2D = $ExplosionParticles if has_node("ExplosionParticles") else null
@onready var cage_particles: GPUParticles2D = $CageParticles if has_node("CageParticles") else null

# ============================================================
# === READY ===================================================
# ============================================================
func _ready() -> void:
	sprite.texture = texture_phase_1
	match Global.dificulty:
		"easy":
			_max_hp = hp_easy
			_current_hp = hp_easy
		"medium":
			_max_hp = hp_medium
			_current_hp = hp_medium
		"hard":
			_max_hp = hp_hard
			_current_hp = hp_hard

	Global.set(hp_key + "_max", _max_hp)
	Global.set(hp_key, _max_hp)
	player = get_tree().get_first_node_in_group("player")

	if aura_particles:
		aura_particles.emitting = true

	_play_anim("idle")

	if use_invisibility:
		_start_visibility_cycle()

# ============================================================
# === PROCESS (animazione draw per Raffica Esplosiva) =========
# ============================================================
func _process(_delta: float) -> void:
	if _barraging:
		queue_redraw()

func _draw() -> void:
	if not _barraging:
		return
	var segments = 32
	var r_spawn = explosive_barrage_radius
	var alpha = sin(_barrage_draw_progress * PI) * 0.7 + 0.3

	# Cerchio di spawn (punteggiato)
	draw_arc(Vector2.ZERO, r_spawn, 0, TAU, 64, Color(1.0, 0.5, 1.0, alpha * 0.5), 2.0)

	# Anelli concentrici pulsanti attorno al cerchio
	for i in range(3):
		var r = r_spawn + _barrage_draw_progress * 40.0 + i * 25.0
		if r > r_spawn + 100: continue
		draw_arc(Vector2.ZERO, r, 0, TAU, segments, Color(0.8, 0.2, 1.0, alpha * (1.0 - i * 0.25)), 2.0)

	# Linee radiali rotanti
	var line_count = 8
	for i in range(line_count):
		var angle = (TAU / line_count) * i + _barrage_draw_progress * 2.0
		var end = Vector2.RIGHT.rotated(angle) * (r_spawn + 20) * abs(sin(_barrage_draw_progress * PI))
		draw_line(Vector2.ZERO, end, Color(1.0, 0.5, 1.0, alpha * 0.4), 2.0)

# ============================================================
# === PHYSICS PROCESS =========================================
# ============================================================
func _physics_process(delta: float) -> void:
	$HP_Bar.max_value = _max_hp
	$HP_Bar.value = _current_hp
	$AppearSound.volume_db = Global.effects_volume
	$CloneBurst.volume_db = Global.effects_volume
	$CloneSpawn.volume_db = Global.effects_volume
	$disapear.volume_db = Global.effects_volume

	_update_homing_arrows(delta)

	match phase:
		1: _phase_one(delta)
		2: _phase_two(delta)
		3: _phase_three(delta)

# ============================================================
# === CICLO VISIBILITÀ ========================================
# ============================================================
func _start_visibility_cycle() -> void:
	while not is_queued_for_deletion():
		var vt = visible_time_easy if Global.dificulty == "easy" \
			else (visible_time_medium if Global.dificulty == "medium" else visible_time_hard)
		await _set_visibility(true, 0.3)
		await get_tree().create_timer(vt).timeout

		var it = invisible_time_easy if Global.dificulty == "easy" \
			else (invisible_time_medium if Global.dificulty == "medium" else invisible_time_hard)
		await _set_visibility(false, 0.4)
		if attack_while_invisible and not is_queued_for_deletion():
			_attack_invisible()
		await get_tree().create_timer(it).timeout

func _set_visibility(show: bool, duration: float) -> Signal:
	is_invisible = not show
	is_invincible = (is_invisible and invincible_while_invisible)

	if show:
		visible = true
		_play_anim("appear")
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 1.0, duration)
		return tw.finished
	else:
		_play_anim("disappear")
		GlobalTweens.glitch_flash($Sprite2D)
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 0.15, 1.0)
		tw.tween_callback(func(): visible = true)
		return tw.finished

func _attack_invisible() -> void:
	if use_shadow_strike and rng.randf() < 0.5:
		_shadow_strike()
	elif use_soul_arrows:
		_fire_soul_arrows()

# ============================================================
# === FASI ====================================================
# ============================================================
func _phase_one(delta: float) -> void:
	_float_toward_player(delta)
	if use_teleport and rng.randf() < teleport_probability: _teleport()
	if use_soul_arrows and rng.randf() < soul_arrow_probability: _fire_soul_arrows()
	if use_mirror_dash and rng.randf() < mirror_dash_probability: _mirror_dash()
	if use_explosive_barrage and rng.randf() < _get_explosive_barrage_prob():
		_explosive_barrage()

func _phase_two(delta: float) -> void:
	_float_toward_player(delta)
	if use_teleport and rng.randf() < teleport_probability * 1.5: _teleport()
	if use_soul_arrows and rng.randf() < soul_arrow_probability * 1.5: _fire_soul_arrows()
	if use_mirror_dash and rng.randf() < mirror_dash_probability * 1.5: _mirror_dash()
	if use_shadow_strike and rng.randf() < shadow_strike_probability: _shadow_strike()
	if use_clones and _clones.size() == 0 and rng.randf() < 0.005: _spawn_clones()
	if use_explosive_barrage and rng.randf() < _get_explosive_barrage_prob() * 1.5:
		_explosive_barrage()

func _phase_three(delta: float) -> void:
	_float_toward_player(delta)
	if use_teleport and rng.randf() < teleport_probability * 2.0: _teleport()
	if use_soul_arrows and rng.randf() < soul_arrow_probability * 2.0: _fire_soul_arrows()
	if use_mirror_dash and rng.randf() < mirror_dash_probability * 2.0: _mirror_dash()
	if use_shadow_strike and rng.randf() < shadow_strike_probability * 1.5: _shadow_strike()
	if use_void_cage and rng.randf() < void_cage_probability: _void_cage()
	if use_clones and _clones.size() == 0 and rng.randf() < 0.008: _spawn_clones()
	if use_explosive_barrage and rng.randf() < _get_explosive_barrage_prob() * 2.0:
		_explosive_barrage()

func _float_toward_player(delta: float) -> void:
	if not can_move or not player: return
	if _barraging: return
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * 80.0
	velocity += Vector2(sin(Time.get_ticks_msec() * 0.002), cos(Time.get_ticks_msec() * 0.003)) * 30.0
	move_and_slide()

# ============================================================
# === HELPER PER DIFFICOLTÀ (RAFFICA) =========================
# ============================================================
func _get_explosive_barrage_prob() -> float:
	match Global.dificulty:
		"easy":   return explosive_barrage_probability_easy
		"medium": return explosive_barrage_probability_medium
		"hard":   return explosive_barrage_probability_hard
	return 0.0

func _get_explosive_barrage_duration() -> float:
	match Global.dificulty:
		"easy":   return explosive_barrage_duration_easy
		"medium": return explosive_barrage_duration_medium
		"hard":   return explosive_barrage_duration_hard
	return 5.0

func _get_explosive_barrage_bullets() -> int:
	match Global.dificulty:
		"easy":   return explosive_barrage_bullets_per_burst_easy
		"medium": return explosive_barrage_bullets_per_burst_medium
		"hard":   return explosive_barrage_bullets_per_burst_hard
	return 12

func _get_explosive_barrage_speed() -> float:
	match Global.dificulty:
		"easy":   return explosive_barrage_bullet_speed_easy
		"medium": return explosive_barrage_bullet_speed_medium
		"hard":   return explosive_barrage_bullet_speed_hard
	return 180.0

# ============================================================
# === TRANSIZIONI =============================================
# ============================================================
func _on_damage(amount: int) -> void:
	if is_invincible or _barraging: return
	var actual = amount * (1.0 - damage_reduction_visible)
	_current_hp -= actual
	if _current_hp <= 0:
		_die()
		return

	var ratio = _current_hp / float(_max_hp)
	if use_phase_two and phase == 1 and ratio <= phase_two_threshold:
		_enter_phase(2)
		return
	elif use_phase_three and phase == 2 and ratio <= phase_three_threshold:
		_enter_phase(3)
		return

var phase_two_threshold: float = 0.6
var phase_three_threshold: float = 0.25

func _enter_phase(p: int) -> void:
	$shadow.texture = $Sprite2D.texture
	$Clone_1.texture = $Sprite2D.texture
	$Clone_2.texture = $Sprite2D.texture
	$Dash.texture = $Sprite2D.texture

	match p:
		1: sprite.texture = texture_phase_1
		2: sprite.texture = texture_phase_2
		3: sprite.texture = texture_phase_3

	phase = p
	can_move = false

	if aura_particles:
		aura_particles.modulate = aura_color_p2 if p == 2 else (aura_color_p3 if p == 3 else aura_color_p1)

	_fx_shockwave()
	_play_anim("transform_p" + str(p))

	if p >= clone_phase and use_clones:
		_spawn_clones()

	await get_tree().create_timer(1.4).timeout
	can_move = true

# ============================================================
# === ATTACCHI ORIGINALI (invariati) ==========================
# ============================================================
func _teleport() -> void:
	_fx_rings_burst()
	await get_tree().create_timer(0.15).timeout

	var target: Vector2
	if teleport_behind_player and player:
		var back = -(player.global_position - global_position).normalized()
		target = player.global_position + back * 120.0
	elif teleport_points.size() > 0:
		target = teleport_points.pick_random().global_position
	elif player:
		var angle = rng.randf() * TAU
		var radius = rng.randf_range(teleport_radius_min, teleport_radius_max)
		target = player.global_position + Vector2(cos(angle), sin(angle)) * radius
	else:
		return

	_fx_leave_ghost(global_position)
	global_position = target
	_fx_shockwave()

func _shadow_strike() -> void:
	if not player: return
	_fx_rings_burst()
	var angle = rng.randf() * TAU
	global_position = player.global_position + Vector2(cos(angle), sin(angle)) * shadow_strike_range

	var dmg = shadow_strike_damage_easy if Global.dificulty == "easy" \
		else (shadow_strike_damage_medium if Global.dificulty == "medium" else shadow_strike_damage_hard)

	_play_anim("shadow_strike")
	_fx_shockwave()

	if global_position.distance_to(player.global_position) < shadow_strike_range + 30:
		Global.player_hp -= dmg
		Global.hurt = true

	if explosion_scene:
		var e = explosion_scene.instantiate()
		get_parent().add_child(e)
		e.global_position = global_position
		e.modulate = aura_color_p3
		await get_tree().create_timer(0.5).timeout
		e.queue_free()

	await get_tree().create_timer(0.3).timeout
	_fx_rings_burst()

func _mirror_dash() -> void:
	if attacking or not player: return
	attacking = true
	_play_anim("mirror_dash")

	var count = mirror_dash_count_easy if Global.dificulty == "easy" \
		else (mirror_dash_count_medium if Global.dificulty == "medium" else mirror_dash_count_hard)

	for i in range(count):
		var dir = (player.global_position - global_position).normalized()
		dir = dir.rotated(deg_to_rad(rng.randf_range(-30, 30)))
		_perform_phantom_dash(dir)
		await get_tree().create_timer(0.2).timeout

	attacking = false

func _perform_phantom_dash(dir: Vector2) -> void:
	for g in range(4):
		var ghost_pos = global_position - dir * g * 25.0
		_fx_leave_ghost(ghost_pos)

	var t := 0.0
	while t < 0.4:
		velocity = dir * mirror_dash_speed
		move_and_slide()
		await get_tree().process_frame
		t += get_process_delta_time()
	velocity = Vector2.ZERO
	_fx_shockwave()

func _fire_soul_arrows() -> void:
	if not player or not bullet_scene: return
	var count = soul_arrow_count_easy if Global.dificulty == "easy" \
		else (soul_arrow_count_medium if Global.dificulty == "medium" else soul_arrow_count_hard)
	_play_anim("soul_arrow")
	for i in range(count):
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position
		var angle = (TAU / count) * i
		b.direction = Vector2.RIGHT.rotated(angle)
		b.speed = 180
		_soul_arrows.append({"bullet": b, "strength": soul_arrow_homing_strength})

func _update_homing_arrows(delta: float) -> void:
	_soul_arrows = _soul_arrows.filter(func(a): return is_instance_valid(a["bullet"]))
	if not player: return
	for arrow_data in _soul_arrows:
		var b = arrow_data["bullet"]
		if not is_instance_valid(b): continue
		var target_dir = (player.global_position - b.global_position).normalized()
		b.direction = b.direction.lerp(target_dir, arrow_data["strength"])

func _void_cage() -> void:
	if attacking or not player: return
	attacking = true
	var center = player.global_position
	var bullets: Array = []
	var open_angle = rng.randi_range(0, 360)
	var open_w = void_cage_open_width_easy if Global.dificulty == "easy" \
		else (void_cage_open_width_medium if Global.dificulty == "medium" else void_cage_open_width_hard)
	var bullet_count = 12
	var radius = 280.0

	for i in range(bullet_count):
		var angle = (360.0 / bullet_count) * i
		if angle > open_angle and angle < open_angle + open_w: continue
		if not bullet_scene: break
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)
		var dir = Vector2.RIGHT.rotated(deg_to_rad(angle))
		b.global_position = center + dir * radius
		b.direction = -dir
		b.speed = 0
		bullets.append(b)

	_fx_shockwave()
	var escape_t = 3.0 if Global.dificulty == "easy" else (2.0 if Global.dificulty == "medium" else 1.2)
	await get_tree().create_timer(escape_t).timeout

	for b in bullets:
		if is_instance_valid(b):
			var tw = b.create_tween()
			tw.tween_property(b, "global_position", center, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(0.6).timeout
	for b in bullets:
		if is_instance_valid(b): b.queue_free()
	attacking = false

func _spawn_clones() -> void:
	$Clone_1.texture = $Sprite2D.texture
	$Clone_2.texture = $Sprite2D.texture
	$shadow.texture = $Sprite2D.texture

	for c in _clones:
		if is_instance_valid(c): c.queue_free()
	_clones.clear()

	var count = clone_count_easy if Global.dificulty == "easy" \
		else (clone_count_medium if Global.dificulty == "medium" else clone_count_hard)
	_play_anim("clone_spawn")
	_fx_shockwave()

	for i in range(count):
		var cl = Sprite2D.new()
		cl.texture = sprite.texture
		cl.scale = sprite.scale
		cl.modulate = Color(1, 1, 1, 0.6)
		cl.z_index = sprite.z_index - 0.1
		get_parent().add_child(cl)
		var angle = (TAU / count) * i
		cl.global_position = global_position + Vector2(cos(angle), sin(angle)) * clone_spawn_radius
		_clones.append(cl)

		var tw = create_tween()
		tw.tween_interval(3.0)
		tw.tween_callback(func():
			if is_instance_valid(cl):
				cl.queue_free()
				_clones.erase(cl)
		)

# ============================================================
# === NUOVO ATTACCO: RAFFICA ESPLOSIVA ========================
# ============================================================
func _explosive_barrage() -> void:
	if attacking or _barraging or not player:
		return
	if not explosive_barrage_allow_invisible and is_invisible:
		return

	var scene = explosive_barrage_bullet_scene if explosive_barrage_bullet_scene else bullet_scene
	if not scene:
		push_warning("Explosive Barrage: no bullet scene set!")
		return

	attacking = true
	_barraging = true
	can_move = false

	_play_anim("barrage_start")

	_barrage_draw_progress = 0.0
	var tween = create_tween().set_loops()
	tween.tween_property(self, "_barrage_draw_progress", 1.0, 0.5)
	tween.tween_property(self, "_barrage_draw_progress", 0.0, 0.5)

	var duration = _get_explosive_barrage_duration()
	var bullets_per_burst = _get_explosive_barrage_bullets()
	var bullet_speed = _get_explosive_barrage_speed()
	var radius = explosive_barrage_radius

	var start_time = Time.get_ticks_msec()
	var angle_offset = 0.0

	while Time.get_ticks_msec() - start_time < duration * 1000:
		if not is_instance_valid(player):
			break

		for i in range(bullets_per_burst):
			var angle = (TAU / bullets_per_burst) * i + angle_offset
			var dir = Vector2.RIGHT.rotated(angle)

			var b = scene.instantiate()
			get_parent().add_child(b)
			b.global_position = global_position + dir * radius
			b.direction = dir
			b.speed = bullet_speed

		angle_offset += explosive_barrage_rotation_speed * explosive_barrage_burst_interval
		await get_tree().create_timer(explosive_barrage_burst_interval).timeout

	tween.kill()
	_barraging = false
	attacking = false
	can_move = true
	queue_redraw()
	_play_anim("barrage_end")

# ============================================================
# === FX HELPERS ==============================================
# ============================================================
func _fx_shockwave() -> void:
	if shockwave_particles:
		shockwave_particles.restart()

func _fx_rings_burst() -> void:
	if shockwave_particles:
		shockwave_particles.restart()

func _fx_leave_ghost(world_pos: Vector2) -> void:
	if ghost_trail_particles:
		var ghost = ghost_trail_particles.duplicate() as GPUParticles2D
		get_parent().add_child(ghost)
		ghost.global_position = world_pos
		ghost.emitting = true
		ghost.one_shot = true
		ghost.finished.connect(ghost.queue_free)

# ============================================================
# === UTILITY =================================================
# ============================================================
func _play_anim(name: String) -> void:
	if anim and anim.has_animation(name) and anim.current_animation != name:
		anim.play(name)

# ============================================================
# === HIT =====================================================
# ============================================================
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		if is_invincible or _barraging:
			area.queue_free()
			return
		var dmg := _get_bullet_damage(area)
		_on_damage(int(dmg))
		area.queue_free()

func _get_bullet_damage(area: Area2D) -> float:
	if area.has_meta("damage"): return area.get_meta("damage")
	elif GlobalWeapons.current_weapon.has("damage"): return GlobalWeapons.current_weapon["damage"]
	return 10.0 * Global.player_damage

# ============================================================
# === MORTE ===================================================
# ============================================================
func _die() -> void:
	$DeathAnim.play("death")
	print("dead")

func _on_death_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death": queue_free()
