## BossTemplate_Summoner.gd
## ============================================================
## ARCHETIPO: Boss Evocatore — non combatte direttamente,
## evoca ondate di minion, barriere viventi, si sacrifica,
## si rigenera con il sangue dei servi.
## BOSS CREABILI: strega necromante, dio corrupto, regina alveare,
##                arcimago, entità dimensionale, signore dei demoni...
## ============================================================
## NODI RICHIESTI:
##   - AnimationPlayer        (nome: "AnimationPlayer")
##   - AnimationPlayer        (nome: "AnimFX")          ← opzionale
##   - Sprite2D               (nome: "Sprite2D")
##   - Timer                  (nome: "SummonTimer")     ← auto-configurato
##   - Timer                  (nome: "ShieldRegenTimer")← opzionale
##   - Area2D HurtBox         (gruppo: "hurt_box")
## ============================================================
## ANIMAZIONI ATTESE:
##   IDLE:         "idle", "float", "chant"
##   EVOCAZIONE:   "summon_wave", "summon_elite", "ritual"
##   SCUDO:        "barrier_up", "barrier_down"
##   ATTACCHI:     "curse_cast", "soul_drain", "void_beam"
##   TRANSIZIONI:  "transform_p2", "transform_p3"
##   MORTE:        "death", "resurrection"  ← se usa resurrezione
## ============================================================

extends CharacterBody2D
class_name BossTemplate_Summoner

# ============================================================
# === IDENTITÀ ================================================
# ============================================================
@export_group("Boss Identity")
@export var boss_name: String = "Summoner Boss"
@export var hp_key: String = "summoner_hp"
@export var mission_key_easy: String = "boss_killer_1"
@export var mission_key_medium: String = "boss_killer_2"
@export var mission_key_hard: String = "boss_killer_3"
@export var legendary_weapon_drop: String = "SUMMONER CORE"
@export var death_scene_path: String = "res://Gres/Scenes/Story/boss_dead_scene.tscn"
@export var can_change_scene: bool = false
@export var rotation_speed_deg: float = 180.0

# ============================================================
# === HP ======================================================
# ============================================================
@export_group("Health")
@export var hp_easy: int = 15500
@export var hp_medium: int = 35000
@export var hp_hard: int = 65000
## Il summoner si può resuscitare una volta per partita (fase 3)
@export var use_resurrection: bool = false
@export var resurrection_hp_percent: float = 0.3   # torna con il 30% degli HP

# ============================================================
# === MOVIMENTO ===============================================
# ============================================================
@export_group("Movement")
## Il summoner di solito levita lentamente o rimane fermo
@export var hover_speed: float = 60.0
@export var hover_radius: float = 200.0    # raggio orbita attorno al centro arena
@export var use_orbital_movement: bool = true  # orbita invece di inseguire
@export var orbit_speed_deg: float = 20.0       # gradi/secondo

# ============================================================
# === FASI ====================================================
# ============================================================
@export_group("Phases")
@export var use_phase_two: bool = true
@export var use_phase_three: bool = true
@export var phase_two_threshold: float = 0.6
@export var phase_three_threshold: float = 0.25
@export var aura_color_p1: Color = Color(0.5, 0.0, 0.8, 0.5)
@export var aura_color_p2: Color = Color(0.8, 0.0, 0.5, 0.65)
@export var aura_color_p3: Color = Color(1.0, 0.0, 0.2, 0.8)

# ============================================================
# === EVOCAZIONE MINION =======================================
# ============================================================
@export_group("Summoning - Basic Minions")
@export var minion_scene: PackedScene
@export var summon_interval_easy: float = 8.0
@export var summon_interval_medium: float = 5.5
@export var summon_interval_hard: float = 3.5
@export var minion_count_easy: int = 3
@export var minion_count_medium: int = 5
@export var minion_count_hard: int = 8
@export var minion_spawn_radius: float = 250.0
## Se true, il boss è invincibile mentre evoca
@export var invincible_while_summoning: bool = true

@export_group("Summoning - Elite Minions")
@export var elite_minion_scene: PackedScene       # minion più forte, opzionale
@export var use_elite_summon: bool = false
@export var elite_summon_phase: int = 2           # da quale fase usa gli elite
@export var elite_count_easy: int = 1
@export var elite_count_medium: int = 2
@export var elite_count_hard: int = 3

