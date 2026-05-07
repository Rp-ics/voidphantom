## BossTemplate_Bruiser.gd
## ============================================================
## ARCHETIPO: Boss corpo a corpo — aggressivo, veloce, brutale.
## BOSS CREABILI: guerriero di fuoco, bestia meccanica, titano di pietra,
##                predatore, golem berserk, campione corrotto...
## ============================================================
## NODI RICHIESTI nella scena:
##   - AnimationPlayer        (nome: "AnimationPlayer")
##   - AnimationPlayer        (nome: "AnimFX")          ← opzionale
##   - Sprite2D               (nome: "Sprite2D")
##   - Timer                  (nome: "AttackTimer")
##   - Timer                  (nome: "ShieldRegenTimer") ← opzionale
##   - Area2D + CollisionShape per HurtBox  (gruppo: "hurt_box")
##   - Area2D + CollisionShape per ShieldArea ← opzionale
##   - Label                  (nome: "Sprite2D/ShieldHPL1") ← opzionale
##   - Label                  (nome: "Sprite2D/ShieldHPL2") ← opzionale
## ============================================================
## ANIMAZIONI ATTESE (crea solo quelle che usi, le altre vengono skippate):
##   MOVIMENTO:    "idle", "walk", "run"
##   ATTACCHI:     "charge_windup", "slam", "spin", "rage_roar"
##   TRANSIZIONI:  "transform_p2", "transform_p3"
##   DANNI:        "hit", "stagger"
##   MORTE:        "death"
## ============================================================

extends CharacterBody2D
class_name BossTemplate_Bruiser

# ============================================================
# === IDENTITÀ BOSS (personalizza per ogni boss) ==============
# ============================================================
@export_group("Boss Identity")
@export var boss_name: String = "Bruiser Boss"
## Chiave usata in Global per hp: Global[hp_key] e Global[hp_key + "_max"]
@export var hp_key: String = "bruiser_hp"
## Chiave missione per kill tracking
@export var mission_key_easy: String = "boss_killer_1"
@export var mission_key_medium: String = "boss_killer_2"
@export var mission_key_hard: String = "boss_killer_3"
## Arma leggendaria droppata alla morte
@export var legendary_weapon_drop: String = "BRUISER CORE"
## Scena da caricare dopo la morte
@export var death_scene_path: String = "res://Gres/Scenes/Story/boss_dead_scene.tscn"

# ============================================================
# === HP PER DIFFICOLTÀ =======================================
# ============================================================
@export_group("Health")
@export var hp_easy: int = 8000
@export var hp_medium: int = 13000
@export var hp_hard: int = 20000
@export var shield_hp_easy: int = 0       # 0 = nessuno scudo
@export var shield_hp_medium: int = 0
@export var shield_hp_hard: int = 0
@export var shield_regen_time: float = 8.0

# ============================================================
# === MOVIMENTO ===============================================
# ============================================================
@export_group("Movement")
@export var speed_easy: float = 200.0
@export var speed_medium: float = 280.0
@export var speed_hard: float = 370.0
## Il boss smette di inseguire quando è a questa distanza dal player
@export var stop_distance: float = 80.0
## Se true il boss si muove anche durante gli attacchi
@export var move_while_attacking: bool = false

# ============================================================
# === FASI ====================================================
# ============================================================
@export_group("Phases")
@export var use_phase_two: bool = true
@export var use_phase_three: bool = true
@export var phase_two_threshold: float = 0.6
@export var phase_three_threshold: float = 0.25
## Velocità nelle fasi successive (moltiplicatore sulla base)
@export var phase_two_speed_mult: float = 1.2
@export var phase_three_speed_mult: float = 1.5
## Aura colore per ogni fase (draw)
@export var aura_color_p1: Color = Color(0.8, 0.3, 0.1, 0.5)
@export var aura_color_p2: Color = Color(1.0, 0.2, 0.0, 0.6)
@export var aura_color_p3: Color = Color(1.0, 0.0, 0.0, 0.8)

# ============================================================
# === ATTACCHI ================================================
# ============================================================
@export_group("Attacks - Charge")
## Abilita il dash/carica verso il player
@export var use_charge: bool = true
@export var charge_probability: float = 0.008   # per frame in physics_process
@export var charge_speed_easy: float = 500.0
@export var charge_speed_medium: float = 650.0
@export var charge_speed_hard: float = 850.0
@export var charge_duration: float = 0.5
## Numero di dash per combo (easy/medium/hard)
@export var charge_count_easy: int = 1
@export var charge_count_medium: int = 2
@export var charge_count_hard: int = 3
@export var charge_windup_time: float = 0.7     # tempo di carica prima del dash
@export var explosion_scene: PackedScene         # esplosione sull'impatto

