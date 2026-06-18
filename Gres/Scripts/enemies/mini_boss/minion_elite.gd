extends CharacterBody2D
class_name AssaultMantis

# ============================================================
# === STATS PRINCIPALI ===
# ============================================================
@export var max_hp: float = 300.0
@export var move_speed: float = 100.0
@export var melee_damage: float = 35.0

# === DASH ===
@export var dash_speed: float = 550.0
@export var dash_duration: float = 0.4
@export var dash_cooldown: float = 3.0

# === SHOCKWAVE ===
@export var shockwave_damage: float = 25.0
@export var shockwave_cooldown: float = 5.0

# === MISSILI ===
@export var missile_barrage_count: int = 3
@export var missile_cooldown: float = 4.0
@export var missile_scene: PackedScene

# === NUOVE SKILL: VELENO ===
@export var poison_spray_count: int = 5
@export var poison_damage: float = 8.0       # danno al secondo
@export var poison_duration: float = 3.0
@export var poison_projectile_scene: PackedScene   # proiettile velenoso

# === NUOVA SKILL: TELEPORT SLASH ===
@export var teleport_damage: float = 45.0
@export var teleport_cooldown: float = 8.0

# === TIMER RANDOM SKILL ===
@export var random_skill_interval_min: float = 5.0
@export var random_skill_interval_max: float = 8.0

# ============================================================
# === COLORI EPICI ===
# ============================================================
var neon_green: Color = Color(0.2, 1.0, 0.3, 1.0)
var poison_purple: Color = Color(0.8, 0.1, 0.9, 1.0)
var dash_cyan: Color = Color(0.0, 0.8, 1.0, 1.0)
var shockwave_orange: Color = Color(1.0, 0.5, 0.0, 1.0)

# ============================================================
# === STATI ===
# ============================================================
enum State { CHASE, DASH, SHOCKWAVE, POISON_SPRAY, TELEPORT_SLASH, HURT }
var state: State = State.CHASE
var hp: float
var player: Node2D
var rng = RandomNumberGenerator.new()
var teleport_target_pos: Vector2 = Vector2.ZERO

# === DRAW VARIABILI ===
var _glow_intensity: float = 0.0
var _charge_progress: float = 0.0          # per carica shockwave/teleport
var _damage_flash: float = 0.0
var _hover_offset: float = 0.0
var _wing_flap: float = 0.0
var _rotation_current: float = 0.0
var _rotation_target: float = 0.0
var _rotation_timer: float = 0.0
var _dash_trail_pos: Vector2 = Vector2.ZERO
var _poison_clouds: Array = []             # nuvole di veleno attive

# === NODI ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox
@onready var melee_hitbox: Area2D = $MeleeHitBox
@onready var shockwave_area: Area2D = $ShockwaveArea
@onready var dash_timer: Timer = $DashCooldown
@onready var shockwave_timer: Timer = $ShockwaveCooldown
@onready var missile_timer: Timer = $MissileCooldown
@onready var teleport_timer: Timer = $TeleportCooldown
@onready var random_skill_timer: Timer = $RandomSkillTimer
@onready var anim: AnimationPlayer = $Anim

# ============================================================
# === READY ===
# ============================================================
func _ready() -> void:
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	melee_hitbox.body_entered.connect(_on_melee_hitbox_body_entered)
	shockwave_area.body_entered.connect(_on_shockwave_body_entered)
	
	dash_timer.wait_time = dash_cooldown
	dash_timer.timeout.connect(_start_dash)
	
	shockwave_timer.wait_time = shockwave_cooldown
	shockwave_timer.timeout.connect(_start_shockwave)
	
	missile_timer.wait_time = missile_cooldown
	missile_timer.timeout.connect(_fire_missiles)
	
	if teleport_timer:
		teleport_timer.wait_time = teleport_cooldown
	
	random_skill_timer.wait_time = rng.randf_range(random_skill_interval_min, random_skill_interval_max)
	random_skill_timer.timeout.connect(_use_random_skill)
	random_skill_timer.start()
	
	# Inizializza hitbox disattivi
	melee_hitbox.monitoring = false
	shockwave_area.monitoring = false
	
	sprite.rotation = 0
	state = State.CHASE