@export_group("Summoning - Barrier")
## Barriera vivente: minion che circondano il boss rendendolo invincibile
@export var use_living_barrier: bool = true
@export var barrier_minion_scene: PackedScene
@export var barrier_count: int = 6
@export var barrier_radius: float = 120.0
## Il boss diventa invincibile finché ci sono minion nella barriera
@export var barrier_invincibility: bool = true

# ============================================================
# === ATTACCHI MAGICI =========================================
# ============================================================
@export_group("Attacks - Curse")
## Maledizione: rallenta / avvelena il player
@export var use_curse: bool = true
@export var curse_probability: float = 0.006
@export var curse_duration: float = 4.0
@export var curse_damage_per_second: float = 8.0
@export var bullet_scene: PackedScene               # proiettile maledizione

@export_group("Attacks - Soul Drain")
## Soul Drain: ruba HP al player e li trasferisce al boss
@export var use_soul_drain: bool = true
@export var soul_drain_probability: float = 0.003
@export var soul_drain_range: float = 350.0
@export var soul_drain_duration: float = 3.0
@export var soul_drain_dps: float = 12.0          # danno/sec al player
@export var soul_drain_heal_ratio: float = 0.5    # % del danno trasformata in heal

@export_group("Attacks - Void Beam")
## Raggio del vuoto: laser lento che ruota
@export var use_void_beam: bool = false
@export var laser_scene: PackedScene
@export var void_beam_probability: float = 0.004
@export var void_beam_count: int = 2

@export_group("Attacks - Ritual")
## Rituale: il boss si ferma, canta, poi esplode in danni AOE
@export var use_ritual: bool = false
@export var ritual_probability: float = 0.002
@export var ritual_windup: float = 3.5
@export var ritual_damage_easy: float = 40.0
@export var ritual_damage_medium: float = 70.0
@export var ritual_damage_hard: float = 110.0
@export var ritual_radius: float = 400.0
@export var explosion_scene: PackedScene

# ============================================================
# === DROPS ===================================================
# ============================================================
@export_group("Drops")
@export var gold_min: int = 200
@export var gold_max: int = 700
@export var shard_chance_easy: float = 0.12
@export var shard_chance_medium: float = 0.18
@export var shard_chance_hard: float = 0.25
@export var tablet_chance_easy: float = 0.55
@export var tablet_chance_medium: float = 0.75
@export var tablet_chance_hard: float = 0.92
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
var player: Node2D
var rng := RandomNumberGenerator.new()
var _max_hp: int = 0
var _current_hp = _max_hp
var _orbit_angle: float = 0.0
var _orbit_center: Vector2 = Vector2.ZERO
var _barrier_minions: Array = []
var _resurrection_used: bool = false
var _cursed: bool = false
var _draining: bool = false

# Draw state
var _draw_aura_r: float = 90.0
var _draw_aura_color: Color = Color.TRANSPARENT
var _draw_rings: Array = []
var _draw_shockwave_r: float = 0.0
var _draw_shockwave_a: float = 0.0
var _draw_cracks: Array = []
var _draw_runes: Array = []     # cerchio di rune attorno al boss
var _draw_drain_line: bool = false
var _draw_ritual_charge: float = 0.0

# ============================================================
# === NODI ====================================================
# ============================================================
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var summon_timer: Timer = $SummonTimer

# ============================================================
# === READY ===================================================
# ============================================================
func _ready() -> void:
	if Global.wave >= 5 and Global.wave <= 10: Global.dificulty = "easy"
	elif Global.wave >= 15 and Global.wave <= 20: Global.dificulty = "medium"
	else: Global.dificulty = "hard"
	
	match Global.dificulty:
		"easy":   _max_hp = hp_easy
		"medium": _max_hp = hp_medium
		"hard":   _max_hp = hp_hard
	_current_hp = _max_hp
	
	player = get_tree().get_first_node_in_group("player")
	_orbit_center = global_position
	_draw_aura_color = aura_color_p1

	# Timer evocazione
	var interval = summon_interval_easy if Global.dificulty == "easy" \
		else (summon_interval_medium if Global.dificulty == "medium" else summon_interval_hard)
	summon_timer.wait_time = interval
	summon_timer.start()
	summon_timer.timeout.connect(_on_summon_timer_timeout)

	_fx_aura_pulse()
	_fx_spawn_runes(6, aura_color_p1)
	_play_anim("idle")

	if use_living_barrier:
		_spawn_living_barrier()

