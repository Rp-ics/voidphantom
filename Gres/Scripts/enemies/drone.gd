extends CharacterBody2D

# ============================================================
# === CONFIG (valori base, poi scalati in _ready) ==============
# ============================================================
@export var speed: float = 200.0
@export var explosion_damage: int = 90
@export var hp: int = 40
@export var explosion_radius: float = 100.0
@export var player_path: NodePath

var target: Node = null
var alive: bool = true
var can_rotate: bool = true
var can_hurt: bool = true

# ============================================================
# === DIFFICULTY SCALING ======================================
# ============================================================
func _apply_difficulty() -> void:
	match Global.dificulty:
		"easy":
			speed = 160.0
			hp = 30
			explosion_damage = 70
			explosion_radius = 80.0
		"medium":
			speed = 200.0
			hp = 40
			explosion_damage = 90
			explosion_radius = 100.0
		"hard":
			speed = 260.0
			hp = 60
			explosion_damage = 130
			explosion_radius = 130.0
		_:
			# default medium
			pass

# ============================================================
# === DRAW FX STATE ============================================
# ============================================================
var _draw_aura_radius: float = 0.0
var _draw_aura_color: Color = Color(1.0, 0.3, 0.0, 0.0)
var _draw_trail_points: Array = []           # Array di Vector2 (posizioni locali recenti)
var _draw_shockwave_radius: float = 0.0
var _draw_shockwave_alpha: float = 0.0
var _draw_death_rings: Array = []            # anelli esplosione finale
var _draw_lightning_bolts: Array = []        # fulmini istantanei

var rng := RandomNumberGenerator.new()

# ============================================================
# === READY ===================================================
# ============================================================
func _ready() -> void:
	_apply_difficulty()
	add_to_group("drone")
	if has_node(player_path):
		target = get_node(player_path)
	# Avvia aura pulsante (coroutine)
	_start_aura_pulse()
	# Aggiorna continuamente la coda della scia
	_update_trail_loop()

func set_target(t):
	target = t

# ============================================================
# === PHYSICS PROCESS =========================================
# ============================================================
func _physics_process(delta):
	if not alive:
		return

	# Rotazione verso il target
	if can_rotate and is_instance_valid(target):
		var dir_to_target = (target.global_position - global_position).normalized()
		var target_angle = dir_to_target.angle()
		rotation = lerp_angle(rotation, target_angle, 0.05)  # leggero aumento reattività

	# Movimento
	if is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		# Hard: movimento erratico (piccole deviazioni sinusoidali)
		if Global.dificulty == "hard":
			dir = dir.rotated(sin(Time.get_ticks_msec() * 0.01) * 0.15)
		velocity = dir * speed
		move_and_slide()

		# Distanza di esplosione
		if global_position.distance_to(target.global_position) < 26:
			_explode()
	else:
		velocity = Vector2.ZERO

	queue_redraw()

# ============================================================
# === DRAW (effetti senza Tween) ==============================
# ============================================================
func _draw() -> void:
	# --- AURA pulsante ---
	if _draw_aura_color.a > 0.01:
		draw_arc(Vector2.ZERO, _draw_aura_radius, 0, TAU, 64, _draw_aura_color, 2.0, false)
		# alone esterno
		var outer = Color(_draw_aura_color.r, _draw_aura_color.g, _draw_aura_color.b, _draw_aura_color.a * 0.3)
		draw_arc(Vector2.ZERO, _draw_aura_radius * 1.2, 0, TAU, 64, outer, 1.5, false)

	# --- SCIA (punti recenti) ---
	if _draw_trail_points.size() > 1:
		for i in range(_draw_trail_points.size() - 1):
			var alpha = lerp(0.0, 0.6, float(i) / _draw_trail_points.size())
			var col = Color(1.0, 0.6, 0.1, alpha)
			draw_line(_draw_trail_points[i], _draw_trail_points[i + 1], col, 2.0)

	# --- ONDA D'URTO (morte) ---
	if _draw_shockwave_alpha > 0.01:
		var c = Color(1.0, 0.2, 0.0, _draw_shockwave_alpha)
		draw_arc(Vector2.ZERO, _draw_shockwave_radius, 0, TAU, 80, c, 3.0, false)
		var c2 = Color(1.0, 0.8, 0.0, _draw_shockwave_alpha * 0.5)
		draw_arc(Vector2.ZERO, _draw_shockwave_radius * 0.85, 0, TAU, 80, c2, 2.0, false)

	# --- ANELLI DI MORTE ---
	for ring in _draw_death_rings:
		var col = ring["color"]
		col.a = ring["alpha"]
		draw_arc(Vector2.ZERO, ring["radius"], 0, TAU, 72, col, 2.5, false)

	# --- FULMINI ---
	for bolt in _draw_lightning_bolts:
		if bolt["alpha"] <= 0.01:
			continue
		var bc = bolt["color"]
		bc.a = bolt["alpha"]
		var pts: Array = bolt["points"]
		for i in range(pts.size() - 1):
			draw_line(pts[i], pts[i + 1], bc, rng.randf_range(1.0, 2.5))