# ============================================================
# === PROCESS & DRAW ===
# ============================================================
func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	if state == State.HURT: return
	
	_update_visuals(delta)
	_update_rotation(delta)
	
	match state:
		State.CHASE:
			_chase_behavior(delta)
		State.DASH:
			_dash_behavior(delta)
		State.SHOCKWAVE:
			_shockwave_behavior(delta)
		State.POISON_SPRAY:
			_poison_spray_behavior(delta)
		State.TELEPORT_SLASH:
			_teleport_slash_behavior(delta)
	
	queue_redraw()

func _draw() -> void:
	# === 1. AURA NEON (sempre) ===
	if _glow_intensity > 0.05:
		for i in range(2):
			var alpha = _glow_intensity * (0.35 - i * 0.1)
			draw_circle(Vector2.ZERO, 55 + i * 10, Color(neon_green.r, neon_green.g, neon_green.b, alpha))
	
	# === 2. CARICA (shockwave, teleport, poison) ===
	if state == State.SHOCKWAVE or state == State.TELEPORT_SLASH or state == State.POISON_SPRAY:
		if _charge_progress > 0:
			var ring_radius = 40 + _charge_progress * 50
			var ring_color = neon_green if state == State.SHOCKWAVE else (poison_purple if state == State.POISON_SPRAY else dash_cyan)
			ring_color.a = 0.7 - _charge_progress * 0.5
			draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 40, ring_color, 4.0, false)
			
			# Cerchio interno pulsante
			var inner_alpha = sin(_charge_progress * PI) * 0.6
			draw_circle(Vector2.ZERO, 25 + _charge_progress * 20, Color(1.0, 0.8, 0.2, inner_alpha))
	
	# === 3. SCIA DASH ===
	if state == State.DASH and _dash_trail_pos != Vector2.ZERO:
		draw_circle(_dash_trail_pos, 18, Color(dash_cyan.r, dash_cyan.g, dash_cyan.b, 0.6))
		draw_circle(_dash_trail_pos * 0.7, 12, Color(dash_cyan.r, dash_cyan.g, dash_cyan.b, 0.4))
	
	# === 4. DANNO FLASH ===
	if _damage_flash > 0:
		draw_arc(Vector2.ZERO, 50, 0, TAU, 36, Color(1.0, 0.2, 0.2, _damage_flash), 6.0, false)
	
	# === 5. ALI ENERGETICHE (effetto movimento) ===
	var wing_angle = sin(_wing_flap) * 0.8
	# Ala sinistra
	draw_line(Vector2(-25, -5), Vector2(-45, -20 + wing_angle * 8), neon_green, 3.0)
	draw_line(Vector2(-25, -5), Vector2(-40, 5 + wing_angle * 6), neon_green, 2.5)
	# Ala destra
	draw_line(Vector2(25, -5), Vector2(45, -20 + wing_angle * 8), neon_green, 3.0)
	draw_line(Vector2(25, -5), Vector2(40, 5 + wing_angle * 6), neon_green, 2.5)
	
	# === 6. NUVOLE DI VELENO ATTIVE ===
	for cloud in _poison_clouds:
		var pos = cloud["pos"]
		var alpha = cloud["alpha"]
		draw_circle(pos, 20, Color(poison_purple.r, poison_purple.g, poison_purple.b, alpha * 0.4))
		for i in range(3):
			draw_circle(pos + Vector2(rng.randf_range(-15, 15), rng.randf_range(-15, 15)), 5, Color(0.7, 0.1, 0.9, alpha * 0.6))
	
	# === 7. EFFETTO HOVER (particelle sotto) ===
	var hover_y = sin(_hover_offset) * 5
	for i in range(3):
		var x = -18 + i * 18
		draw_circle(Vector2(x, 35 + hover_y), 3, Color(neon_green.r, neon_green.g, neon_green.b, 0.4))

# ============================================================
# === COMPORTAMENTI ===
# ============================================================
func _chase_behavior(delta: float) -> void:
	var dir = global_position.direction_to(player.global_position)
	velocity = dir * move_speed
	move_and_slide()
	_glow_intensity = 0.5

func _dash_behavior(delta: float) -> void:
	velocity = dash_direction * dash_speed
	move_and_slide()
	_glow_intensity = 1.0
	_dash_trail_pos = -velocity.normalized() * 25   # trail dietro
	# Fine dash dopo durata
	if get_process_delta_time() > dash_duration:
		_end_dash()