# ============================================================
# === PROCESS =================================================
# ============================================================
func _physics_process(delta: float) -> void:
	# Usa la variabile 'player' già esistente
	if player:
		var target_angle = (player.global_position - $Sprite2D.global_position).angle()
		$Sprite2D.rotation = move_toward(
			$Sprite2D.rotation,
			target_angle,
			deg_to_rad(rotation_speed_deg) * delta
		)
	
	_check_barrier()
	
	_check_barrier()

	match phase:
		1: _phase_one(delta)
		2: _phase_two(delta)
		3: _phase_three(delta)

	queue_redraw()

# ============================================================
# === DRAW ====================================================
# ============================================================
func _draw() -> void:
	# Aura
	if _draw_aura_color.a > 0.01:
		for i in range(3):
			var c = _draw_aura_color; c.a *= (1.0 - i * 0.28)
			draw_arc(Vector2.ZERO, _draw_aura_r * (1.0 - i * 0.2), 0, TAU, 64, c, 2.5, false)

	# Shockwave
	if _draw_shockwave_a > 0.01:
		draw_arc(Vector2.ZERO, _draw_shockwave_r, 0, TAU, 80, Color(0.8, 0.0, 1.0, _draw_shockwave_a), 5.0, false)

	# Rings
	for rd in _draw_rings:
		var c = rd["color"]; c.a = rd["alpha"]
		draw_arc(Vector2.ZERO, rd["radius"], 0, TAU, 64, c, 2.5, false)

	# Rune attorno al boss
	for rune in _draw_runes:
		var rc = rune["color"]; rc.a = rune["alpha"]
		draw_circle(rune["pos"], rune["size"], rc)

	# Soul drain: linea verso il player
	if _draw_drain_line and player:
		var lp = to_local(player.global_position)
		var dc = Color(0.8, 0.0, 0.3, 0.7)
		for i in range(3):
			var offset = Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8))
			draw_line(Vector2.ZERO, lp + offset, dc, 2.0 - i * 0.5)

	# Ritual charge circle
	if _draw_ritual_charge > 0.01:
		var rc2 = Color(1.0, 0.2, 0.8, _draw_ritual_charge)
		draw_arc(Vector2.ZERO, ritual_radius, 0, TAU * _draw_ritual_charge, 80, rc2, 6.0, false)

	# Crepe
	for crack in _draw_cracks:
		var c = crack["color"]; c.a = crack["alpha"]
		draw_line(crack["from"], crack["to"], c, 1.5)

	# Invincibilità: scudo esagonale
	if is_invincible:
		var hex_pts: PackedVector2Array = PackedVector2Array()
		for i in range(6):
			hex_pts.append(Vector2(cos(TAU / 6 * i), sin(TAU / 6 * i)) * (_draw_aura_r + 20))
		hex_pts.append(hex_pts[0])
		for i in range(hex_pts.size() - 1):
			draw_line(hex_pts[i], hex_pts[i+1], Color(0.5, 0.0, 1.0, 0.9), 3.0)

# ============================================================
# === FASI ====================================================
# ============================================================
func _phase_one(delta: float) -> void:
	_orbital_move(delta)
	if use_curse and rng.randf() < curse_probability: _cast_curse()
	if use_soul_drain and rng.randf() < soul_drain_probability: _cast_soul_drain()
	if use_void_beam and rng.randf() < void_beam_probability: _spawn_void_beam()

func _phase_two(delta: float) -> void:
	_orbital_move(delta)
	if use_curse and rng.randf() < curse_probability * 1.5: _cast_curse()
	if use_soul_drain and rng.randf() < soul_drain_probability * 1.5: _cast_soul_drain()
	if use_void_beam and rng.randf() < void_beam_probability * 1.5: _spawn_void_beam()
	if use_ritual and rng.randf() < ritual_probability: _cast_ritual()
	if use_elite_summon and elite_minion_scene and rng.randf() < 0.003: _summon_elites()

