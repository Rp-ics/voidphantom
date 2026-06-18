extends CharacterBody2D
class_name ScarabDrone

@export var move_speed: float = 150.0
@export var max_hp: float = 40.0
@export var contact_damage: float = 12.0
@export var shoot_interval: float = 2.0
@export var bullet_scene: PackedScene

# === DASH MECHANICS ===
@export var dash_speed: float = 800.0
@export var dash_cooldown: float = 3.0
@export var dash_charge_time: float = 0.6
@export var dash_range: float = 280.0

# === VISUAL COLORS (neon rosa/ciano) ===
var pink_neon: Color = Color(1.0, 0.2, 0.7, 1.0)
var pink_glow: Color = Color(1.0, 0.4, 0.9, 0.5)
var energy_cyan: Color = Color(0.2, 0.9, 1.0, 0.8)
var energy_purple: Color = Color(0.8, 0.2, 1.0, 0.7)

# === STATE ===
enum State { IDLE, MOVING, CHARGING, DASHING, HURT }
var current_state: State = State.IDLE
var hp: float
var player: Node2D
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO

# === DRAW VARIABILI ===
var _charge_progress: float = 0.0
var _glow_intensity: float = 0.0
var _damage_flash: float = 0.0
var _hover_offset: float = 0.0
var _rotation_current: float = 0.0
var _rotation_target: float = 0.0
var _rotation_timer: float = 0.0
var _engine_pulse: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox
@onready var hitbox: Area2D = $HitBox
@onready var shoot_timer: Timer = $ShootTimer
@onready var dash_area: Area2D = $DashArea
@onready var dash_timer: Timer = $DashTimer

func _ready() -> void:
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	if dash_area:
		dash_area.body_entered.connect(_on_dash_area_body_entered)
		if dash_area.get_child_count() == 0:
			var shape = CollisionShape2D.new()
			var circle_shape = CircleShape2D.new()
			circle_shape.radius = dash_range
			shape.shape = circle_shape
			dash_area.add_child(shape)
	
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_shoot)
	shoot_timer.start()
	
	current_state = State.IDLE

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	
	_update_visuals(delta)
	_update_rotation(delta)
	
	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.MOVING:
			_moving_behavior(delta)
		State.CHARGING:
			_charging_behavior(delta)
		State.DASHING:
			_dashing_behavior(delta)
		State.HURT:
			_hurt_behavior(delta)
	
	queue_redraw()

# ============================================================
# === DRAW EFFECTS (leggeri, solo overlay) ===
# ============================================================
func _draw() -> void:
	# === 1. GLOW INTORNO AL NEMICO ===
	if _glow_intensity > 0.05:
		for i in range(2):
			var alpha = _glow_intensity * (0.3 - i * 0.1)
			draw_circle(Vector2.ZERO, 45 + i * 8, Color(pink_glow.r, pink_glow.g, pink_glow.b, alpha))
	
	# === 2. AURA DI CARICA DASH ===
	if current_state == State.CHARGING:
		var ring_radius = 35 + _charge_progress * 55
		var ring_color = Color(energy_cyan.r, energy_cyan.g, energy_cyan.b, 0.8 - _charge_progress * 0.5)
		draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, ring_color, 4.0, false)
		
		# Cerchio interno pulsante
		var inner_alpha = sin(_charge_progress * PI) * 0.7
		draw_circle(Vector2.ZERO, 20 + _charge_progress * 15, Color(1.0, 0.5, 0.8, inner_alpha))
	
	# === 3. SCIA DASH (leggera, solo quando dash) ===
	if current_state == State.DASHING:
		var dash_trail_alpha = 0.6
		for i in range(2):
			var offset = -dash_direction * (15 + i * 10)
			draw_circle(offset, 12 - i * 3, Color(energy_cyan.r, energy_cyan.g, energy_cyan.b, dash_trail_alpha - i * 0.2))
	
	# === 4. DANNO FLASH ===
	if _damage_flash > 0:
		draw_arc(Vector2.ZERO, 40, 0, TAU, 32, Color(1.0, 0.3, 0.3, _damage_flash), 5.0, false)
	
	# === 5. MOTORE ENERGETICO (sotto il nemico) ===
	var engine_glow = 0.4 + sin(_engine_pulse) * 0.2
	draw_circle(Vector2(0, 22), 10, Color(energy_purple.r, energy_purple.g, energy_purple.b, engine_glow * 0.5))
	draw_circle(Vector2(0, 22), 5, Color(energy_cyan.r, energy_cyan.g, energy_cyan.b, engine_glow * 0.7))
	
	# === 6. PARTICELLE DI LEVITAZIONE (3 puntini sotto) ===
	var hover_y = sin(_hover_offset) * 4
	for i in range(3):
		var x_pos = -12 + i * 12
		var particle_alpha = 0.3 + sin(_hover_offset * 2 + i) * 0.2
		draw_circle(Vector2(x_pos, 28 + hover_y), 2.5, Color(energy_cyan.r, energy_cyan.g, energy_cyan.b, particle_alpha))