@export_group("Attacks - Slam")
## Slam AOE: si ferma, si alza, crasha giù con AOE
@export var use_slam: bool = true
@export var slam_probability: float = 0.005
@export var slam_radius_easy: float = 150.0
@export var slam_radius_medium: float = 200.0
@export var slam_radius_hard: float = 280.0
@export var slam_damage_easy: float = 25.0
@export var slam_damage_medium: float = 40.0
@export var slam_damage_hard: float = 65.0
@export var slam_windup_time: float = 1.0

@export_group("Attacks - Spin")
## Spin: il boss ruota su sé stesso e avanza, spazzando tutto
@export var use_spin: bool = false
@export var spin_probability: float = 0.003
@export var spin_duration: float = 3.0
@export var spin_speed_mult: float = 1.3
@export var spin_damage_per_frame: float = 2.0

@export_group("Attacks - Rage")
## Rage Roar: nella fase 3 il boss urla, guadagna velocità e immunità breve
@export var use_rage: bool = true
@export var rage_probability: float = 0.002
@export var rage_duration: float = 4.0
@export var rage_speed_mult: float = 2.0
@export var rage_invincible: bool = true

@export_group("Attacks - Summon")
@export var use_summon: bool = false
@export var minion_scene: PackedScene
@export var summon_probability: float = 0.003
@export var summon_count_easy: int = 2
@export var summon_count_medium: int = 4
@export var summon_count_hard: int = 6
@export var summon_radius: float = 220.0

# ============================================================
# === SCENE / NODI ============================================
# ============================================================
@export_group("Scenes & Nodes")
@export var bullet_scene: PackedScene           # opzionale: il bruiser può sparare
@export var use_shield: bool = false
@export var use_shield_label: bool = false

# ============================================================
# === DROPS ===================================================
# ============================================================
@export_group("Drops")
@export var gold_min: int = 150
@export var gold_max: int = 600
@export var shard_chance_easy: float = 0.10
@export var shard_chance_medium: float = 0.15
@export var shard_chance_hard: float = 0.20
@export var tablet_chance_easy: float = 0.50
@export var tablet_chance_medium: float = 0.70
@export var tablet_chance_hard: float = 0.90
@export var spin_gem_chance: float = 0.001     # 0.1%
@export var icon_chance_easy: float = 0.02
@export var icon_chance_medium: float = 0.05
@export var icon_chance_hard: float = 0.10

# ============================================================
# === RUNTIME (non toccare) ===================================
# ============================================================
var phase: int = 1
var attacking: bool = false
var can_move: bool = true
var is_raging: bool = false
var is_invincible: bool = false
var player: Node2D
var rng := RandomNumberGenerator.new()
var can_regen: bool = true
var _shield_hp: int = 0
var _max_hp: int = 0
var _speed: float = 0.0
var _base_speed: float = 0.0

# DRAW state
var _draw_aura_r: float = 80.0
var _draw_aura_color: Color = Color.TRANSPARENT
var _draw_rings: Array = []
var _draw_shockwave_r: float = 0.0
var _draw_shockwave_a: float = 0.0
var _draw_cracks: Array = []
var _draw_rage_time: float = 0.0
var _draw_slam_ring: float = 0.0
var _draw_slam_alpha: float = 0.0

# ============================================================
# === NODI ====================================================
# ============================================================
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

# ============================================================
# === READY ===================================================
# ============================================================
func _ready() -> void:
	match Global.dificulty:
		"easy":
			_max_hp = hp_easy
			_base_speed = speed_easy
			_shield_hp = shield_hp_easy
		"medium":
			_max_hp = hp_medium
			_base_speed = speed_medium
			_shield_hp = shield_hp_medium
		"hard":
			_max_hp = hp_hard
			_base_speed = speed_hard
			_shield_hp = shield_hp_hard

	_speed = _base_speed
	Global.set(hp_key + "_max", _max_hp)
	Global.set(hp_key, _max_hp)

	player = get_tree().get_first_node_in_group("player")
	_draw_aura_color = aura_color_p1
	_fx_aura_pulse()
	_play_anim("idle")