func _phase_three(delta: float) -> void:
	_orbital_move(delta)
	if use_curse and rng.randf() < curse_probability * 2.0: _cast_curse()
	if use_soul_drain and rng.randf() < soul_drain_probability * 2.0: _cast_soul_drain()
	if use_void_beam and rng.randf() < void_beam_probability * 2.0: _spawn_void_beam()
	if use_ritual and rng.randf() < ritual_probability * 1.5: _cast_ritual()
	if use_elite_summon and elite_minion_scene and rng.randf() < 0.005: _summon_elites()

func _orbital_move(delta: float) -> void:
	if not use_orbital_movement or not can_move: return
	_orbit_angle += deg_to_rad(orbit_speed_deg) * delta
	global_position = _orbit_center + Vector2(cos(_orbit_angle), sin(_orbit_angle)) * hover_radius

# ============================================================
# === TRANSIZIONI =============================================
# ============================================================
func _on_damage(amount: int) -> void:
	return


func _enter_phase(p: int) -> void:
	phase = p
	can_move = false
	attacking = false
	_draw_aura_color = aura_color_p2 if p == 2 else aura_color_p3
	orbit_speed_deg *= 1.4
	_fx_shockwave(aura_color_p2 if p == 2 else aura_color_p3, 500.0)
	_fx_cracks(12, _draw_aura_color)
	_fx_spawn_runes(8 + p * 2, _draw_aura_color)

	if use_living_barrier: _spawn_living_barrier()

	# Timer evocazione più veloce
	var interval = summon_interval_easy if Global.dificulty == "easy" \
		else (summon_interval_medium if Global.dificulty == "medium" else summon_interval_hard)
	summon_timer.wait_time = interval / p
	summon_timer.start()

	_play_anim("transform_p" + str(p))
	await get_tree().create_timer(1.5).timeout
	can_move = true

func _do_resurrection() -> void:
	is_invincible = true
	can_move = false
	_play_anim("resurrection")
	_fx_shockwave(Color(1.0, 0.0, 0.0), 800.0)
	_fx_cracks(25, Color(1.0, 0.0, 0.0))
	await get_tree().create_timer(2.0).timeout
	_spawn_living_barrier()
	await get_tree().create_timer(0.5).timeout
	is_invincible = false
	can_move = true

# ============================================================
# === TIMER EVOCAZIONE ========================================
# ============================================================
func _on_summon_timer_timeout() -> void:
	if not minion_scene: return
	var count = minion_count_easy if Global.dificulty == "easy" \
		else (minion_count_medium if Global.dificulty == "medium" else minion_count_hard)

	if invincible_while_summoning: is_invincible = true
	_play_anim("summon_wave")
	_fx_shockwave(_draw_aura_color, 300.0)

	for i in range(count):
		var m = minion_scene.instantiate()
		get_parent().add_child(m)
		var angle = (TAU / count) * i + rng.randf_range(-0.3, 0.3)
		m.global_position = global_position + Vector2(cos(angle), sin(angle)) * minion_spawn_radius

	await get_tree().create_timer(0.8).timeout
	if invincible_while_summoning: is_invincible = false

# ============================================================
# === BARRIERA VIVENTE ========================================
# ============================================================
func _spawn_living_barrier() -> void:
	if not barrier_minion_scene: return
	# Rimuovi vecchi
	for m in _barrier_minions:
		if is_instance_valid(m): m.queue_free()
	_barrier_minions.clear()

	for i in range(barrier_count):
		var m = barrier_minion_scene.instantiate()
		var angle = (TAU / barrier_count) * i
		# Imposta la posizione prima di aggiungerlo alla scena
		m.global_position = global_position + Vector2(cos(angle), sin(angle)) * barrier_radius
		# Marca come barriera (se supportato)
		if m.has_meta("is_barrier"):
			m.set_meta("is_barrier", true)
		# Aggiungi il minion alla lista (anche se non ancora nella scena)
		_barrier_minions.append(m)
		# Aggiungi in modo differito per evitare il blocco
		get_parent().add_child.call_deferred(m)
	
func _check_barrier() -> void:
	if not use_living_barrier or not barrier_invincibility: return
	_barrier_minions = _barrier_minions.filter(func(m): return is_instance_valid(m))
	is_invincible = _barrier_minions.size() > 0

