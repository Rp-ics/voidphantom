extends Area2D

# =======================
# CONFIG
# =======================
@export var can_random: bool = true
@export var rarity: String = "common"
@export var hp: int = 5

var maxhp: int
var opened: bool = false

@export var float_range: float = 800.0
@export var float_speed: float = 10.0

var tween: Tween
var start_position: Vector2

# --- Draw / VFX state ---
var _hit_flash: float = 0.0          # 0..1, decade ogni frame
var _particles: Array = []           # array di dict per particelle custom
var _glow_pulse: float = 0.0         # fase oscillazione glow
var _shake_offset: Vector2 = Vector2.ZERO
var _shake_timer: float = 0.0

# Colori per rarità
const RARITY_COLORS := {
	"common":  Color(0.6, 0.6, 0.6),
	"rare":    Color(0.2, 0.5, 1.0),
	"epic":    Color(0.7, 0.1, 1.0),
}

const RARITY_GLOW := {
	"common":  Color(0.8, 0.8, 0.8, 0.15),
	"rare":    Color(0.2, 0.6, 1.0, 0.25),
	"epic":    Color(0.9, 0.1, 1.0, 0.35),
}

var rarities := ["epic", "rare", "common"]
var rarity_chances := {
	"epic":   2,
	"rare":   10,
	"common": 88,
}

signal chest_opened(weapon_name: String, rarity: String)

# =======================
# READY
# =======================
func _ready() -> void:
	start_position = position
	maxhp = hp

	if GlobalStats.critical_chest and randi() % 100 < 50:
		hp = 1
		maxhp = 1

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	_start_floating()

	if can_random:
		rarity = _get_random_rarity()

	match rarity:
		"common":
			$Body.texture = load("res://Gres/Assets/UI/sprites/box_2.png")
			$Hat.texture  = load("res://Gres/Assets/UI/sprites/box_cover_2.png")
		"rare":
			$Body.texture = load("res://Gres/Assets/UI/sprites/box_4.png")
			$Hat.texture  = load("res://Gres/Assets/UI/sprites/box_cover_4.png")
		"epic":
			$Body.texture = load("res://Gres/Assets/UI/sprites/box_3.png")
			$Hat.texture  = load("res://Gres/Assets/UI/sprites/box_cover_3.png")

	$percent.max_value = maxhp
	$percent.value = 0

	# Spawna subito qualche particella ambient per le rarità superiori
	if rarity in ["rare", "epic"]:
		_spawn_ambient_particles()

# =======================
# PROCESS — aggiorna VFX
# =======================
func _process(delta: float) -> void:
	_glow_pulse = fmod(_glow_pulse + delta * 2.5, TAU)

	if _hit_flash > 0.0:
		_hit_flash = move_toward(_hit_flash, 0.0, delta * 4.0)

	if _shake_timer > 0.0:
		_shake_timer -= delta
		var intensity = _shake_timer * 8.0
		_shake_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	else:
		_shake_offset = Vector2.ZERO

	# aggiorna particelle
	for i in range(_particles.size() - 1, -1, -1):
		var p = _particles[i]
		p.life -= delta
		if p.life <= 0.0:
			_particles.remove_at(i)
			continue
		p.pos += p.vel * delta
		p.vel.y -= 60.0 * delta   # gravità leggera
		p.alpha = clamp(p.life / p.max_life, 0.0, 1.0)

	queue_redraw()

# =======================
# DRAW — tutto il visual custom
# =======================
func _draw() -> void:
	var base_color: Color = RARITY_COLORS.get(rarity, Color.WHITE)
	var glow_color: Color = RARITY_GLOW.get(rarity, Color(1,1,1,0.1))

	# --- GLOW PULSANTE attorno al coffre ---
	var glow_radius = 42.0 + sin(_glow_pulse) * 6.0
	var glow_alpha  = glow_color.a + sin(_glow_pulse) * 0.08
	var gc = glow_color
	gc.a = glow_alpha
	# layer multipli per effetto bloom fake
	for i in range(3):
		var r = glow_radius + i * 10.0
		var c = gc
		c.a *= (1.0 - i * 0.3)
		draw_circle(_shake_offset, r, c)

	# --- FLASH HIT (schiarita bianca) ---
	if _hit_flash > 0.0:
		var fc = Color(1, 1, 1, _hit_flash * 0.55)
		draw_circle(_shake_offset, 38.0, fc)

	# --- BARRA HP disegnata a mano (sopra il nodo $percent built-in) ---
	_draw_hp_bar()

	# --- PARTICELLE ---
	for p in _particles:
		var c: Color = p.color
		c.a = p.alpha
		draw_circle(p.pos, p.size, c)

	# --- ANELLO RARITY (epic only: anello rotante) ---
	if rarity == "epic":
		_draw_epic_ring()

func _draw_hp_bar() -> void:
	var bar_w   = 60.0
	var bar_h   = 7.0
	var bar_pos = Vector2(-bar_w * 0.5, -52.0) + _shake_offset

	# sfondo
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0, 0, 0, 0.6))

	# riempimento
	var fill_ratio = float(maxhp - hp) / float(maxhp)
	var fill_color = Color(0.1 + fill_ratio * 0.8, 0.9 - fill_ratio * 0.7, 0.1, 0.9)
	if fill_ratio > 0.0:
		draw_rect(Rect2(bar_pos, Vector2(bar_w * fill_ratio, bar_h)), fill_color)

	# bordo
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(1, 1, 1, 0.4), false, 1.0)