# ============================================================
# === PROCESS =================================================
# ============================================================
func _physics_process(delta: float) -> void:
	if phase == 3:
		_draw_rage_time += delta * (3.0 if is_raging else 1.5)

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
			var c = _draw_aura_color
			c.a *= (1.0 - i * 0.28)
			draw_arc(Vector2.ZERO, _draw_aura_r * (1.0 - i * 0.18), 0, TAU, 64, c, 2.5 - i * 0.5, false)

	# Shockwave
	if _draw_shockwave_a > 0.01:
		var sc = Color(1.0, 0.4, 0.1, _draw_shockwave_a)
		draw_arc(Vector2.ZERO, _draw_shockwave_r, 0, TAU, 80, sc, 5.0, false)

	# Rings
	for rd in _draw_rings:
		var c = rd["color"]; c.a = rd["alpha"]
		draw_arc(Vector2.ZERO, rd["radius"], 0, TAU, 64, c, 2.5, false)

	# Slam ring
	if _draw_slam_alpha > 0.01:
		var sc2 = Color(1.0, 0.5, 0.0, _draw_slam_alpha)
		draw_arc(Vector2.ZERO, _draw_slam_ring, 0, TAU, 80, sc2, 6.0, false)
		var sc3 = Color(1.0, 0.8, 0.2, _draw_slam_alpha * 0.3)
		draw_circle(Vector2.ZERO, _draw_slam_ring * 0.7, sc3)

	# Crepe
	for crack in _draw_cracks:
		var c = crack["color"]; c.a = crack["alpha"]
		draw_line(crack["from"], crack["to"], c, 2.0)

	# Rage: bordo rosso pulsante
	if is_raging:
		var p = abs(sin(_draw_rage_time)) * 0.9
		draw_arc(Vector2.ZERO, 100 + p * 25, 0, TAU, 64, Color(1, 0, 0, p * 0.8), 7.0, false)

# ============================================================
# === FASI ====================================================
# ============================================================
func _phase_one(delta: float) -> void:
	_move_toward_player()
	if use_charge and rng.randf() < charge_probability: _charge_attack()
	if use_slam and rng.randf() < slam_probability: _slam_attack()
	if use_summon and rng.randf() < summon_probability: _summon_minions()

func _phase_two(delta: float) -> void:
	_move_toward_player()
	if use_charge and rng.randf() < charge_probability * 1.5: _charge_attack()
	if use_slam and rng.randf() < slam_probability * 1.5: _slam_attack()
	if use_spin and rng.randf() < spin_probability: _spin_attack()
	if use_summon and rng.randf() < summon_probability * 1.3: _summon_minions()

func _phase_three(delta: float) -> void:
	_move_toward_player()
	if use_charge and rng.randf() < charge_probability * 2.0: _charge_attack()
	if use_slam and rng.randf() < slam_probability * 2.0: _slam_attack()
	if use_spin and rng.randf() < spin_probability * 1.5: _spin_attack()
	if use_rage and rng.randf() < rage_probability and not is_raging: _rage_roar()
	if use_summon and rng.randf() < summon_probability * 1.8: _summon_minions()

func _move_toward_player() -> void:
	if not can_move or (attacking and not move_while_attacking): return
	if not player: return
	var dist = global_position.distance_to(player.global_position)
	if dist > stop_distance:
		velocity = (player.global_position - global_position).normalized() * _speed
		_play_anim("walk")
	else:
		velocity = Vector2.ZERO
		_play_anim("idle")
	move_and_slide()

# ============================================================
# === TRANSIZIONI =============================================
# ============================================================
func _on_damage(amount: int) -> void:
	if is_invincible: return
	Global.set(hp_key, Global.get(hp_key) - amount)
	if Global.get(hp_key) <= 0: _die(); return

	var ratio = float(Global.get(hp_key)) / float(_max_hp)
	if use_phase_two and phase == 1 and ratio <= phase_two_threshold:
		_enter_phase(2)
	elif use_phase_three and phase == 2 and ratio <= phase_three_threshold:
		_enter_phase(3)

func _enter_phase(p: int) -> void:
	phase = p
	can_move = false
	attacking = false
	_draw_aura_color = aura_color_p2 if p == 2 else aura_color_p3
	_speed = _base_speed * (phase_two_speed_mult if p == 2 else phase_three_speed_mult)
	_fx_shockwave(_draw_aura_color, 400.0 + p * 80)
	_fx_cracks(10 + p * 4, _draw_aura_color)
	_play_anim("transform_p" + str(p))
	await get_tree().create_timer(1.2).timeout
	can_move = true