# ============================================================
# === COMPORTAMENTI ===
# ============================================================
func _idle_behavior(delta: float) -> void:
	velocity = Vector2.ZERO
	_glow_intensity = 0.3
	if global_position.distance_to(player.global_position) > 150:
		current_state = State.MOVING

func _moving_behavior(delta: float) -> void:
	var dir = global_position.direction_to(player.global_position)
	var perpendicular = dir.rotated(PI/2) * sin(Time.get_ticks_msec() * 0.005) * 0.3
	velocity = (dir + perpendicular).normalized() * move_speed
	move_and_slide()
	_glow_intensity = 0.5
	
	if global_position.distance_to(player.global_position) < 80:
		current_state = State.IDLE

func _charging_behavior(delta: float) -> void:
	velocity = Vector2.ZERO
	_charge_progress += delta / dash_charge_time
	
	if _charge_progress >= 1.0:
		_charge_progress = 1.0
		current_state = State.DASHING
		_perform_dash()

func _dashing_behavior(delta: float) -> void:
	velocity = dash_direction * dash_speed
	move_and_slide()
	_glow_intensity = 1.0
	
	if _check_dash_collision():
		_stop_dash()
	
	# Stop dopo 0.4 secondi
	if get_process_delta_time() > 0.4:
		_stop_dash()

func _hurt_behavior(delta: float) -> void:
	_damage_flash = 1.0
	velocity = -dash_direction * 200
	move_and_slide()
	await get_tree().create_timer(0.15).timeout
	current_state = State.MOVING

# ============================================================
# === DASH MECCANICHE ===
# ============================================================
func _on_dash_area_body_entered(body: Node2D) -> void:
	if body == player and can_dash and current_state != State.DASHING and current_state != State.CHARGING:
		current_state = State.CHARGING
		_charge_progress = 0.0
		can_dash = false

func _perform_dash() -> void:
	dash_direction = global_position.direction_to(player.global_position)
	
	if hitbox:
		hitbox.set_deferred("monitoring", true)
	
	dash_timer.wait_time = dash_cooldown
	dash_timer.start()
	dash_timer.timeout.connect(_on_dash_cooldown_timeout)

func _stop_dash() -> void:
	current_state = State.MOVING
	if hitbox:
		hitbox.set_deferred("monitoring", false)

func _check_dash_collision() -> bool:
	for body in hitbox.get_overlapping_bodies():
		if body == player:
			_apply_dash_damage()
			_stop_dash()
			return true
	return false

func _apply_dash_damage() -> void:
	Global.player_hp -= contact_damage * 1.8
	Global.hurt = true

func _on_dash_cooldown_timeout() -> void:
	can_dash = true
	dash_timer.timeout.disconnect(_on_dash_cooldown_timeout)

# ============================================================
# === VISUAL UPDATE ===
# ============================================================
func _update_visuals(delta: float) -> void:
	_hover_offset += delta * 5
	_engine_pulse += delta * 12
	_glow_intensity = lerp(_glow_intensity, 0.0, delta * 3)
	_damage_flash = lerp(_damage_flash, 0.0, delta * 12)
	
	# Piccolo hover movement
	sprite.position.y = sin(_hover_offset) * 2

func _update_rotation(delta: float) -> void:
	if not player: return
	_rotation_timer += delta
	if _rotation_timer >= 0.08:
		_rotation_target = global_position.direction_to(player.global_position).angle()
		_rotation_timer = 0.0
	_rotation_current = lerp_angle(_rotation_current, _rotation_target, 8 * delta)
	sprite.rotation = _rotation_current

# ============================================================
# === COMBAT ===
# ============================================================
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		var dmg = _get_bullet_damage(area)
		hp -= dmg
		area.queue_free()
		
		if current_state != State.DASHING:
			current_state = State.HURT
			dash_direction = global_position.direction_to(player.global_position)
		
		# Effetto visivo rapido
		modulate = Color(1.5, 0.5, 0.5, 1.0)
		create_tween().tween_property(self, "modulate", Color.WHITE, 0.2)
		
		if hp <= 0:
			_die()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == player and current_state != State.DASHING:
		Global.player_hp -= contact_damage
		Global.hurt = true

func _shoot() -> void:
	if current_state == State.DASHING or current_state == State.CHARGING: return
	
	if not bullet_scene or not is_instance_valid(player): return
	var b = bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position
	b.direction = global_position.direction_to(player.global_position)
	b.speed = 250

func _get_bullet_damage(area: Area2D) -> float:
	if area.has_meta("damage"): return area.get_meta("damage")
	elif GlobalWeapons.current_weapon.has("damage"): return GlobalWeapons.current_weapon["damage"]
	return 10.0 * Global.player_damage

func _die() -> void:
	# Esplosione leggera
	var tw = create_tween()
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tw.parallel().tween_method(func(x): _glow_intensity = x, 1.0, 0.0, 0.4)
	await tw.finished
	queue_free()