func _shockwave_behavior(delta: float) -> void:
	velocity = Vector2.ZERO
	_charge_progress += delta / 0.8   # tempo di carica
	if _charge_progress >= 1.0:
		_charge_progress = 0.0
		shockwave_area.monitoring = true
		await get_tree().create_timer(0.4).timeout
		shockwave_area.monitoring = false
		state = State.CHASE
		anim_play("idle")

func _poison_spray_behavior(delta: float) -> void:
	velocity = Vector2.ZERO
	_charge_progress += delta / 0.6
	if _charge_progress >= 1.0:
		_charge_progress = 0.0
		_fire_poison_spray()
		state = State.CHASE
		anim_play("idle")

func _teleport_slash_behavior(delta: float) -> void:
	velocity = Vector2.ZERO
	_charge_progress += delta / 0.5
	if _charge_progress >= 1.0:
		_charge_progress = 0.0
		_perform_teleport_slash()
		state = State.CHASE
		anim_play("idle")

# ============================================================
# === SKILL ORIGINALI ===
# ============================================================
var dash_direction: Vector2 = Vector2.ZERO

func _start_dash() -> void:
	if state != State.CHASE: return
	dash_direction = global_position.direction_to(player.global_position)
	state = State.DASH
	melee_hitbox.monitoring = true
	anim_play("dash")
	await get_tree().create_timer(dash_duration).timeout
	_end_dash()

func _end_dash() -> void:
	if state == State.DASH:
		melee_hitbox.monitoring = false
		state = State.CHASE
		anim_play("idle")
		_dash_trail_pos = Vector2.ZERO

func _start_shockwave() -> void:
	if state != State.CHASE: return
	state = State.SHOCKWAVE
	_charge_progress = 0.0
	anim_play("shockwave_charge")

func _fire_missiles() -> void:
	if state != State.CHASE or not missile_scene: return
	for i in range(missile_barrage_count):
		var m = missile_scene.instantiate()
		get_parent().add_child(m)
		m.global_position = global_position
		if m.has_method("set_target"):
			m.set_target(player)
		elif m.has_meta("target"):
			m.set_meta("target", player)

# ============================================================
# === NUOVE SKILL RANDOM ===
# ============================================================
func _use_random_skill() -> void:
	if state != State.CHASE:
		random_skill_timer.start(rng.randf_range(random_skill_interval_min, random_skill_interval_max))
		return
	
	var available_skills = []
	if dash_timer.is_stopped():
		available_skills.append("dash")
	if shockwave_timer.is_stopped():
		available_skills.append("shockwave")
	if missile_timer.is_stopped():
		available_skills.append("missiles")
	if teleport_timer and teleport_timer.is_stopped():
		available_skills.append("teleport")
	available_skills.append("poison")   # Poison non ha cooldown separato, ma limitiamo con timer
	
	if available_skills.is_empty():
		random_skill_timer.start(2.0)
		return
	
	var chosen = available_skills.pick_random()
	match chosen:
		"dash":
			_start_dash()
			dash_timer.start()
		"shockwave":
			_start_shockwave()
			shockwave_timer.start()
		"missiles":
			_fire_missiles()
			missile_timer.start()
		"teleport":
			_start_teleport_slash()
			if teleport_timer: teleport_timer.start()
		"poison":
			_start_poison_spray()
	
	random_skill_timer.start(rng.randf_range(random_skill_interval_min, random_skill_interval_max))

func _start_poison_spray() -> void:
	if state != State.CHASE: return
	state = State.POISON_SPRAY
	_charge_progress = 0.0
	anim_play("poison_charge")

func _fire_poison_spray() -> void:
	# Spruzza proiettili a ventaglio
	if poison_projectile_scene:
		for i in range(poison_spray_count):
			var angle_offset = deg_to_rad(-40 + i * 20)
			var dir = global_position.direction_to(player.global_position).rotated(angle_offset)
			var p = poison_projectile_scene.instantiate()
			get_parent().add_child(p)
			p.global_position = global_position
			p.direction = dir
			p.speed = 200
			if p.has_method("set_poison"):
				p.set_poison(poison_damage, poison_duration)
	# Effetto aggiuntivo: nube di veleno attorno (danno area)
	var cloud = {"pos": Vector2.ZERO, "alpha": 1.0, "timer": 0.0}
	_poison_clouds.append(cloud)
	create_tween().tween_method(func(val): cloud["alpha"] = val, 1.0, 0.0, 2.0)
	await get_tree().create_timer(2.0).timeout
	_poison_clouds.erase(cloud)