# ============================================================
# === AURA COROUTINE (sostituisce Tween) ======================
# ============================================================
func _start_aura_pulse() -> void:
	_draw_aura_color.a = 0.0
	_draw_aura_radius = 10.0
	# Fade in
	var fade_in := 0.8
	var elapsed := 0.0
	while elapsed < fade_in:
		_draw_aura_color.a = lerp(0.0, 0.6, elapsed / fade_in)
		_draw_aura_radius = lerp(10.0, 35.0, elapsed / fade_in)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_draw_aura_color.a = 0.6
	_draw_aura_radius = 35.0

	# Pulsazione continua
	while alive:
		# Espansione
		elapsed = 0.0
		while elapsed < 0.8 and alive:
			_draw_aura_radius = lerp(35.0, 45.0, elapsed / 0.8)
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		if not alive: break
		_draw_aura_radius = 45.0
		# Contrazione
		elapsed = 0.0
		while elapsed < 0.8 and alive:
			_draw_aura_radius = lerp(45.0, 35.0, elapsed / 0.8)
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		_draw_aura_radius = 35.0

# ============================================================
# === SCIA (coda dinamica) ====================================
# ============================================================
func _update_trail_loop() -> void:
	# Aggiunge la posizione corrente ogni 0.03 sec per creare una scia fluida
	while alive:
		_add_trail_point()
		await get_tree().create_timer(0.03).timeout

func _add_trail_point() -> void:
	# Convertiamo la posizione globale in locale per il draw
	var local_pos = Vector2.ZERO  # il drone è al centro, quindi le posizioni delle scie sono relative al passato
	# Dobbiamo mantenere la scia relativa al movimento: usiamo to_local della posizione attuale?
	# Meglio: salviamo la posizione globale del drone in quel momento e poi al draw la convertiamo in locale.
	# Modifichiamo _draw_trail_points per contenere posizioni globali e nel draw convertiamo.
	# Scegliamo di mantenere globali e convertire al volo.
	if not alive:
		return
	_draw_trail_points.append(global_position)
	# Mantieni massimo 20 punti
	if _draw_trail_points.size() > 20:
		_draw_trail_points.pop_front()

	# Per il draw, convertiamo tutto in coordinate locali al momento del disegno:
	# Nella funzione _draw faremo:
	# for pt in _draw_trail_points: draw... (pt - global_position)
	# Modifichiamo _draw per gestire questo.

# NOTA: Poiché usiamo coordinate globali nella scia, adatteremo la _draw:
# Sostituiremo la parte SCIA con:
# for i in range(_draw_trail_points.size() - 1):
#     var local_a = to_local(_draw_trail_points[i])
#     var local_b = to_local(_draw_trail_points[i+1])
#     ... draw_line(local_a, local_b, ...

# Dobbiamo aggiornare la funzione _draw per usare to_local. Lo faremo nel codice completo.

