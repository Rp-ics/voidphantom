extends Node2D
class_name ShieldMite

# ============================================================
# === PARAMETRI ESPORTATI =====================================
# ============================================================
@export_group("Orbit")
@export var orbit_radius: float = 120.0
@export var orbit_speed_deg: float = 50.0
@export var orbit_offset: float = 0.0

@export_group("Health")
@export var max_hp: int = 3

@export_group("Laser Defense")
@export var laser_damage: float = 8.0
@export var laser_range: float = 200.0
@export var laser_duration: float = 0.3
@export var laser_cooldown: float = 2.0

@export_group("Visual")
@export var shield_color: Color = Color(0.6, 0.2, 1.0, 0.85)   # viola luminoso
@export var tether_color: Color = Color(0.7, 0.3, 1.0, 0.6)

# ============================================================
# === NODI (onready) ==========================================
# ============================================================
@onready var sprite: Sprite2D = $Sprite
@onready var shield_ring: Sprite2D = $ShieldRing
@onready var tether_line: Line2D = $TetherLine
@onready var hurtbox: Area2D = $HurtBox
@onready var laser_hitbox: Area2D = $LaserHitBox
@onready var laser_timer: Timer = $LaserTimer
@onready var pulse_timer: Timer = $PulseTimer
@onready var anim: AnimationPlayer = $AnimPlayer

# ============================================================
# === RUNTIME =================================================
# ============================================================
var boss: Node2D
var hp: int
var player: Node2D
var angle: float = 0.0
var is_firing: bool = false
var is_dead: bool = false

# ============================================================
# === READY ===================================================
# ============================================================
func _ready() -> void:
	add_to_group("barrier_minion")
	set_meta("is_barrier", true)
	
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	
	# Trova il boss (gruppo "boss")
	var bosses = get_tree().get_nodes_in_group("boss")
	if bosses.is_empty():
		await get_tree().process_frame
		bosses = get_tree().get_nodes_in_group("boss")
	boss = bosses[0] if not bosses.is_empty() else null
	
	if not boss:
		queue_free()
		return
	
	# Calcola angolo iniziale dalla posizione relativa
	var dir = global_position - boss.global_position
	angle = dir.angle() + orbit_offset if dir.length() > 0 else randf() * TAU
	
	# Configura Line2D
	tether_line.width = 2.5
	tether_line.default_color = tether_color
	tether_line.antialiased = true
	
	# Timer laser
	laser_timer.wait_time = laser_cooldown
	laser_timer.one_shot = true
	laser_timer.timeout.connect(_on_laser_ready)
	laser_timer.start()
	
	# Timer pulsazione anello
	pulse_timer.wait_time = 0.05
	pulse_timer.timeout.connect(_update_pulse)
	pulse_timer.start()
	
	# Segnali
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	laser_hitbox.body_entered.connect(_on_laser_body_entered)
	
	# Disabilita hitbox laser all'inizio
	laser_hitbox.monitoring = false
	
	# Animazioni
	anim.play("idle")
	_spawn_animation()

# ============================================================
# === PROCESS =================================================
# ============================================================
func _process(delta: float) -> void:
	if is_dead or not is_instance_valid(boss):
		if is_dead: return
		_die()
		return
	
	# Orbita attorno al boss
	angle += deg_to_rad(orbit_speed_deg) * delta
	var target_pos = boss.global_position + Vector2(cos(angle), sin(angle)) * orbit_radius
	global_position = global_position.lerp(target_pos, delta * 10.0)
	
	# Ruota lo Sprite e l'anello verso l'esterno
	var outward = (global_position - boss.global_position).normalized()
	rotation = outward.angle() + PI / 2
	shield_ring.rotation = -rotation   # mantiene l'anello dritto visivamente
	
	# Aggiorna la linea di connessione
	_update_tether()
	
	# Controllo laser
	if player and not is_firing and laser_timer.is_stopped() and not is_dead:
		var dist = global_position.distance_to(player.global_position)
		if dist < laser_range:
			_fire_laser()

# ============================================================
# === TETHER LINE (effetto tratteggiato con alpha) ============
# ============================================================
func _update_tether() -> void:
	if not boss: return
	var local_boss = to_local(boss.global_position)
	tether_line.points = PackedVector2Array([Vector2.ZERO, local_boss])
	
	# Effetto "respiro" sulla linea
	var alpha = 0.4 + sin(Time.get_ticks_msec() * 0.004) * 0.3
	tether_line.default_color.a = alpha