func _start_teleport_slash() -> void:
	if state != State.CHASE: return
	state = State.TELEPORT_SLASH
	_charge_progress = 0.0
	anim_play("teleport_charge")

func _perform_teleport_slash() -> void:
	if not player: return
	
	# Calcola la posizione "dietro" il player (dalla parte opposta della mantide)
	var dir_to_player = (player.global_position - global_position).normalized()
	var behind_player = player.global_position + dir_to_player * 45
	
	# Disabilita momentaneamente l'hitbox per evitare danni durante il volo
	melee_hitbox.monitoring = false
	
	# Effetto flash sulla mantide
	modulate = Color(1.0, 0.5, 1.0, 1.0)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# Teletrasporto epico con quantum_jump (scala a zero → sposta → scala a uno)
	GlobalTweens.quantum_jump(self, behind_player, 0.25)
	
	# Attendi che il teletrasporto sia completato
	await get_tree().create_timer(0.25).timeout
	
	# Ora riattiva l'hitbox e controlla le collisioni
	melee_hitbox.monitoring = true
	await get_tree().physics_frame   # Assicura che il motore fisico aggiorni le collisioni
	
	var bodies = melee_hitbox.get_overlapping_bodies()
	for body in bodies:
		if body == player:
			Global.player_hp -= teleport_damage
			Global.hurt = true
			# Knockback per allontanare il player
			if player.has_method("apply_knockback"):
				var knockback_dir = (player.global_position - global_position).normalized()
				player.apply_knockback(knockback_dir * 350)
	
	# Disattiva nuovamente l'hitbox (verrà riattivata solo al prossimo teletrasporto o dash)
	melee_hitbox.monitoring = false

# ============================================================
# === ANIMAZIONI & HELPER ===
# ============================================================
func anim_play(name: String) -> void:
	if anim and anim.has_animation(name):
		anim.play(name)
		
func _update_visuals(delta: float) -> void:
	_hover_offset += delta * 6
	_wing_flap += delta * 12
	_glow_intensity = lerp(_glow_intensity, 0.0, delta * 2)
	_damage_flash = lerp(_damage_flash, 0.0, delta * 12)
	
	# Hover leggero
	sprite.position.y = sin(_hover_offset) * 3

func _update_rotation(delta: float) -> void:
	if not player or state == State.DASH: return
	_rotation_timer += delta
	if _rotation_timer >= 0.08:
		_rotation_target = global_position.direction_to(player.global_position).angle()
		_rotation_timer = 0.0
	_rotation_current = lerp_angle(_rotation_current, _rotation_target, 8 * delta)
	sprite.rotation = _rotation_current

# ============================================================
# === COMBAT & DANNO ===
# ============================================================
func _on_melee_hitbox_body_entered(body: Node2D) -> void:
	if body == player and state == State.DASH:
		Global.player_hp -= melee_damage
		Global.hurt = true

func _on_shockwave_body_entered(body: Node2D) -> void:
	if body == player:
		Global.player_hp -= shockwave_damage
		Global.hurt = true
		if body.has_method("apply_curse"):
			body.apply_curse(0.5, 2.0)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		var dmg = _get_bullet_damage(area)
		hp -= dmg
		area.queue_free()
		
		_damage_flash = 1.0
		modulate = Color(1.5, 0.5, 0.5, 1.0)
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
		
		if hp <= 0:
			_die()

func _get_bullet_damage(area: Area2D) -> float:
	if area.has_meta("damage"): return area.get_meta("damage")
	elif GlobalWeapons.current_weapon.has("damage"): return GlobalWeapons.current_weapon["damage"]
	return 10.0 * Global.player_damage

func _die() -> void:
	# Esplosione epica
	var tw = create_tween()
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	tw.parallel().tween_method(func(x): _glow_intensity = x, 1.0, 0.0, 0.5)
	await tw.finished
	queue_free()