func _draw_epic_ring() -> void:
	var segments = 12
	var radius   = 50.0 + sin(_glow_pulse * 0.7) * 4.0
	var rot_off  = _glow_pulse * 0.5

	for i in range(segments):
		var angle_a = rot_off + (TAU / segments) * i
		var angle_b = rot_off + (TAU / segments) * (i + 0.6)
		var p1 = _shake_offset + Vector2(cos(angle_a), sin(angle_a)) * radius
		var p2 = _shake_offset + Vector2(cos(angle_b), sin(angle_b)) * radius
		var alpha = 0.5 + sin(_glow_pulse + i) * 0.3
		draw_line(p1, p2, Color(0.9, 0.2, 1.0, alpha), 2.0, true)

# =======================
# HIT HANDLER
# =======================
func _on_area_entered(area: Area2D) -> void:
	if opened:
		return
	if area.is_in_group("p_bullet"):
		if not is_instance_valid(area):
			return
		hp -= 1
		area.queue_free()
		$open.play("hit")
		$percent.value = maxhp - hp

		# VFX: flash + shake + particelle hit
		_hit_flash   = 1.0
		_shake_timer = 0.18
		_spawn_hit_particles()

		if hp <= 0:
			_open()

# =======================
# OPEN CHEST
# =======================
func _open() -> void:
	Global.update_mission_progress("collect_void", 1)
	if opened:
		return

	if has_node("Price"):
		match rarity:
			"common": $Price.texture = load("res://Gres/Assets/Icons/incognito_2.png")
			"rare":   $Price.texture = load("res://Gres/Assets/Icons/incognito_3.png")
			"epic":   $Price.texture = load("res://Gres/Assets/Icons/incognito_4.png")

	$open.play("open")
	opened = true

	# Burst di particelle all'apertura
	_spawn_open_burst()

func _on_open_animation_finished(anim_name: StringName) -> void:
	if anim_name != "open":
		return

	var weapon_name = _get_random_weapon(rarity)
	Global.register_found_weapon(weapon_name, rarity)

	var is_new = not GlobalInventory.has_weapon(weapon_name, rarity)
	if is_new:
		GlobalInventory.add_weapon(weapon_name, rarity)
		GlobalStats.weapon_collected_lvl   += 1
		GlobalStats.weapon_collected_total += 1
		if GlobalStats.weapon_collected_total == 10:
			GlobalStats.achievements["Astral Collector"] = true
	else:
		GlobalStats.gold += 100

	if is_new:
		GlobalWeapons.emit_signal("gun_found", weapon_name, rarity)

	call_deferred("queue_free")

# =======================
# RANDOM RARITY  (FIX: iterazione corretta)
# =======================
func _get_random_rarity() -> String:
	var roll = randi() % 100
	var cumulative = 0
	# Ordine: epic → rare → common (dal più raro al più comune)
	for r in rarities:
		cumulative += rarity_chances[r]
		if roll < cumulative:
			return r
	return "common"

# =======================
# RANDOM WEAPON
# =======================
func _get_random_weapon(r: String) -> String:
	var filtered: Array = []
	for k in GlobalWeapons.weapons.keys():
		if GlobalWeapons.weapons[k].has(r):
			filtered.append(k)
	if filtered.is_empty():
		return "SOLBREAKER"
	return filtered[randi() % filtered.size()]

# =======================
# FLOATING
# =======================
func _start_floating() -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = get_tree().create_tween()
	_move_randomly()
	tween.tween_callback(_start_floating)

func _move_randomly() -> void:
	if not tween:
		return
	var offset   = Vector2(randf_range(-float_range, float_range), randf_range(-float_range, float_range))
	var target_p = start_position + offset
	tween.tween_property(self, "position", target_p,        float_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start_position,  float_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# =======================
# PARTICELLE (custom, no GPUParticles richiesti)
# =======================
func _spawn_hit_particles() -> void:
	var base_color = RARITY_COLORS.get(rarity, Color.WHITE)
	for i in range(8):
		var angle = TAU * i / 8.0 + randf_range(-0.3, 0.3)
		var speed = randf_range(40.0, 110.0)
		_particles.append({
			"pos":      _shake_offset + Vector2.ZERO,
			"vel":      Vector2(cos(angle), sin(angle)) * speed,
			"life":     randf_range(0.25, 0.55),
			"max_life": 0.55,
			"alpha":    1.0,
			"size":     randf_range(2.0, 5.0),
			"color":    base_color,
		})

func _spawn_open_burst() -> void:
	var base_color = RARITY_COLORS.get(rarity, Color.WHITE)
	var count = 20 if rarity == "epic" else (14 if rarity == "rare" else 8)
	for i in range(count):
		var angle = TAU * i / float(count) + randf_range(-0.4, 0.4)
		var speed = randf_range(60.0, 180.0)
		_particles.append({
			"pos":      Vector2.ZERO,
			"vel":      Vector2(cos(angle), sin(angle)) * speed,
			"life":     randf_range(0.4, 0.9),
			"max_life": 0.9,
			"alpha":    1.0,
			"size":     randf_range(3.0, 8.0),
			"color":    base_color.lightened(randf_range(0.0, 0.4)),
		})

func _spawn_ambient_particles() -> void:
	# Piccole particelle flottanti permanenti (si rispawnano da sole)
	# Chiamata solo una volta in _ready, poi si auto-rigenera in _process
	# tramite timer casuale — versione semplice: spawniamo 3 iniziali
	var base_color = RARITY_COLORS.get(rarity, Color.WHITE)
	for i in range(3):
		var angle = randf() * TAU
		_particles.append({
			"pos":      Vector2(randf_range(-20, 20), randf_range(-20, 20)),
			"vel":      Vector2(cos(angle), sin(angle)) * randf_range(8.0, 20.0),
			"life":     randf_range(0.6, 1.5),
			"max_life": 1.5,
			"alpha":    1.0,
			"size":     randf_range(1.5, 3.5),
			"color":    base_color,
		})