# ============================================================
# === ATTACCHI ================================================
# ============================================================
func _charge_attack() -> void:
	if attacking or not player: return
	attacking = true; can_move = false
	_play_anim("charge_windup")
	_fx_rings_contract(aura_color_p2, _scale(charge_windup_time))
	await get_tree().create_timer(_scale(charge_windup_time)).timeout

	var count = charge_count_easy if Global.dificulty == "easy" \
		else (charge_count_medium if Global.dificulty == "medium" else charge_count_hard)
	var spd = charge_speed_easy if Global.dificulty == "easy" \
		else (charge_speed_medium if Global.dificulty == "medium" else charge_speed_hard)

	for i in range(count):
		if not is_instance_valid(player): break
		var dir = (player.global_position - global_position).normalized()
		_perform_dash(dir, spd)
		await get_tree().create_timer(0.2).timeout

	await get_tree().create_timer(_scale(0.4)).timeout
	attacking = false; can_move = true

func _perform_dash(dir: Vector2, spd: float) -> void:
	# Ghost trail
	for g in range(3):
		var ghost = Sprite2D.new()
		ghost.texture = sprite.texture
		ghost.modulate = Color(_draw_aura_color.r, _draw_aura_color.g, _draw_aura_color.b, 0.45 - g * 0.1)
		ghost.scale = sprite.scale * (0.95 - g * 0.07)
		ghost.global_position = global_position
		get_parent().add_child(ghost)
		var tw = ghost.create_tween()
		tw.tween_property(ghost, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_EXPO)
		tw.tween_callback(ghost.queue_free)

	var t := 0.0
	while t < charge_duration:
		velocity = dir * spd
		move_and_slide()
		await get_tree().process_frame
		t += get_process_delta_time()
	velocity = Vector2.ZERO

	_fx_shockwave(aura_color_p2, 200.0)
	if explosion_scene:
		var e = explosion_scene.instantiate()
		get_parent().add_child(e)
		e.global_position = global_position