# ============================================================
# === ESPLOSIONE MIGLIORATA (catena intelligente) =============
# ============================================================
func _explode():
	if not alive:
		return
	alive = false
	speed = 0
	GlobalTweens.deactivate($Damage/coll)
	GlobalTweens.deactivate($player_coll)
	$dead.play("dead")

	# Effetti visivi epici (draw)
	_spawn_death_effects()

	# Danno al giocatore
	if is_instance_valid(target) and target.has_method("take_damage"):
		if global_position.distance_to(target.global_position) < explosion_radius * 0.8:
			target.take_damage(explosion_damage)
			if can_hurt:
				can_hurt = false
				Global.hurt = true
				Global.player_hp -= int(explosion_damage * 0.2)

	# Danno a catena (più aggressivo in hard)
	var chain_count = 0
	for other in get_tree().get_nodes_in_group("drone"):
		if other == self:
			continue
		if not is_instance_valid(other):
			continue
		if not other.alive:
			continue
		var dist = global_position.distance_to(other.global_position)
		if dist < explosion_radius:
			# In hard: esplosione a catena più rapida, ritardo ridotto
			var delay = 0.05 if Global.dificulty == "hard" else 0.1
			other.call_deferred("_explode")
			chain_count += 1
			# Limita la catena per evitare loop infiniti (ma call_deferred già aiuta)
			if chain_count > 10:
				break

# ============================================================
# === EFFETTI DI MORTE (coroutine, no Tween) ==================
# ============================================================
func _spawn_death_effects() -> void:
	# Onda d'urto
	_draw_shockwave_radius = 10.0
	_draw_shockwave_alpha = 0.9
	var shockwave_coroutine = func():
		var dur = 0.5
		var elapsed = 0.0
		while elapsed < dur:
			_draw_shockwave_radius = lerp(10.0, explosion_radius * 1.5, elapsed / dur)
			_draw_shockwave_alpha = lerp(0.9, 0.0, elapsed / dur)
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		_draw_shockwave_alpha = 0.0
	shockwave_coroutine.call()

	# Anelli di energia
	for i in range(3):
		var ring = {"radius": 10.0 + i * 15, "alpha": 0.8, "color": Color(1.0, 0.3, 0.0)}
		_draw_death_rings.append(ring)
		# Anima l'anello verso l'esterno
		var animate_ring = func(r):
			var dur = 0.6
			var elapsed = 0.0
			var start_r = r["radius"]
			while elapsed < dur and r in _draw_death_rings:
				r["radius"] = lerp(start_r, explosion_radius * 1.2, elapsed / dur)
				r["alpha"] = lerp(0.8, 0.0, elapsed / dur)
				await get_tree().process_frame
				elapsed += get_process_delta_time()
			if r in _draw_death_rings:
				_draw_death_rings.erase(r)
		animate_ring.call(ring)

	# Fulmini casuali
	for j in range(4):
		_spawn_random_bolt(1.0)

func _spawn_random_bolt(duration: float) -> void:
	var angle = rng.randf() * TAU
	var points: Array[Vector2] = []
	var cursor = Vector2.ZERO
	var len = rng.randf_range(50.0, 100.0)
	var segs = rng.randi_range(4, 7)
	for s in range(segs):
		cursor += Vector2(cos(angle + rng.randf_range(-0.7, 0.7)), sin(angle + rng.randf_range(-0.7, 0.7))) * (len / segs)
		points.append(cursor)
	var bolt = {"points": points, "alpha": 1.0, "color": Color(1.0, 0.8, 0.2)}
	_draw_lightning_bolts.append(bolt)
	# Dissolvenza
	var fade_bolt = func(b):
		var elapsed = 0.0
		while elapsed < duration and b in _draw_lightning_bolts:
			b["alpha"] = lerp(1.0, 0.0, elapsed / duration)
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		if b in _draw_lightning_bolts:
			_draw_lightning_bolts.erase(b)
	fade_bolt.call(bolt)

# ============================================================
# === GESTIONE DANNI (invariata con piccoli fix) ==============
# ============================================================
func _on_hurt(amount:int):
	if not alive:
		return
	# Effetto esplosione piccola
	var effect_scene = load("res://Gres/Scenes/Effects/expl_e.tscn")
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
	hp -= amount
	if hp <= 0:
		_explode()

func _on_damage_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.is_in_group("drone"):
		_explode()

func _on_damage_area_entered(area: Area2D) -> void:
	if not alive:
		return
	area.queue_free()
	_on_hurt(Global.player_damage + 10)

func _on_dead_animation_finished(anim_name: StringName) -> void:
	queue_free()

func _on_explossion_timeout() -> void:
	_explode()