func _summon_elites() -> void:
	var count = elite_count_easy if Global.dificulty == "easy" \
		else (elite_count_medium if Global.dificulty == "medium" else elite_count_hard)
	_play_anim("summon_elite")
	_fx_shockwave(Color(1.0, 0.0, 0.5), 350.0)
	for i in range(count):
		var e_m = elite_minion_scene.instantiate()
		get_parent().add_child(e_m)
		var angle = rng.randf() * TAU
		e_m.global_position = global_position + Vector2(cos(angle), sin(angle)) * (minion_spawn_radius * 0.6)

# ============================================================
# === ATTACCHI ================================================
# ============================================================
func _cast_curse() -> void:
	if attacking or not player or not bullet_scene: return
	attacking = true
	_play_anim("curse_cast")
	# Spara 5 proiettili a ventaglio verso il player
	var base_dir = (player.global_position - global_position).normalized()
	for i in range(5):
		var b = bullet_scene.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position
		b.direction = base_dir.rotated(deg_to_rad(-20 + i * 10))
		b.speed = 200
		if b.has_meta("is_curse"): b.set_meta("is_curse", true)
	await get_tree().create_timer(0.5).timeout
	attacking = false

func _cast_soul_drain() -> void:
	if _draining or not player: return
	if global_position.distance_to(player.global_position) > soul_drain_range: return
	_draining = true
	_draw_drain_line = true
	_play_anim("soul_drain")

	var elapsed = 0.0
	while elapsed < soul_drain_duration:
		if not is_instance_valid(player): break
		var dmg = soul_drain_dps * get_process_delta_time()
		Global.player_hp -= dmg
		Global.hurt = true
		# Heals il boss
		var healed = int(dmg * soul_drain_heal_ratio)
		var hp_now = _current_hp
		_current_hp += healed
		await get_tree().process_frame
		elapsed += get_process_delta_time()

	_draw_drain_line = false
	_draining = false

func _spawn_void_beam() -> void:
	if not laser_scene: return
	var count = void_beam_count if phase >= 2 else 1
	for i in range(count):
		var l = laser_scene.instantiate()
		get_parent().add_child(l)
		l.global_position = global_position
		l.rotation_speed = rng.randf_range(-1.0, 1.0)

func _cast_ritual() -> void:
	if attacking: return
	attacking = true; can_move = false
	_play_anim("ritual")

	# Carica progressiva via draw
	var elapsed = 0.0
	while elapsed < ritual_windup:
		_draw_ritual_charge = elapsed / ritual_windup
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_draw_ritual_charge = 0.0

	var dmg = ritual_damage_easy if Global.dificulty == "easy" \
		else (ritual_damage_medium if Global.dificulty == "medium" else ritual_damage_hard)
	if player and global_position.distance_to(player.global_position) < ritual_radius:
		Global.player_hp -= dmg
		Global.hurt = true

	_fx_shockwave(aura_color_p3, ritual_radius)
	if explosion_scene:
		var e = explosion_scene.instantiate()
		get_parent().add_child(e)
		e.global_position = global_position
		e.scale = Vector2.ONE * (ritual_radius / 80.0)
		e.modulate = aura_color_p3

	await get_tree().create_timer(0.5).timeout
	attacking = false; can_move = true

# ============================================================
# === FX HELPERS ==============================================
# ============================================================
func _fx_aura_pulse() -> void:
	var tw = create_tween().set_loops()
	tw.tween_property(self, "_draw_aura_r", 105.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "_draw_aura_r", 85.0, 1.2).set_trans(Tween.TRANS_SINE)

func _fx_shockwave(color: Color, max_r: float) -> void:
	_draw_shockwave_r = 10.0; _draw_shockwave_a = 0.9
	var tw = create_tween()
	tw.tween_property(self, "_draw_shockwave_r", max_r, 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "_draw_shockwave_a", 0.0, 0.55)

func _fx_cracks(count: int, color: Color) -> void:
	for i in range(count):
		var angle = rng.randf() * TAU
		var l = rng.randf_range(35.0, 95.0)
		var f = Vector2(cos(angle), sin(angle)) * 45.0
		var t2 = f + Vector2(cos(angle + rng.randf_range(-0.6, 0.6)), sin(angle + rng.randf_range(-0.6, 0.6))) * l
		var crack = {"from": f, "to": t2, "alpha": 1.0, "color": color}
		_draw_cracks.append(crack)
		var tw = create_tween()
		tw.tween_method(func(v): crack["alpha"] = v, 1.0, 0.0, 3.5)
		tw.tween_callback(func(): _draw_cracks.erase(crack))