func _update_pulse() -> void:
	if is_dead: return
	# Scala dell'anello
	var t = Time.get_ticks_msec() * 0.002
	var scale_val = 0.9 + sin(t) * 0.15
	shield_ring.scale = Vector2.ONE * scale_val
	
	# Colore pulsante
	var color = shield_color
	color.a = 0.5 + sin(t * 1.5) * 0.3
	shield_ring.modulate = color

# ============================================================
# === SPAWN ANIMATION (leggera) ===============================
# ============================================================
func _spawn_animation() -> void:
	scale = Vector2.ZERO
	var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2.ONE, 0.4)
	
	shield_ring.modulate.a = 0
	var tw2 = create_tween()
	tw2.tween_property(shield_ring, "modulate:a", shield_color.a, 0.3)

# ============================================================
# === LASER ===================================================
# ============================================================
func _on_laser_ready() -> void:
	pass   # possiamo usarlo per un effetto "pronto" ma non necessario

func _fire_laser() -> void:
	if is_firing: return
	is_firing = true
	
	# Animazione (se esiste nell'AnimationPlayer)
	if anim.has_animation("fire_laser"):
		anim.play("fire_laser")
	
	# Attiva hitbox
	laser_hitbox.monitoring = true
	
	# Effetto visivo: Line2D temporanea
	var laser_beam = Line2D.new()
	laser_beam.width = 4.0
	laser_beam.default_color = Color(1.0, 0.2, 0.8, 0.9)
	laser_beam.antialiased = true
	var dir_to_player = global_position.direction_to(player.global_position)
	laser_beam.points = PackedVector2Array([Vector2.ZERO, dir_to_player * laser_range])
	laser_beam.z_index = 10
	add_child(laser_beam)
	
	# Sfarfallio leggero
	var tw = create_tween()
	tw.tween_property(laser_beam, "modulate:a", 0.6, 0.05).set_loops(3)
	
	# Durata laser
	await get_tree().create_timer(laser_duration).timeout
	laser_hitbox.monitoring = false
	laser_beam.queue_free()
	
	is_firing = false
	if anim.has_animation("idle"):
		anim.play("idle")
	
	laser_timer.start()

func _on_laser_body_entered(body: Node2D) -> void:
	if body == player:
		Global.player_hp -= laser_damage
		Global.hurt = true
		# piccolo effetto flash sul player (se supportato)
		if body.has_method("apply_damage_flash"):
			body.apply_damage_flash()

# ============================================================
# === DANNO E MORTE ===========================================
# ============================================================
func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead or not area.is_in_group("p_bullet"): return
	
	hp -= 1
	area.queue_free()
	
	if hp <= 0:
		_die()
	else:
		_take_damage_flash()

func _take_damage_flash() -> void:
	# Flash rosso su sprite e anello
	var orig_sprite = sprite.modulate
	var orig_ring = shield_ring.modulate
	sprite.modulate = Color.RED
	shield_ring.modulate = Color.RED
	if anim.has_animation("damage"):
		anim.play("damage")
		await anim.animation_finished
		anim.play("idle")
	else:
		await get_tree().create_timer(0.1).timeout
	sprite.modulate = orig_sprite
	shield_ring.modulate = orig_ring

func _die() -> void:
	if is_dead: return
	is_dead = true
	
	# Notifica il boss
	if boss and boss.has_method("_on_barrier_minion_died"):
		boss._on_barrier_minion_died(self)
	
	# Disabilita collisioni
	hurtbox.monitoring = false
	laser_hitbox.monitoring = false
	
	# Animazione morte
	if anim.has_animation("death"):
		anim.play("death")
	
	# Esplosione soft (solo scaling e dissolvenza)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tw.tween_property(shield_ring, "modulate:a", 0.0, 0.3)
	tw.tween_property(tether_line, "modulate:a", 0.0, 0.3)
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.3)
	
	# piccoli "frammenti" visivi (opzionale, leggero)
	for i in range(4):
		var fragment = Sprite2D.new()
		fragment.texture = sprite.texture
		fragment.centered = true
		fragment.scale = Vector2(0.3, 0.3)
		fragment.modulate = shield_color
		fragment.global_position = global_position
		get_parent().add_child(fragment)
		var dir = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(60, 120)
		var frag_tw = create_tween()
		frag_tw.set_parallel(true)
		frag_tw.tween_property(fragment, "position", fragment.position + dir, 0.5)
		frag_tw.tween_property(fragment, "modulate:a", 0.0, 0.5)
		frag_tw.tween_property(fragment, "scale", Vector2.ZERO, 0.5)
		frag_tw.finished.connect(fragment.queue_free)
	
	await get_tree().create_timer(0.5).timeout
	queue_free()

# ============================================================
# === UTILITY (opzionale per debug) ===========================
# ============================================================
func set_boss(boss_node: Node2D) -> void:
	boss = boss_node