func _slam_attack() -> void:
	if attacking: return
	attacking = true; can_move = false
	_play_anim("slam")
	_fx_rings_contract(Color(1.0, 0.6, 0.0), _scale(slam_windup_time))
	await get_tree().create_timer(_scale(slam_windup_time)).timeout

	var radius = slam_radius_easy if Global.dificulty == "easy" \
		else (slam_radius_medium if Global.dificulty == "medium" else slam_radius_hard)
	var dmg = slam_damage_easy if Global.dificulty == "easy" \
		else (slam_damage_medium if Global.dificulty == "medium" else slam_damage_hard)

	# Slam visivo
	_draw_slam_ring = 20.0; _draw_slam_alpha = 1.0
	var tw_s = create_tween()
	tw_s.tween_property(self, "_draw_slam_ring", radius, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw_s.parallel().tween_property(self, "_draw_slam_alpha", 0.0, 0.4)

	if explosion_scene:
		var e = explosion_scene.instantiate()
		get_parent().add_child(e); e.global_position = global_position
		e.scale = Vector2.ONE * (radius / 80.0)

	# Danno al player se in range
	if player and global_position.distance_to(player.global_position) < radius:
		Global.hurt = true
		Global.player_hp -= dmg

	await get_tree().create_timer(0.5).timeout
	attacking = false; can_move = true

func _spin_attack() -> void:
	if attacking: return
	attacking = true
	_play_anim("spin")
	var elapsed := 0.0
	while elapsed < spin_duration:
		if player:
			velocity = (player.global_position - global_position).normalized() * _speed * spin_speed_mult
		sprite.rotation += deg_to_rad(15)
		if player and global_position.distance_to(player.global_position) < 90:
			Global.hurt = true
			Global.player_hp -= spin_damage_per_frame
		move_and_slide()
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	sprite.rotation = 0.0
	attacking = false

func _rage_roar() -> void:
	if is_raging: return
	is_raging = true
	if rage_invincible: is_invincible = true
	_play_anim("rage_roar")
	_fx_shockwave(Color(1.0, 0.0, 0.0), 600.0)
	_fx_cracks(20, Color(1.0, 0.0, 0.0))
	var old_speed = _speed
	_speed *= rage_speed_mult
	await get_tree().create_timer(rage_duration).timeout
	_speed = old_speed
	is_invincible = false
	is_raging = false

func _summon_minions() -> void:
	if not minion_scene: return
	var count = summon_count_easy if Global.dificulty == "easy" \
		else (summon_count_medium if Global.dificulty == "medium" else summon_count_hard)
	for i in range(count):
		var m = minion_scene.instantiate()
		get_parent().add_child(m)
		var angle = (TAU / count) * i
		m.global_position = global_position + Vector2(cos(angle), sin(angle)) * summon_radius
	_fx_shockwave(Color(0.8, 0.0, 1.0), 250.0)

# ============================================================
# === FX HELPERS ==============================================
# ============================================================
func _fx_aura_pulse() -> void:
	var tw = create_tween().set_loops()
	tw.tween_property(self, "_draw_aura_r", 100.0, 1.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "_draw_aura_r", 80.0, 1.0).set_trans(Tween.TRANS_SINE)

func _fx_shockwave(color: Color, max_r: float) -> void:
	_draw_shockwave_r = 10.0; _draw_shockwave_a = 0.9
	var tw = create_tween()
	tw.tween_property(self, "_draw_shockwave_r", max_r, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "_draw_shockwave_a", 0.0, 0.5)

func _fx_rings_contract(color: Color, duration: float) -> void:
	for i in range(4):
		var ring = {"radius": 200.0 - i * 30, "alpha": 0.0, "color": color}
		_draw_rings.append(ring)
		var tw = create_tween().set_delay(i * 0.08)
		tw.tween_property(ring, "alpha", 0.8, 0.1)
		tw.tween_property(ring, "radius", 20.0, duration * 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(ring, "alpha", 0.0, duration * 0.85)
		tw.tween_callback(func(): _draw_rings.erase(ring))

func _fx_cracks(count: int, color: Color) -> void:
	for i in range(count):
		var angle = rng.randf() * TAU
		var l = rng.randf_range(40.0, 100.0)
		var f = Vector2(cos(angle), sin(angle)) * 40.0
		var t2 = f + Vector2(cos(angle + rng.randf_range(-0.5, 0.5)), sin(angle + rng.randf_range(-0.5, 0.5))) * l
		var crack = {"from": f, "to": t2, "alpha": 1.0, "color": color}
		_draw_cracks.append(crack)
		var tw = create_tween()
		tw.tween_method(func(v): crack["alpha"] = v, 1.0, 0.0, 4.0)
		tw.tween_callback(func(): _draw_cracks.erase(crack))

# ============================================================
# === UTILITY =================================================
# ============================================================
func _scale(t: float) -> float:
	match Global.dificulty:
		"easy":   return t * 1.3
		"medium": return t
		"hard":   return t * 0.6
		_:        return t

func _play_anim(name: String) -> void:
	if anim and anim.has_animation(name):
		if anim.current_animation != name:
			anim.play(name)

# ============================================================
# === HIT / DAMAGE ============================================
# ============================================================
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		var dmg := _get_bullet_damage(area)
		_on_damage(int(dmg))
		_spawn_hit_fx(dmg)
		area.queue_free()
		_spawn_damage_popup(int(dmg))

func _get_bullet_damage(area: Area2D) -> float:
	if area.has_meta("damage"): return area.get_meta("damage")
	elif GlobalWeapons.current_weapon.has("damage"): return GlobalWeapons.current_weapon["damage"]
	return 10.0 * Global.player_damage

func _spawn_hit_fx(amount: float) -> void:
	if explosion_scene:
		var e = explosion_scene.instantiate()
		get_parent().add_child(e)
		e.global_position = global_position + Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))
		e.scale = Vector2.ONE * clamp(amount / 80.0, 0.3, 1.2)
	_fx_shockwave(_draw_aura_color, 100.0)

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

	var shard_ch = shard_chance_easy if diff == "easy" else (shard_chance_medium if diff == "medium" else shard_chance_hard)
	if randf() < shard_ch: _drop_shard()
	var tab_ch = tablet_chance_easy if diff == "easy" else (tablet_chance_medium if diff == "medium" else tablet_chance_hard)
	if randf() < tab_ch: GlobalStats.tablet += 1
	if randf() < spin_gem_chance: Global.spin_gem += 1
	if randf() < icon_chance_easy: Global.set(hp_key + "_icon_easy", true)
	if diff != "easy" and randf() < icon_chance_medium: Global.set(hp_key + "_icon_medium", true)
	if diff == "hard" and randf() < icon_chance_hard: Global.set(hp_key + "_icon_hard", true)

	Global.register_found_weapon(legendary_weapon_drop, "legendary")
	get_tree().change_scene_to_file(death_scene_path)

func _drop_shard() -> void:
	match ["ice","magma","light","void"].pick_random():
		"ice":   GlobalStats.ice_shard += 1
		"magma": GlobalStats.magma_shard += 1
		"light": GlobalStats.light_shard += 1
		"void":  GlobalStats.void_shard += 1