func _fx_spawn_runes(count: int, color: Color) -> void:
	for rd in _draw_runes: _draw_runes.erase(rd)
	_draw_runes.clear()
	for i in range(count):
		var angle = (TAU / count) * i
		var rune = {"pos": Vector2(cos(angle), sin(angle)) * (_draw_aura_r + 30),
					"size": 6.0, "alpha": 0.8, "color": color}
		_draw_runes.append(rune)
	# Rotazione rune continua
	var tw = create_tween().set_loops()
	tw.tween_method(func(a):
		for j in range(_draw_runes.size()):
			var angle = (TAU / _draw_runes.size()) * j + a
			_draw_runes[j]["pos"] = Vector2(cos(angle), sin(angle)) * (_draw_aura_r + 30)
		, 0.0, TAU, 4.0)

# ============================================================
# === UTILITY =================================================
# ============================================================
func _scale(t: float) -> float:
	match Global.dificulty:
		"easy": return t * 1.3
		"medium": return t
		"hard": return t * 0.6
		_: return t

func _play_anim(name: String) -> void:
	if anim and anim.has_animation(name) and anim.current_animation != name:
		anim.play(name)

# ============================================================
# === HIT =====================================================
# ============================================================
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if not area.is_in_group("p_bullet"):
		area.queue_free()
		return
	if is_invincible:
		area.queue_free()
		return
	var dmg := _get_bullet_damage(area)
	
	# Applica danno
	_current_hp -= dmg
	print(_current_hp)
	
	# Effetti visivi
	GlobalTweens.glitch_flash($Sprite2D)
	area.queue_free()
	_spawn_damage_popup(int(dmg))
	
	# Gestione morte
	if _current_hp <= 0:
		# Resurrezione (solo fase 3)
		if use_resurrection and not _resurrection_used and phase == 3:
			_resurrection_used = true
			_current_hp = int(_max_hp * resurrection_hp_percent)  # CORRETTO: assegnazione, non sottrazione
			_do_resurrection()
			return
		
		_die()
		return
	
	# Gestione fasi (solo se vivo)
	var ratio := float(_current_hp) / float(_max_hp)
	
	if use_phase_two and phase == 1 and ratio <= phase_two_threshold:
		_enter_phase(2)
	elif use_phase_three and phase == 2 and ratio <= phase_three_threshold:
		_enter_phase(3)

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
# === MORTE ===================================================
# ============================================================
func _die() -> void:
	if has_node("HurtBox"):
		$HurtBox.set_deferred("monitoring", false)
		$HurtBox.set_deferred("monitorable", false)
	call_deferred("_death_cleanup")

func _death_cleanup() -> void:
	GlobalStats.kill_boss_total += 1
	Global.boss_killed = true
	GlobalStats.gold += randi_range(gold_min, gold_max)
	var diff = Global.dificulty
	Global.update_mission_progress(
		mission_key_easy if diff == "easy" else (mission_key_medium if diff == "medium" else mission_key_hard), 1)
	if randf() < (shard_chance_easy if diff == "easy" else (shard_chance_medium if diff == "medium" else shard_chance_hard)):
		_drop_shard()
	if randf() < (tablet_chance_easy if diff == "easy" else (tablet_chance_medium if diff == "medium" else tablet_chance_hard)):
		GlobalStats.tablet += 1
	if randf() < spin_gem_chance: Global.spin_gem += 1
	if Global.dificulty == "hard":  Global.register_found_weapon(legendary_weapon_drop, "legendary")
	if can_change_scene: get_tree().change_scene_to_file(death_scene_path)
	else: $Sprite2D/loop.play("death")
	
func _drop_shard() -> void:
	match ["ice","magma","light","void"].pick_random():
		"ice":   GlobalStats.ice_shard += 1
		"magma": GlobalStats.magma_shard += 1
		"light": GlobalStats.light_shard += 1
		"void":  GlobalStats.void_shard += 1


func _on_shield_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		GlobalTweens.explode_and_free(area)


func _on_loop_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death": queue_free()
