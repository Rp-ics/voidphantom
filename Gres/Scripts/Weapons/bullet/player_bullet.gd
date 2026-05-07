extends Area2D
class_name PlayerBullet

@export var base_texture: Texture2D

var speed: float = 800.0
var direction: Vector2 = Vector2.RIGHT
var damage: int = 5
var fire_rate: float = 0.25
var projectile_type: String = "line"
var bullet_owner: Node = null

var traveled_distance: float = 0.0
var return_distance: float = 500.0
var life_timer: float = 0.0
var max_life: float = 5.0
var target: Node2D = null
var spawned: bool = false

var rift_timer: float = 0.0
var collided: bool = false

var start_angle := 0.0
var radius := 60.0

var zigzag_amplitude: float = 200.0
var zigzag_frequency: float = 20.0
var zigzag_timer: float = 0.0
var start_position: Vector2

const BULLET_SCENE_PATH := "res://Gres/Scenes/weapons/bullet/player_bullet.tscn"

var weapon_name: String = ""
var weapon_rarity: String = ""
@onready var bullet_sprite: Sprite2D = $Sprite
var weapon_info: Dictionary = {}

var _has_hit: bool = false

# ============================================================
# == VARIABILI NUOVE ARMI VOID
# ============================================================
var _magnet_tick_timer: float = 0.0
var _rift_positions: Array = []
var _rift_last_pos: Vector2 = Vector2.ZERO
var _chrono_field_applied: bool = false
var _leech_applied: bool = false
var _spawn_pos: Vector2 = Vector2.ZERO
var _echo_spawned: bool = false
var _storm_hit_target: Node2D = null
var _storm_hit_count: int = 0
var _storm_hit_timer: float = 0.0
var _is_mine: bool = false
var _mine_armed: bool = false
var _mine_trigger_radius: float = 80.0
var _mine_explosion_radius: float = 200.0
var _mine_stop_time: float = 0.5
var _swap_done: bool = false
var _mind_effect_applied: bool = false

# ============================================================
# == VARIABILI DRAW — condivise da tutti gli effetti _draw()
# ============================================================
var swap_percent := 15
# Scia trail: array di posizioni nel sistema world (converito in locale in _draw)
var _trail_points: Array[Vector2] = []
var _trail_max_points: int = 40

# Timer globale per animazioni continue
var _draw_time: float = 0.0

# Rift scar: Line2D esterna che persiste dopo la morte del bullet
var _rift_line: Node2D = null  # nodo RiftScarDrawer

# Graviton: il nodo field che resta sul posto
var _graviton_field: Node2D = null
var _graviton_spawned: bool = false

# Mine: nodo MinePulseDrawer attaccato
var _mine_draw_node: Node2D = null
var _mine_draw_spawned: bool = false

# Explosion flash: timer per l'esplosione visiva
var _explosion_flash_timer: float = -1.0
var _explosion_flash_pos: Vector2 = Vector2.ZERO

# Swap portal spawned
var _swap_portal_spawned: bool = false

# Chrono ring spawned
var _chrono_ring: Node2D = null
var _chrono_ring_spawned: bool = false

# Soul leech beam target pos
var _leech_last_target_pos: Vector2 = Vector2.ZERO
var _leech_beam_node: Node2D = null


# ============================================================
# == _READY
# ============================================================
func _ready() -> void:
	
	
	GlobalStats.bullets_shoot_lvl += 1
	GlobalStats.bullets_shoot_total += 1
	if GlobalStats.bullets_shoot_total >= 1000000:
		GlobalStats.achievements["Mirage of Million Shots"] = true
	$Killer.wait_time = Global.bullet_life

	match projectile_type:
		"nullborn_sovereign_shot":
			$eclipse.emitting = true
			bullet_sprite.visible = false  # il draw sostituisce lo sprite
		"oblivion_herald_shot":
			$BlackHole.show()
			$BlackHole/part.emitting = true
		"voidfather_eclipse_shot":
			$Colapse.show()
		"proximity_mine_shot":
			_mine_stop_time       = weapon_info.get("mine_stop_time", 0.5)
			_mine_trigger_radius  = weapon_info.get("mine_trigger_radius", 80.0)
			_mine_explosion_radius = weapon_info.get("mine_explosion_radius", 200.0)
		"entropy_cannon_shot":
			pass  # _spawn_pos è settato in init_from_weapon
		"rift_blade_shot":
			# _rift_last_pos è settato in init_from_weapon
			# Nasconde lo sprite base — la scia è tutto
			bullet_sprite.modulate = Color(0.6, 0.0, 1.0, 0.9)

	# Abilita _draw() per tutti i tipi speciali
	_init_trail_types()


func _init_trail_types() -> void:
	var draw_types = [
		"homing", "tide_homing", "ImplosionBurst", "VoidRift",
		"piercing_burn", "nullborn_sovereign_shot", "oblivion_herald_shot",
		"voidfather_eclipse_shot", "aegis_storm_shot", "mind_fracture_shot",
		"wall_caster_shot", "proximity_mine_shot", "graviton_pulse_shot",
		"phantom_echo_shot", "chrono_ripper_shot", "soul_leech_shot",
		"entropy_cannon_shot", "necro_pulse_shot", "rift_blade_shot",
		"storm_caller_shot", "dimensional_swap_shot", "bounce",
		"seismic_bounce", "boomerang", "wave_split", "explode_after",
		"zigzag", "follow_stop"
	]
	if projectile_type in draw_types:
		set_process(true)  # attiva _process per queue_redraw


# ============================================================
# == _PROCESS: aggiorna timer draw e trail
# ============================================================
func _process(_delta: float) -> void:
	_draw_time += _delta

	# Aggiorna trail per tipi che lo usano
	var trail_types = [
		"homing", "tide_homing", "piercing_burn",
		"nullborn_sovereign_shot", "oblivion_herald_shot",
		"voidfather_eclipse_shot", "aegis_storm_shot",
		"mind_fracture_shot", "wall_caster_shot",
		"phantom_echo_shot", "chrono_ripper_shot",
		"soul_leech_shot", "entropy_cannon_shot",
		"necro_pulse_shot", "storm_caller_shot",
		"dimensional_swap_shot", "bounce", "seismic_bounce",
		"boomerang", "wave_split", "explode_after",
		"zigzag", "follow_stop", "ImplosionBurst", "VoidRift"
	]
	if projectile_type in trail_types:
		_trail_points.append(global_position)
		if _trail_points.size() > _trail_max_points:
			_trail_points.remove_at(0)

	# Aggiorna scia rift blade (nodo esterno)
	if projectile_type == "rift_blade_shot" and is_instance_valid(_rift_line):
		_rift_line.call("add_world_point", global_position)

	# Entropy: scala e colore crescono col volo
	if projectile_type == "entropy_cannon_shot" and is_instance_valid(bullet_sprite):
		var dist_t = clamp(_spawn_pos.distance_to(global_position) / weapon_info.get("max_range_px", 800.0), 0.0, 1.0)
		bullet_sprite.scale = Vector2.ONE * lerp(0.5, 2.2, dist_t)
		bullet_sprite.modulate = Color(lerp(0.4, 1.0, dist_t), lerp(0.3, 0.8, dist_t) * (1.0 - dist_t), 0.0, 1.0)

	queue_redraw()


# ============================================================
# == _DRAW: CENTRO DI TUTTE LE ANIMAZIONI PROCEDURALI
# ============================================================
func _draw() -> void:
	if _trail_points.size() < 2:
		match projectile_type:
			"proximity_mine_shot":
				if _is_mine:
					_draw_mine()
			"graviton_pulse_shot":
				if life_timer >= 0.3:
					_draw_graviton_field()
		return

	match projectile_type:

		# ---- HOMING: scia cinetica arancione/bianca ----
		"homing", "tide_homing":
			_draw_energy_trail(Color(1.0, 0.5, 0.0), Color(1.0, 1.0, 0.5), 5.0, 1.5)

		# ---- BOUNCE: scia neon verde che zigzaga ----
		"bounce", "seismic_bounce":
			_draw_energy_trail(Color(0.0, 1.0, 0.3), Color(0.3, 1.0, 0.6), 4.0, 1.0)

		# ---- BOOMERANG: arco curvo giallo ----
		"boomerang":
			_draw_energy_trail(Color(1.0, 0.9, 0.0), Color(1.0, 0.5, 0.0), 5.0, 1.5)

		# ---- ZIGZAG: scia a onde ciano elettrico ----
		"zigzag":
			_draw_energy_trail(Color(0.0, 0.8, 1.0), Color(0.4, 0.0, 1.0), 4.0, 1.0)

		# ---- FOLLOW STOP: scia corta magenta ----
		"follow_stop":
			_draw_energy_trail(Color(1.0, 0.0, 0.8), Color(0.5, 0.0, 0.5), 3.5, 1.0)

		# ---- WAVE SPLIT / EXPLODE AFTER: scia doppia violacea ----
		"wave_split", "explode_after":
			_draw_double_trail(Color(0.8, 0.0, 1.0), Color(1.0, 0.4, 0.0))

		# ---- PIERCING BURN: scia fuoco che brucia ----
		"piercing_burn":
			_draw_fire_trail()

		# ---- IMPLOSION BURST: scia a spirale che si restringe ----
		"ImplosionBurst":
			_draw_implosion_trail()

		# ---- VOID RIFT: scia cosmica con distorsione ----
		"VoidRift":
			_draw_void_rift_trail()

		# ---- NULLBORN SOVEREIGN: scia ghiaccio cristallino blu ----
		"nullborn_sovereign_shot":
			_draw_ice_trail()
			_draw_nullborn_core()

		# ---- OBLIVION HERALD: scia nera gravitazionale ----
		"oblivion_herald_shot":
			_draw_gravity_trail()

		# ---- VOIDFATHER ECLIPSE: scia apocalittica ----
		"voidfather_eclipse_shot":
			_draw_eclipse_trail()

		# ---- AEGIS STORM: scia a energia con scintille ----
		"aegis_storm_shot":
			_draw_aegis_trail()

		# ---- MIND FRACTURE: scia psionica verde malata ----
		"mind_fracture_shot":
			_draw_mind_fracture_trail()

		# ---- WALL CASTER: scia geometrica a mattoni ----
		"wall_caster_shot":
			_draw_wall_caster_trail()

		# ---- PROXIMITY MINE: volo + stato mina ----
		"proximity_mine_shot":
			if not _is_mine:
				_draw_energy_trail(Color(1.0, 0.1, 0.0), Color(1.0, 0.6, 0.0), 4.0, 1.0)
			else:
				_draw_mine()

		# ---- GRAVITON PULSE: campo magnetico ----
		"graviton_pulse_shot":
			if life_timer < 0.3:
				_draw_energy_trail(Color(0.5, 0.0, 1.0), Color(0.8, 0.0, 1.0), 4.0, 1.0)
			else:
				_draw_graviton_field()

		# ---- PHANTOM ECHO: scia fantasma sfumata ----
		"phantom_echo_shot":
			_draw_phantom_trail()

		# ---- CHRONO RIPPER: scia distorsione temporale ----
		"chrono_ripper_shot":
			_draw_chrono_trail()

		# ---- SOUL LEECH: scia di sangue/anime ----
		"soul_leech_shot":
			_draw_soul_leech_trail()

		# ---- ENTROPY CANNON: scia di calore che cresce ----
		"entropy_cannon_shot":
			_draw_entropy_trail()

		# ---- NECRO PULSE: scia verde putrefazione ----
		"necro_pulse_shot":
			_draw_necro_trail()

		# ---- RIFT BLADE: scia gestita dal nodo esterno, bullet ha corona ----
		"rift_blade_shot":
			_draw_rift_blade_core()

		# ---- STORM CALLER: scia con archi elettrici ----
		"storm_caller_shot":
			_draw_storm_trail()

		# ---- DIMENSIONAL SWAP: scia shift dimensionale ----
		"dimensional_swap_shot":
			_draw_swap_trail()


# ============================================================
# == FUNZIONI DRAW SPECIFICHE PER OGNI TIPO
# ============================================================

# --- Utility: converte world pos in locale per draw ---
# IMPORTANTE: applica rotazione inversa del nodo — _draw() è in spazio locale,
# quindi (world_offset) deve essere ruotato di -rotation per allinearsi al nodo.
# Senza questo il trail appare davanti al proiettile invece che dietro.
func _to_local_trail() -> Array[Vector2]:
	var local: Array[Vector2] = []
	var inv_rot := -rotation
	for p in _trail_points:
		local.append((p - global_position).rotated(inv_rot))
	return local

# --- TRAIL BASE: scia sfumata con glow + nucleo pulsante ---
func _draw_energy_trail(col_head: Color, col_tail: Color, w_head: float, w_tail: float) -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	# Scia principale con sfumatura
	for i in range(n - 1):
		var t := float(i) / float(n)
		var col := col_tail.lerp(col_head, t)
		col.a = t * 0.9
		var w = lerp(w_tail, w_head, t)
		draw_line(pts[i], pts[i + 1], col, w, true)
	# Alone esterno soffice
	for i in range(n - 1):
		var t := float(i) / float(n)
		var gc := col_head
		gc.a = t * 0.18
		draw_line(pts[i], pts[i + 1], gc, (w_head + 5.0) * t, true)
	# Nucleo al bullet (ultimo punto = testa, vicino a zero)
	var pulse := sin(_draw_time * 14.0) * 0.5 + 0.5
	draw_circle(Vector2.ZERO, 3.5 + pulse * 2.5, col_head)
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 1.0, 0.9))
	# Speed lines: 3 trattini corti dietro la testa
	if n > 3:
		for k in range(3):
			var idx := n - 2 - k * 2
			if idx < 0: break
			var lc := col_head
			lc.a = (1.0 - float(k) * 0.3) * 0.7
			draw_line(pts[idx], pts[min(idx + 1, n - 1)], lc, w_head * (1.0 - float(k) * 0.25), true)

# --- DOUBLE TRAIL: due scie parallele che divergono ---
func _draw_double_trail(col_a: Color, col_b: Color) -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		var perp := Vector2(-(pts[i+1] - pts[i]).normalized().y, (pts[i+1] - pts[i]).normalized().x)
		var off := perp * (1.0 - t) * 8.0
		var ca := col_a; ca.a = t * 0.85
		var cb := col_b; cb.a = t * 0.85
		draw_line(pts[i] + off, pts[i+1] + off, ca, lerp(1.0, 4.0, t), true)
		draw_line(pts[i] - off, pts[i+1] - off, cb, lerp(1.0, 4.0, t), true)

# --- FIRE TRAIL: fuoco vivo con lingue e braci ---
func _draw_fire_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Scia esterna bruciante (alone arancio largo)
		var outer := Color(1.0, 0.15, 0.0, t * 0.22)
		draw_line(pts[i], pts[i + 1], outer, lerp(6.0, 18.0, t), true)
		# Corpo fuoco (giallo → rosso)
		var fire := Color(1.0, lerp(0.0, 0.75, t), 0.0, t * 0.95)
		draw_line(pts[i], pts[i + 1], fire, lerp(1.5, 7.0, t), true)
		# Linea bianca interna (nucleo più caldo)
		draw_line(pts[i], pts[i + 1], Color(1.0, 1.0, 0.6, t * 0.5), lerp(0.5, 2.5, t), true)
		# Lingue di fiamma: segmenti laterali frenetici
		if i % 3 == 0 and t > 0.25 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			var tongue_amp := sin(_draw_time * 20.0 + float(i) * 1.3) * 9.0 * t
			var tongue_tip := pts[i] + perp * tongue_amp + d * 4.0
			draw_line(pts[i], tongue_tip, Color(1.0, 0.6, 0.0, t * 0.55), 1.5, true)
		# Braci: cerchietti bianchi/gialli
		if i % 5 == 0 and t > 0.15:
			var ember_r := randf_range(1.0, 2.8)
			draw_circle(pts[i] + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)) * t,
						ember_r, Color(1.0, 0.95, 0.4, t * 0.65))
	# Core: fiamma pulsante con corona
	var fp := sin(_draw_time * 18.0) * 0.4 + 0.6
	draw_circle(Vector2.ZERO, 7.0 * fp, Color(1.0, 0.3, 0.0, 0.5))
	draw_circle(Vector2.ZERO, 4.5 * fp, Color(1.0, 0.7, 0.0, 0.85))
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 0.8, 1.0))

# --- IMPLOSION: scia che si restringe a spirale con anelli collassanti ---
func _draw_implosion_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Alone viola largo che si restringe
		draw_line(pts[i], pts[i + 1], Color(0.9, 0.1, 1.0, t * 0.12), lerp(18.0, 3.0, t), true)
		# Corpo principale
		draw_line(pts[i], pts[i + 1], Color(0.7, 0.0, 1.0, t * 0.9), lerp(6.0, 1.0, t), true)
		# Bordo bianco tagliente
		draw_line(pts[i], pts[i + 1], Color(1.0, 0.8, 1.0, t * 0.45), lerp(2.0, 0.5, t), true)
		# Anelli collassanti trasversali ogni 4 punti
		if i % 4 == 0 and t > 0.1:
			var ring_r = lerp(14.0, 2.0, t)
			var ring_alpha := t * 0.5
			draw_arc(pts[i], ring_r, 0.0, TAU, 16, Color(0.8, 0.0, 1.0, ring_alpha), 1.2, true)
		# Particelle che spiralano verso la testa
		if i % 6 == 0 and t > 0.2:
			var spiral_offset := Vector2(cos(_draw_time * 8.0 + float(i)), sin(_draw_time * 8.0 + float(i))) * (1.0 - t) * 8.0
			draw_circle(pts[i] + spiral_offset, 1.5 * t, Color(1.0, 0.5, 1.0, t * 0.7))
	# Nucleo: implosione multi-ring
	var pulse := sin(_draw_time * 16.0) * 0.5 + 0.5
	# Anello esterno che si contrae
	for ring in range(3):
		var rp := fmod(_draw_time * 2.5 + float(ring) * 0.33, 1.0)
		draw_arc(Vector2.ZERO, lerp(20.0, 4.0, rp), 0.0, TAU, 20,
				 Color(0.9, 0.0, 1.0, (1.0 - rp) * 0.6), 1.5, true)
	draw_circle(Vector2.ZERO, 5.0 + pulse * 4.0, Color(1.0, 0.0, 0.85, 0.85))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 1.0, 1.0, 1.0))

# --- VOID RIFT TRAIL: lacerazione cosmica con detriti stellari ---
func _draw_void_rift_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Scia principale: vuoto cosmico (nero/viola)
		draw_line(pts[i], pts[i + 1], Color(0.0, 0.0, 0.0, t * 0.95), lerp(2.0, 9.0, t), true)
		draw_line(pts[i], pts[i + 1], Color(0.3, 0.0, 0.65, t * 0.6), lerp(4.0, 14.0, t), true)
		# Bordo incandescente viola
		draw_line(pts[i], pts[i + 1], Color(0.7, 0.0, 1.0, t * 0.25), lerp(7.0, 18.0, t), true)
		# Distorsione spazio: linee laterali irregolari che "lacerano"
		if i % 3 == 0 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			for side in [-1.0, 1.0]:
				var tear_dist := sin(_draw_time * 7.0 + float(i) * 0.6 + side) * 10.0 * t
				var tear_end = pts[i] + perp * (side * abs(tear_dist))
				draw_line(pts[i], tear_end, Color(0.5, 0.0, 1.0, t * 0.35), 1.0, true)
		# Stelle che vengono "inghiottite": puntini bianchi che si allontanano
		if i % 7 == 0 and t > 0.2:
			var star_off := Vector2(cos(float(i) * 2.1), sin(float(i) * 3.7)) * randf_range(6.0, 16.0) * t
			draw_circle(pts[i] + star_off, randf_range(0.8, 2.0), Color(0.8, 0.6, 1.0, t * 0.4))
	# Core: singolarità con anelli di distorsione
	var sp := sin(_draw_time * 5.0) * 0.5 + 0.5
	for ring in range(3):
		var rr := 12.0 + float(ring) * 6.0 + sp * 3.0
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 32, Color(0.5, 0.0, 1.0, 0.15 - float(ring) * 0.04), 1.0, true)
	draw_circle(Vector2.ZERO, 5.5, Color(0.0, 0.0, 0.0, 1.0))
	draw_circle(Vector2.ZERO, 3.0, Color(0.6, 0.0, 1.0, 0.9))
	draw_circle(Vector2.ZERO, 1.5, Color(1.0, 0.8, 1.0, 1.0))

# --- NULLBORN ICE TRAIL: ghiaccio cristallino con ramificazioni ---
func _draw_ice_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Alone freddo esterno azzurro
		draw_line(pts[i], pts[i + 1], Color(0.5, 0.85, 1.0, t * 0.15), lerp(4.0, 12.0, t), true)
		# Corpo ghiaccio
		draw_line(pts[i], pts[i + 1], Color(0.35, 0.78, 1.0, t * 0.9), lerp(1.5, 6.0, t), true)
		# Brillio bianco interno
		draw_line(pts[i], pts[i + 1], Color(0.9, 1.0, 1.0, t * 0.65), lerp(0.5, 2.5, t), true)
		# Ramificazioni cristalline: dendriti laterali
		if i % 4 == 0 and t > 0.2 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			var branch_len := t * 8.0
			for side in [-1.0, 1.0]:
				var branch_tip = pts[i] + perp * side * branch_len
				draw_line(pts[i], branch_tip, Color(0.7, 0.95, 1.0, t * 0.5), 1.0, true)
				# Sub-ramificazione
				var sub_tip = branch_tip + (d + perp * side * 0.5).normalized() * branch_len * 0.5
				draw_line(branch_tip, sub_tip, Color(0.9, 1.0, 1.0, t * 0.3), 0.8, true)
		# Cristalli: croce + diagonali ogni 6 punti
		if i % 6 == 0 and t > 0.1:
			var sz := t * 4.5
			for ang in [0.0, PI * 0.25, PI * 0.5, PI * 0.75]:
				var cv := Vector2(cos(ang), sin(ang)) * sz
				draw_line(pts[i] - cv, pts[i] + cv, Color(1.0, 1.0, 1.0, t * 0.45), 0.8, true)

# --- NULLBORN CORE: nucleo congelante — fiocco di neve ruotante ---
func _draw_nullborn_core() -> void:
	var pulse := sin(_draw_time * 6.0) * 0.5 + 0.5
	# Anelli concentrici che si espandono (effetto congelamento)
	for ring in range(3):
		var ring_age := fmod(_draw_time * 1.0 + float(ring) * 0.33, 1.0)
		var ring_r = lerp(3.0, 16.0, ring_age)
		var ring_col := Color(0.5, 0.9, 1.0, (1.0 - ring_age) * 0.55)
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 24, ring_col, 1.2, true)
	# Fiocco di neve: 6 raggi principali + barbe
	var snow_rot := _draw_time * 0.8
	for arm in range(6):
		var angle := snow_rot + (TAU / 6.0) * float(arm)
		var tip := Vector2(cos(angle), sin(angle)) * (7.0 + pulse * 3.0)
		draw_line(Vector2.ZERO, tip, Color(0.8, 1.0, 1.0, 0.9), 1.5, true)
		# Barbe perpendicolari
		for barb in range(2):
			var bf := (float(barb) + 0.4) / 2.0
			var bp := Vector2(cos(angle), sin(angle)) * (tip.length() * bf)
			var perp := Vector2(-sin(angle), cos(angle)) * 3.5 * (1.0 - bf)
			draw_line(bp - perp, bp + perp, Color(0.7, 0.95, 1.0, 0.65), 1.0, true)
	draw_circle(Vector2.ZERO, 3.5, Color(0.8, 1.0, 1.0, 0.9))
	draw_circle(Vector2.ZERO, 1.5, Color(1.0, 1.0, 1.0, 1.0))

# --- GRAVITY TRAIL (Oblivion Herald): orizzonte degli eventi + lensing gravitazionale ---
func _draw_gravity_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Alone viola gravitazionale molto ampio
		draw_line(pts[i], pts[i + 1], Color(0.35, 0.0, 0.75, t * 0.18), lerp(6.0, 22.0, t), true)
		# Strato intermedio
		draw_line(pts[i], pts[i + 1], Color(0.4, 0.0, 0.8, t * 0.5), lerp(3.0, 14.0, t), true)
		# Core nero assoluto
		draw_line(pts[i], pts[i + 1], Color(0.0, 0.0, 0.0, t * 0.9), lerp(1.5, 8.0, t), true)
		# Lensing: linee radiali che "cadono" verso la scia da entrambi i lati
		if i % 3 == 0 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			for side in [-1.0, 1.0]:
				# Linea che si incurva verso il centro (lensing)
				var p_far = pts[i] + perp * side * lerp(8.0, 22.0, t)
				var p_near = pts[i] + perp * side * lerp(2.0, 6.0, t)
				draw_line(p_far, p_near, Color(0.55, 0.0, 0.9, t * 0.3), 1.0, true)
		# Detriti risucchiati: punti che spiralano
		if i % 8 == 0 and t > 0.25:
			var spiral_r := (1.0 - t) * 12.0
			var sa := _draw_time * 6.0 + float(i) * 0.9
			draw_circle(pts[i] + Vector2(cos(sa), sin(sa)) * spiral_r, 1.2, Color(0.6, 0.0, 1.0, t * 0.55))
	# Core: buco nero con accretion disk visivo
	var gp := sin(_draw_time * 3.5) * 0.5 + 0.5
	# Disco di accrescimento (ellisse simulata con arc)
	for ring in range(3):
		var rr := 10.0 + float(ring) * 4.0 + gp * 2.0
		var alpha := (0.4 - float(ring) * 0.1) * (1.0 - gp * 0.3)
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 36, Color(0.5, 0.0, 1.0, alpha), 2.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color(0.0, 0.0, 0.0, 1.0))
	draw_circle(Vector2.ZERO, 3.5, Color(0.4, 0.0, 0.8, 0.85))
	draw_circle(Vector2.ZERO, 1.5, Color(1.0, 0.5, 1.0, 1.0))

# --- ECLIPSE TRAIL (Voidfather): apocalisse cosmica — eclissi totale ---
func _draw_eclipse_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Alone ultravioletto esterno
		draw_line(pts[i], pts[i + 1], Color(0.4, 0.0, 0.6, t * 0.2), lerp(8.0, 24.0, t), true)
		# Strato viola medio
		draw_line(pts[i], pts[i + 1], Color(0.5, 0.0, 0.8, t * 0.55), lerp(4.0, 16.0, t), true)
		# Nucleo nero assoluto
		draw_line(pts[i], pts[i + 1], Color(0.0, 0.0, 0.0, t), lerp(2.5, 10.0, t), true)
		# Stelle morenti: piccoli lampi bianchi/gialli che si spengono
		if i % 4 == 0 and t > 0.25:
			var star_size := randf_range(0.8, 2.5) * t
			var star_col := Color(1.0, randf_range(0.7, 1.0), randf_range(0.3, 0.7), t * 0.45)
			draw_circle(pts[i], star_size, star_col)
		# Filamenti corona: raggi che fuoriescono perpendicolarmente
		if i % 5 == 0 and t > 0.3 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			var fil_len := sin(_draw_time * 4.0 + float(i) * 0.7) * 12.0 * t
			draw_line(pts[i], pts[i] + perp * fil_len, Color(0.8, 0.2, 1.0, t * 0.3), 1.0, true)
	# Core: eclissi — disco nero con corona solare violacea
	var cp := sin(_draw_time * 4.0) * 0.35 + 0.65
	# Corona: raggi irregolari
	var corona_count := 12
	for ci in range(corona_count):
		var ca := (TAU / corona_count) * ci + _draw_time * 0.3
		var cl := (8.0 + sin(_draw_time * 6.0 + float(ci) * 1.1) * 4.0) * cp
		draw_line(Vector2.ZERO, Vector2(cos(ca), sin(ca)) * cl,
				  Color(0.8, 0.0, 1.0, 0.45), 1.2, true)
	# Aureola diffusa
	draw_circle(Vector2.ZERO, 11.0 * cp, Color(0.6, 0.0, 1.0, 0.35))
	# Disco oscuro
	draw_circle(Vector2.ZERO, 6.5, Color(0.0, 0.0, 0.0, 1.0))
	draw_circle(Vector2.ZERO, 2.5, Color(0.7, 0.0, 0.9, 0.9))

# --- AEGIS TRAIL: scudo ad energia con frammenti esagonali ---
func _draw_aegis_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		var pulse := sin(_draw_time * 12.0 + float(i) * 0.4) * 0.5 + 0.5
		# Alone scudo viola esterno
		draw_line(pts[i], pts[i + 1], Color(0.3, 0.0, 0.9, t * 0.15), lerp(5.0, 16.0, t), true)
		# Corpo energia
		var col := Color(0.45 + pulse * 0.45, 0.05, 1.0, t * 0.85)
		draw_line(pts[i], pts[i + 1], col, lerp(1.5, 6.0, t), true)
		# Linea interna bianca
		draw_line(pts[i], pts[i + 1], Color(0.9, 0.8, 1.0, t * 0.4), lerp(0.5, 2.0, t), true)
		# Frammenti esagonali: 6 lati ridotti come segmenti
		if i % 7 == 0 and t > 0.2:
			var hex_r := t * 7.0
			var hex_col := Color(0.8, 0.5, 1.0, t * 0.5)
			for side in range(6):
				var a1 := (TAU / 6.0) * side
				var a2 := (TAU / 6.0) * (side + 1)
				var hp1 := pts[i] + Vector2(cos(a1), sin(a1)) * hex_r
				var hp2 := pts[i] + Vector2(cos(a2), sin(a2)) * hex_r
				draw_line(hp1, hp2, hex_col, 0.8, true)
		# Scariche laterali
		if i % 4 == 0 and t > 0.35 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			var spark_off := perp * randf_range(-10.0, 10.0) * t
			draw_line(pts[i], pts[i] + spark_off, Color(1.0, 0.7, 1.0, t * 0.5), 0.8, true)
	# Core: scudo pulsante con croce energetica
	var cp := sin(_draw_time * 9.0) * 0.5 + 0.5
	draw_circle(Vector2.ZERO, 8.0 + cp * 3.0, Color(0.5, 0.0, 1.0, 0.2 + cp * 0.2))
	draw_circle(Vector2.ZERO, 5.0, Color(0.7, 0.0, 1.0, 0.7))
	# Croce energetica
	for ca in [0.0, PI * 0.5, PI, PI * 1.5]:
		draw_line(Vector2.ZERO, Vector2(cos(ca), sin(ca)) * (5.0 + cp * 3.0),
				  Color(1.0, 0.8, 1.0, 0.8), 1.2, true)
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 1.0, 1.0))

# --- MIND FRACTURE TRAIL: onde psioniche con vene fractali e occhio spaccato ---
func _draw_mind_fracture_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Alone psiconico verde esterno
		draw_line(pts[i], pts[i + 1], Color(0.0, 0.8, 0.2, t * 0.12), lerp(5.0, 14.0, t), true)
		# Core verde malato
		draw_line(pts[i], pts[i + 1], Color(0.0, lerp(0.3, 0.9, t), 0.18, t * 0.9), lerp(1.5, 5.0, t), true)
		# Linea interna brillante
		draw_line(pts[i], pts[i + 1], Color(0.4, 1.0, 0.5, t * 0.35), lerp(0.5, 2.0, t), true)
		# Vene fractali: biforcazioni laterali che si spezzano
		if i % 3 == 0 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			var wave := sin(_draw_time * 18.0 + float(i) * 1.1) * 10.0 * t
			var vein_end := pts[i] + perp * wave
			draw_line(pts[i], vein_end, Color(0.0, 1.0, 0.35, t * 0.4), 0.8, true)
			# Biforcazione terminale
			if t > 0.4:
				var fork1 := vein_end + (d + perp * 0.5).normalized() * 4.0 * t
				var fork2 := vein_end + (d - perp * 0.5).normalized() * 4.0 * t
				draw_line(vein_end, fork1, Color(0.0, 0.9, 0.3, t * 0.3), 0.6, true)
				draw_line(vein_end, fork2, Color(0.0, 0.9, 0.3, t * 0.3), 0.6, true)
	# Occhio psiconico che si "spacca"
	var ep := sin(_draw_time * 10.0) * 0.5 + 0.5
	var eye_r := 5.0 + ep * 3.0
	# Iride
	draw_circle(Vector2.ZERO, eye_r, Color(0.0, 0.8, 0.2, 0.8))
	# Pupilla che si dilata
	draw_circle(Vector2.ZERO, eye_r * (0.3 + ep * 0.25), Color(0.0, 0.0, 0.0, 1.0))
	# Vene sull'iride
	for vv in range(4):
		var va := (TAU / 4.0) * vv + _draw_time * 2.0
		draw_line(Vector2.ZERO, Vector2(cos(va), sin(va)) * eye_r * 0.7,
				  Color(0.2, 1.0, 0.4, 0.45), 0.8, true)
	draw_circle(Vector2.ZERO, 1.2, Color(0.6, 1.0, 0.6, 1.0))

# --- WALL CASTER TRAIL: blocchi geometrici di energia ----
func _draw_wall_caster_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	# Scia principale bianca/azzurra
	for i in range(n - 1):
		var t := float(i) / float(n)
		draw_line(pts[i], pts[i+1], Color(0.6, 0.8, 1.0, t * 0.8), lerp(1.5, 5.0, t), true)
	# Segmenti perpendicolari (mattoni):
	for i in range(0, n - 1, 5):
		var t := float(i) / float(n)
		if pts.size() <= i + 1: break
		var d := (pts[i+1] - pts[i]).normalized()
		var perp := Vector2(-d.y, d.x)
		var half := 6.0 * t
		draw_line(pts[i] - perp * half, pts[i] + perp * half, Color(1.0, 1.0, 1.0, t * 0.6), 2.0)

# --- MINE DRAW: mina stazionaria pulsante con raggio di allerta ---
func _draw_mine() -> void:
	var pulse := sin(_draw_time * 7.0) * 0.5 + 0.5
	var danger_pulse := sin(_draw_time * 12.0) * 0.5 + 0.5

	# Raggio trigger: cerchio tratteggiato rosso pulsante
	var tr := _mine_trigger_radius
	var segments := 24
	for i in range(segments):
		if i % 2 == 0: continue
		var a1 := (TAU / segments) * i
		var a2 := (TAU / segments) * (i + 1)
		var p1 := Vector2(cos(a1), sin(a1)) * tr
		var p2 := Vector2(cos(a2), sin(a2)) * tr
		draw_line(p1, p2, Color(1.0, 0.1, 0.0, 0.2 + danger_pulse * 0.3), 1.5)

	# Alone di pericolo esterno (molto sottile)
	draw_arc(Vector2.ZERO, tr, 0, TAU, 48, Color(1.0, 0.0, 0.0, 0.06 + pulse * 0.08), 1.0, true)

	# Corpo mina: quadrato ruotante con raggi
	var rot := _draw_time * 2.0
	for i in range(4):
		var a := rot + (TAU / 4.0) * i
		var p := Vector2(cos(a), sin(a)) * (7.0 + pulse * 3.0)
		draw_line(Vector2.ZERO, p, Color(1.0, 0.2 + pulse * 0.5, 0.0, 0.8), 2.0)
		draw_circle(p, 2.0, Color(1.0, 0.5, 0.0, 0.9))

	# Core centrale
	draw_circle(Vector2.ZERO, 4.0 + pulse * 2.0, Color(1.0, 0.0, 0.0, 0.9))
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.8, 0.0, 1.0))

	# Croce di puntamento
	var cross := 8.0 + pulse * 2.0
	draw_line(Vector2(-cross, 0), Vector2(cross, 0), Color(1.0, 1.0, 1.0, 0.5 + pulse * 0.3), 1.0)
	draw_line(Vector2(0, -cross), Vector2(0, cross), Color(1.0, 1.0, 1.0, 0.5 + pulse * 0.3), 1.0)

# --- GRAVITON FIELD: anelli che si restringono verso il centro ---
func _draw_graviton_field() -> void:
	var duration: float = weapon_info.get("magnet_duration", 3.5)
	var field_r: float  = weapon_info.get("magnet_radius", 300.0)
	var t_alive = clamp((life_timer - 0.3) / duration, 0.0, 1.0)
	var fade = 1.0 - t_alive

	# 4 anelli in fase diversa che si restringono verso il centro
	for ring in range(4):
		var phase := fmod(_draw_time * 1.2 + float(ring) * 0.25, 1.0)
		var r := field_r * (1.0 - phase)
		var alpha = phase * fade * 0.55
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.5, 0.0, 1.0, alpha), 2.5, true)
		# Linee radiali — frecce verso il centro
		if ring == 0:
			var arrow_count := 8
			for ai in range(arrow_count):
				var angle := (TAU / arrow_count) * ai + _draw_time * 0.5
				var outer_p := Vector2(cos(angle), sin(angle)) * r
				var inner_p := outer_p * 0.7
				draw_line(outer_p, inner_p, Color(0.7, 0.0, 1.0, alpha * 1.2), 1.5)

	# Nucleo singolarità
	var core_r := 8.0 + sin(_draw_time * 10.0) * 4.0
	draw_circle(Vector2.ZERO, core_r, Color(0.6, 0.0, 1.0, fade * 0.8))
	draw_circle(Vector2.ZERO, core_r * 0.5, Color(1.0, 0.5, 1.0, fade))
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 1.0, fade))

# --- PHANTOM TRAIL: scia fantasma con copie spettrali sfasate ---
func _draw_phantom_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	# Layer 1: alone esterno soffice bianco-blu
	for i in range(n - 1):
		var t := float(i) / float(n)
		draw_line(pts[i], pts[i + 1], Color(0.7, 0.7, 1.0, t * 0.12), lerp(6.0, 16.0, t), true)
	# Layer 2: corpo fantasma
	for i in range(n - 1):
		var t := float(i) / float(n)
		draw_line(pts[i], pts[i + 1], Color(0.5, 0.55, 1.0, t * 0.65), lerp(1.5, 5.0, t), true)
	# Copie fantasma sfasate (offset laterale oscillante)
	for ghost in range(2):
		var ghost_offset := sin(_draw_time * 4.0 + float(ghost) * PI) * 5.0
		for i in range(n - 1):
			var t := float(i) / float(n)
			if i + 1 >= pts.size(): break
			var d := (pts[i + 1] - pts[i])
			var perp := Vector2(-d.normalized().y, d.normalized().x) * ghost_offset
			draw_line(pts[i] + perp, pts[i + 1] + perp,
					  Color(0.4 + float(ghost) * 0.3, 0.4, 1.0, t * (0.2 - float(ghost) * 0.08)),
					  lerp(1.0, 3.0, t), true)
	# Puntini fantasma
	for i in range(0, n, 5):
		var t := float(i) / float(n)
		draw_circle(pts[i], 2.2 * t, Color(0.7, 0.7, 1.0, t * 0.45))
	# Core: triplo ghosting — tre cerchi sfasati
	var gp := sin(_draw_time * 7.0) * 4.0
	draw_circle(Vector2(gp * 0.8, gp * 0.2), 4.5, Color(0.35, 0.35, 0.9, 0.3))
	draw_circle(Vector2(-gp * 0.6, gp * 0.3), 4.5, Color(0.5, 0.5, 1.0, 0.3))
	draw_circle(Vector2.ZERO, 5.0, Color(0.88, 0.88, 1.0, 0.85))

# --- CHRONO TRAIL: distorsione temporale con echi e orologio inverso ---
func _draw_chrono_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Alone tempo esterno (cyan diffuso)
		draw_line(pts[i], pts[i + 1], Color(0.0, 0.7, 1.0, t * 0.15), lerp(5.0, 16.0, t), true)
		# Corpo ciano principale
		draw_line(pts[i], pts[i + 1], Color(0.0, 0.82, 1.0, t * 0.85), lerp(1.5, 5.0, t), true)
		# Stria interna acquamarina
		draw_line(pts[i], pts[i + 1], Color(0.3, 1.0, 0.85, t * 0.5), lerp(0.5, 2.0, t), true)
		# Echi temporali: copie sfasate del trail (ghost del passato)
		if i % 4 == 0 and i + 2 < n:
			draw_line(pts[i], pts[i + 2], Color(0.0, 1.0, 0.8, t * 0.18), 1.2, true)
		# "Crepe" temporali: brevi segmenti obliqui trasversali
		if i % 6 == 0 and t > 0.3 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			var crack_len := t * 9.0
			draw_line(pts[i] - perp * crack_len, pts[i] + perp * crack_len,
					  Color(0.5, 1.0, 1.0, t * 0.35), 0.8, true)
	# Core: orologio procedurale con lancette che girano al contrario
	var clock_r := 7.0
	draw_arc(Vector2.ZERO, clock_r, 0.0, TAU, 24, Color(0.0, 0.85, 1.0, 0.85), 1.5, true)
	# Tacche dell'orologio (12)
	for tick in range(12):
		var ta := (TAU / 12.0) * tick
		var t_outer := Vector2(cos(ta), sin(ta)) * clock_r
		var t_inner := Vector2(cos(ta), sin(ta)) * (clock_r - (2.0 if tick % 3 == 0 else 1.2))
		draw_line(t_inner, t_outer, Color(0.5, 1.0, 1.0, 0.7), 0.8, true)
	# Lancette inverse
	var hr_angle  := -_draw_time * 0.4
	var min_angle := -_draw_time * 2.5
	var sec_angle := -_draw_time * 8.0
	draw_line(Vector2.ZERO, Vector2(cos(hr_angle), sin(hr_angle)) * clock_r * 0.45,
			  Color(1.0, 1.0, 1.0, 0.95), 1.8, true)
	draw_line(Vector2.ZERO, Vector2(cos(min_angle), sin(min_angle)) * clock_r * 0.75,
			  Color(0.5, 1.0, 1.0, 0.9), 1.2, true)
	draw_line(Vector2.ZERO, Vector2(cos(sec_angle), sin(sec_angle)) * clock_r * 0.85,
			  Color(1.0, 0.3, 0.3, 0.8), 0.7, true)
	draw_circle(Vector2.ZERO, 1.8, Color(0.0, 1.0, 0.9, 1.0))

# --- SOUL LEECH TRAIL: sangue vivo con anime che orbitano ---
func _draw_soul_leech_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Alone scuro esterno
		draw_line(pts[i], pts[i + 1], Color(0.4, 0.0, 0.05, t * 0.2), lerp(4.0, 14.0, t), true)
		# Scia sanguigna principale
		draw_line(pts[i], pts[i + 1], Color(0.7, 0.0, 0.1, t * 0.92), lerp(1.5, 6.0, t), true)
		# Stria interna più scura (vena)
		draw_line(pts[i], pts[i + 1], Color(0.3, 0.0, 0.0, t * 0.5), lerp(0.5, 2.5, t), true)
		# Tendini di sangue: gocce che si allontanano e cadono
		if i % 4 == 0 and t > 0.2 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			var side := 1.0 if (i % 8 == 0) else -1.0
			var drip_len := randf_range(4.0, 12.0) * t
			var drip_end := pts[i] + perp * side * drip_len
			draw_line(pts[i], drip_end, Color(0.85, 0.0, 0.1, t * 0.55), 1.0, true)
			draw_circle(drip_end, randf_range(1.0, 2.5) * t, Color(0.9, 0.0, 0.1, t * 0.6))
	# Core: cuore pulsante con orbite di anime
	var hp := sin(_draw_time * 11.0) * 0.5 + 0.5
	# Alone sangue
	draw_circle(Vector2.ZERO, 9.0 + hp * 4.0, Color(0.5, 0.0, 0.08, 0.3))
	draw_circle(Vector2.ZERO, 5.5 + hp * 2.0, Color(0.65, 0.0, 0.1, 0.9))
	# 3 anime in orbita a raggi diversi
	for soul_i in range(3):
		var soul_angle := _draw_time * (3.5 + float(soul_i) * 1.2) + (TAU / 3.0) * soul_i
		var soul_r := 8.0 + float(soul_i) * 4.0
		var sp2 := Vector2(cos(soul_angle), sin(soul_angle)) * soul_r
		var soul_alpha := 0.6 + sin(_draw_time * 5.0 + float(soul_i)) * 0.3
		draw_circle(sp2, 2.0 - float(soul_i) * 0.4, Color(1.0, 0.2 + float(soul_i) * 0.2, 0.2, soul_alpha))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.5, 0.5, 1.0))

# --- ENTROPY TRAIL: calore crescente con plasma e shimmer ---
func _draw_entropy_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	var dist_t = clamp(_spawn_pos.distance_to(global_position) / weapon_info.get("max_range_px", 800.0), 0.0, 1.0)
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Alone calore (arancio diffuso, cresce col volo)
		draw_line(pts[i], pts[i + 1], Color(1.0, 0.35, 0.0, t * 0.18 * (0.3 + dist_t)),
				  lerp(4.0, 12.0 + dist_t * 10.0, t), true)
		# Corpo principale: grigio → rosso → giallo
		var heat_col := Color(
			lerp(0.3, 1.0, dist_t),
			lerp(0.3, lerp(0.85, 0.05, dist_t), t),
			0.0,
			t * 0.92
		)
		var w = lerp(1.0, 4.0 + dist_t * 7.0, t)
		draw_line(pts[i], pts[i + 1], heat_col, w, true)
		# Core bianco caldo (molto caldo = bianco)
		if dist_t > 0.4:
			draw_line(pts[i], pts[i + 1], Color(1.0, 0.95, 0.5, t * 0.35 * dist_t), w * 0.4, true)
		# Wisps di calore: ondulazioni laterali
		if i % 4 == 0 and dist_t > 0.25 and i + 1 < n:
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			var wisp = sin(_draw_time * 16.0 + float(i) * 1.4) * 7.0 * t * dist_t
			draw_line(pts[i], pts[i] + perp * wisp, Color(1.0, 0.55, 0.0, t * 0.3 * dist_t), 1.0, true)
		# Scorie: particelle calcinazione
		if i % 8 == 0 and dist_t > 0.5 and t > 0.2:
			draw_circle(pts[i] + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0)) * t,
						randf_range(0.8, 2.0), Color(1.0, 0.8, 0.0, t * 0.5 * dist_t))
	# Core: plasma in espansione
	var ep := sin(_draw_time * 12.0) * 0.4 + 0.6
	var core_r = 3.0 + dist_t * 10.0
	draw_circle(Vector2.ZERO, core_r * 1.8, Color(1.0, 0.3, 0.0, 0.2 * dist_t))
	draw_circle(Vector2.ZERO, core_r, Color(1.0, lerp(0.4, 0.9, dist_t), 0.0, 0.85 * ep))
	if dist_t > 0.6:
		draw_circle(Vector2.ZERO, core_r * 0.5, Color(1.0, 1.0, 0.5, 0.9))

# --- NECRO TRAIL: morte e putrefazione con nube necrotica ---
func _draw_necro_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Nube necrotica esterna (verde scuro diffuso)
		draw_line(pts[i], pts[i + 1], Color(0.0, 0.3, 0.0, t * 0.18), lerp(5.0, 16.0, t), true)
		# Scia verde ossea principale
		draw_line(pts[i], pts[i + 1], Color(0.08, lerp(0.2, 0.65, t), 0.08, t * 0.88), lerp(1.5, 5.5, t), true)
		# Stria interna (marciume più scuro)
		draw_line(pts[i], pts[i + 1], Color(0.0, 0.15, 0.0, t * 0.4), lerp(0.5, 2.0, t), true)
		# Particelle ossee: segmenti a X + cerchietti
		if i % 6 == 0 and t > 0.15:
			var sz := 3.5 * t
			draw_line(pts[i] + Vector2(-sz, -sz), pts[i] + Vector2(sz, sz),
					  Color(0.5, 1.0, 0.4, t * 0.45), 1.0, true)
			draw_line(pts[i] + Vector2(-sz, sz), pts[i] + Vector2(sz, -sz),
					  Color(0.5, 1.0, 0.4, t * 0.45), 1.0, true)
		# Spore necrotiche: puntini che galleggiano
		if i % 9 == 0 and t > 0.2:
			var spore_off := Vector2(cos(float(i) * 2.7), sin(float(i) * 1.9)) * randf_range(4.0, 12.0) * t
			draw_circle(pts[i] + spore_off, randf_range(1.0, 2.0), Color(0.3, 0.9, 0.3, t * 0.4))
	# Core: corona di ossa + nucleo putrescente
	var bone_count := 5
	var bp := sin(_draw_time * 5.0) * 0.4 + 0.6
	for b in range(bone_count):
		var ba := _draw_time * 2.5 + (TAU / bone_count) * b
		var bone_r := 10.0 + bp * 3.0
		var bone_pos := Vector2(cos(ba), sin(ba)) * bone_r
		# Osso: due cerchi con linea
		draw_circle(bone_pos, 2.2, Color(0.4, 0.95, 0.35, 0.75))
		draw_circle(bone_pos * 0.7, 1.5, Color(0.35, 0.85, 0.3, 0.6))
		draw_line(bone_pos * 0.7, bone_pos, Color(0.4, 0.8, 0.3, 0.5), 1.0, true)
	# Nucleo
	draw_circle(Vector2.ZERO, 5.0 * bp, Color(0.0, 0.45, 0.0, 0.9))
	draw_circle(Vector2.ZERO, 2.5, Color(0.5, 1.0, 0.4, 1.0))

# --- RIFT BLADE CORE: cristallo dimensionale affilato con bordi taglienti ---
func _draw_rift_blade_core() -> void:
	# La scia è sul nodo esterno RiftScarDrawer
	# Qui: blade allungata che punta lungo +X (segue direction via node rotation)
	var pulse := sin(_draw_time * 16.0) * 0.5 + 0.5
	var blade_len := 16.0
	var blade_w   := 3.5

	# Alone viola dietro la lama
	var glow_pts := PackedVector2Array([
		Vector2(blade_len * 1.1, 0),
		Vector2(0, blade_w * 1.8),
		Vector2(-blade_len * 0.5, 0),
		Vector2(0, -blade_w * 1.8)
	])
	draw_colored_polygon(glow_pts, Color(0.5, 0.0, 1.0, 0.18 + pulse * 0.12))

	# Corpo lama: rombo affilato
	var blade_pts := PackedVector2Array([
		Vector2(blade_len, 0),
		Vector2(blade_len * 0.15, blade_w * 0.6),
		Vector2(-blade_len * 0.4, 0),
		Vector2(blade_len * 0.15, -blade_w * 0.6)
	])
	draw_colored_polygon(blade_pts, Color(0.35, 0.0, 0.85, 0.92))

	# Bordo incandescente viola
	draw_polyline(blade_pts, Color(0.85, 0.25, 1.0, 0.8 + pulse * 0.2), 1.5, true)

	# Linea di taglio interna (bianca brillante al centro)
	draw_line(Vector2(-blade_len * 0.3, 0), Vector2(blade_len * 0.92, 0),
			  Color(1.0, 1.0, 1.0, 0.55 + pulse * 0.45), 1.2)

	# Micro-scintille al bordo tagliente (punta)
	for sk in range(3):
		var sa := _draw_time * 15.0 + float(sk) * 1.8
		var sp2 := Vector2(blade_len * 0.9, 0) + Vector2(cos(sa), sin(sa)) * (2.0 + pulse * 2.5)
		draw_circle(sp2, 0.8, Color(1.0, 0.7, 1.0, 0.7 + pulse * 0.3))

# --- STORM TRAIL: fulminazione frenetica con ramificazioni reali ---
func _draw_storm_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		# Alone elettrico esterno (giallo-bianco diffuso)
		draw_line(pts[i], pts[i + 1], Color(1.0, 1.0, 0.5, t * 0.2), lerp(4.0, 14.0, t), true)
		# Corpo principale giallo
		draw_line(pts[i], pts[i + 1], Color(1.0, 0.9, 0.0, t * 0.9), lerp(1.5, 5.0, t), true)
		# Linea interna bianca
		draw_line(pts[i], pts[i + 1], Color(1.0, 1.0, 0.8, t * 0.6), lerp(0.5, 2.0, t), true)
		# Archi elettrici con zigzag realistici
		if i % 2 == 0 and t > 0.15 and i + 1 < n:
			var mid := pts[i].lerp(pts[i + 1], 0.5)
			var d := (pts[i + 1] - pts[i]).normalized()
			var perp := Vector2(-d.y, d.x)
			var jitter := perp * randf_range(-10.0, 10.0) * t
			# Bolt principale con kink
			draw_line(pts[i], mid + jitter, Color(1.0, 1.0, 0.4, t * 0.7), 1.0, true)
			draw_line(mid + jitter, pts[i + 1], Color(1.0, 1.0, 0.4, t * 0.7), 1.0, true)
			# Ramificazione secondaria
			if t > 0.45 and i % 4 == 0:
				var branch_end := mid + jitter + perp * randf_range(5.0, 14.0) * t
				draw_line(mid + jitter, branch_end, Color(0.9, 1.0, 0.3, t * 0.4), 0.7, true)
	# Core: nodo di plasma elettrico con stella
	var sp := sin(_draw_time * 22.0) * 0.5 + 0.5
	# Alone diffuso
	draw_circle(Vector2.ZERO, 9.0 + sp * 4.0, Color(1.0, 1.0, 0.2, 0.15))
	# Raggi del nodo — ampiezza variabile e frenetica
	var ray_count := 8
	for r in range(ray_count):
		var ra := (TAU / ray_count) * r + _draw_time * 18.0
		var rl := 5.0 + sin(_draw_time * 25.0 + float(r) * 1.3) * 4.5
		draw_line(Vector2.ZERO, Vector2(cos(ra), sin(ra)) * rl, Color(1.0, 1.0, 0.5, 0.95), 1.5, true)
	draw_circle(Vector2.ZERO, 3.5, Color(1.0, 1.0, 1.0, 1.0))

# --- SWAP TRAIL: portali dimensionali con scia biforcata ---
func _draw_swap_trail() -> void:
	var pts := _to_local_trail()
	var n := pts.size()
	for i in range(n - 1):
		var t := float(i) / float(n)
		var shift := sin(_draw_time * 7.0 + float(i) * 0.5) * 6.0 * (1.0 - t)
		var perp := Vector2.ZERO
		if i + 1 < n and pts[i] != pts[i + 1]:
			var d := (pts[i + 1] - pts[i]).normalized()
			perp = Vector2(-d.y, d.x)
		# Scia A: dimensione corrente (viola)
		draw_line(pts[i] + perp * shift, pts[i + 1] + perp * shift,
				  Color(0.85, 0.15, 1.0, t * 0.85), lerp(1.5, 4.5, t), true)
		# Scia B: dimensione alternata (ciano)
		draw_line(pts[i] - perp * shift, pts[i + 1] - perp * shift,
				  Color(0.15, 0.85, 1.0, t * 0.55), lerp(1.0, 3.5, t), true)
		# Anelli portale lungo la scia ogni 8 punti
		if i % 8 == 0 and t > 0.2:
			var pr := t * 6.0
			var portal_alpha := t * 0.3
			draw_arc(pts[i], pr, 0.0, TAU, 16, Color(0.8, 0.2, 1.0, portal_alpha), 1.0, true)
			draw_arc(pts[i], pr * 0.7, 0.0, TAU, 16, Color(0.2, 0.8, 1.0, portal_alpha), 0.7, true)
	# Core: doppio portale interferente
	var phase := sin(_draw_time * 9.0) * 4.5
	# Portale A
	draw_circle(Vector2(phase, 0), 5.0, Color(0.8, 0.2, 1.0, 0.5))
	draw_arc(Vector2(phase, 0), 5.5, 0.0, TAU, 20, Color(0.9, 0.4, 1.0, 0.7), 1.2, true)
	# Portale B
	draw_circle(Vector2(-phase, 0), 5.0, Color(0.2, 0.8, 1.0, 0.5))
	draw_arc(Vector2(-phase, 0), 5.5, 0.0, TAU, 20, Color(0.4, 0.9, 1.0, 0.7), 1.2, true)
	# Punto di collisione
	draw_circle(Vector2.ZERO, 2.8, Color(1.0, 1.0, 1.0, 0.95))


# ============================================================
# == NODI DRAW ESTERNI (spawned una volta, persistenti)
# ============================================================

# Spawna il nodo RiftScarDrawer quando il rift blade vola
func _ensure_rift_line() -> void:
	if is_instance_valid(_rift_line): return
	_rift_line = _RiftScarDrawer.new()
	_rift_line.persist_time = weapon_info.get("rift_persist_time", 2.0)
	_rift_line.scar_width   = weapon_info.get("rift_width", 40.0)
	_rift_line.scar_dps     = weapon_info.get("rift_scar_dps", 30.0)
	_rift_line.bullet_ref   = self
	get_parent().add_child(_rift_line)

# Spawna il nodo GravitonField quando si ferma
func _ensure_graviton_node() -> void:
	if is_instance_valid(_graviton_field): return
	_graviton_field = _GravitonFieldNode.new()
	_graviton_field.global_position = global_position
	_graviton_field.magnet_radius   = weapon_info.get("magnet_radius", 300.0)
	_graviton_field.duration        = weapon_info.get("magnet_duration", 3.5)
	_graviton_field.tick_rate       = weapon_info.get("magnet_tick_rate", 0.5)
	_graviton_field.tick_dmg        = weapon_info.get("magnet_tick_damage", 7.0)
	_graviton_field.pull_force      = weapon_info.get("magnet_pull_force", 600.0)
	_graviton_field.bullet_ref      = self
	get_parent().add_child(_graviton_field)


# ============================================================
# == CLASSI INTERNE — nodi draw persistenti dopo la morte del bullet
# ============================================================

# --- RiftScarDrawer: scia che persiste sulla mappa ---
class _RiftScarDrawer extends Node2D:
	var world_points: Array[Vector2] = []
	var persist_time: float = 2.0
	var scar_width: float = 40.0
	var scar_dps: float = 30.0
	var _age: float = 0.0
	var bullet_ref: Node = null

	func add_world_point(wp: Vector2) -> void:
		world_points.append(wp)
		if world_points.size() > 200:
			world_points.remove_at(0)
		queue_redraw()

	func _process(delta: float) -> void:
		_age += delta
		# Danno ai nemici sulla scia
		if world_points.size() > 1:
			var enemies := get_tree().get_nodes_in_group("enemy")
			for e in enemies:
				if not (e is Node2D and is_instance_valid(e)): continue
				for wp in world_points:
					if wp.distance_to(e.global_position) < scar_width * 0.5:
						if e.has_method("take_damage"):
							e.take_damage(scar_dps * delta, bullet_ref)
						break
		queue_redraw()
		if _age >= persist_time:
			queue_free()

	func _draw() -> void:
		var n := world_points.size()
		if n < 2: return
		var fade = clamp(1.0 - _age / persist_time, 0.0, 1.0)
		for i in range(n - 1):
			var seg_t := float(i) / float(n)
			var p1 := world_points[i]     - global_position
			var p2 := world_points[i + 1] - global_position
			# Scia principale
			draw_line(p1, p2, Color(0.4, 0.0, 0.9, fade * 0.85), 6.0, true)
			# Bordo luminoso
			draw_line(p1, p2, Color(0.9, 0.4, 1.0, fade * 0.35), 12.0, true)
			# Linea centrale bianca sottile
			draw_line(p1, p2, Color(1.0, 1.0, 1.0, fade * 0.25), 1.5, true)
			# Microtagli trasversali ogni 8 punti
			if i % 8 == 0:
				var d := (p2 - p1).normalized()
				var perp := Vector2(-d.y, d.x) * scar_width * 0.3
				draw_line(p1 - perp, p1 + perp, Color(0.8, 0.2, 1.0, fade * 0.3), 1.0)


# --- GravitonFieldNode: campo magnetico visivo persistente sul posto ---
class _GravitonFieldNode extends Node2D:
	var magnet_radius: float = 300.0
	var duration: float = 3.5
	var tick_rate: float = 0.5
	var tick_dmg: float = 7.0
	var pull_force: float = 600.0
	var bullet_ref: Node = null
	var _age: float = 0.0
	var _tick_t: float = 0.0

	func _process(delta: float) -> void:
		_age += delta
		_tick_t += delta
		# Attrazione e danno nemici
		if _tick_t >= tick_rate:
			_tick_t = 0.0
			var enemies := get_tree().get_nodes_in_group("enemy")
			for e in enemies:
				if not (e is Node2D and is_instance_valid(e)): continue
				var dist := global_position.distance_to(e.global_position)
				if dist > magnet_radius: continue
				var pull_dir = (global_position - e.global_position).normalized()
				if "velocity" in e:
					e.velocity += pull_dir * pull_force * tick_rate
				if e.has_method("take_damage"):
					e.take_damage(tick_dmg, bullet_ref)
					if dist < 30.0:
						e.take_damage(tick_dmg * 4.0, bullet_ref)
		queue_redraw()
		if _age >= duration:
			queue_free()

	func _draw() -> void:
		var fade = clamp(1.0 - _age / duration, 0.0, 1.0)
		var t_alive := _age / duration
		for ring in range(4):
			var phase := fmod(t_alive * 1.2 + float(ring) * 0.25, 1.0)
			var r := magnet_radius * (1.0 - phase)
			var alpha = phase * fade * 0.5
			draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.5, 0.0, 1.0, alpha), 2.0, true)
			if ring == 0:
				var arr_n := 8
				var arr_t := Time.get_ticks_msec() / 1000.0
				for ai in range(arr_n):
					var angle := arr_t * 0.5 + (TAU / arr_n) * ai
					var op := Vector2(cos(angle), sin(angle)) * r
					var ip := op * 0.75
					draw_line(op, ip, Color(0.7, 0.0, 1.0, alpha * 1.3), 1.5)
		var core_pulse := sin(Time.get_ticks_msec() / 100.0) * 3.0 + 8.0
		draw_circle(Vector2.ZERO, core_pulse, Color(0.5, 0.0, 1.0, fade * 0.7))
		draw_circle(Vector2.ZERO, core_pulse * 0.5, Color(1.0, 0.5, 1.0, fade))
		draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 1.0, fade))


# ============================================================
# == init_from_weapon
# ============================================================
func init_from_weapon(weapon_data: Dictionary, shoot_dir: Vector2, p_owner: Node = null, is_child: bool = false) -> void:
	if is_instance_valid(p_owner):
		bullet_owner = p_owner
	else:
		bullet_owner = null

	damage        = weapon_data.get("damage", 5)
	speed         = weapon_data.get("speed", 800)
	fire_rate     = weapon_data.get("fire_rate", 0.25)
	projectile_type = weapon_data.get("projectile_type", "line")
	weapon_info   = weapon_data.duplicate(true)
	weapon_name   = weapon_data.get("name", weapon_name)
	weapon_rarity = weapon_data.get("rarity", weapon_rarity)

	direction = shoot_dir.normalized()
	if direction.length() == 0:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	if speed <= 0:
		speed = 600 * Global.player_bullet_speed

	start_position = global_position
	_spawn_pos     = global_position
	_rift_last_pos = global_position

	var tex_path = weapon_data.get("bullet_texture", "")
	if typeof(tex_path) == TYPE_STRING and tex_path != "":
		base_texture = load(tex_path)
	if base_texture and bullet_sprite:
		bullet_sprite.texture = base_texture

	if not is_child:
		match projectile_type:
			"cone_3":
				for angle in [-15, 15]:
					_spawn_extra(weapon_data, shoot_dir.rotated(deg_to_rad(angle)), bullet_owner)
			"cone_5":
				for angle in [-30, -15, 15, 30]:
					_spawn_extra(weapon_data, shoot_dir.rotated(deg_to_rad(angle)), bullet_owner)
			"boomerang":
				set_meta("original_dir", direction)
				traveled_distance = 0.0
			"homing", "tide_homing", "follow_stop":
				target = find_nearest_enemy()
				if projectile_type == "follow_stop":
					life_timer = 0.0
					max_life   = 0.5
			"explode_after":
				life_timer = 0.0
				max_life   = 1.5
			"wave_split":
				spawned  = false
				max_life = 0.1
			"zigzag", "chain_lightning":
				zigzag_timer   = 0.0
				start_position = global_position
			"dual_beam":
				var offset = Vector2(-direction.y, direction.x) * 20
				var b1 = preload(BULLET_SCENE_PATH).instantiate()
				b1.init_from_weapon(weapon_data, direction, bullet_owner, true)
				b1.projectile_type = weapon_data.get("child_projectile_type", "line")
				b1.global_position = global_position + offset
				get_parent().add_child(b1)
				var b2 = preload(BULLET_SCENE_PATH).instantiate()
				b2.init_from_weapon(weapon_data, direction, bullet_owner, true)
				b2.projectile_type = weapon_data.get("child_projectile_type", "line")
				b2.global_position = global_position - offset
				get_parent().add_child(b2)
				set_physics_process(false)
				call_deferred("queue_free")
			"phantom_echo_shot":
				_echo_spawned = false
			"proximity_mine_shot":
				_is_mine    = false
				_mine_armed = false
			"rift_blade_shot":
				_ensure_rift_line()


func _spawn_extra(weapon_data: Dictionary, dir: Vector2, p_owner: Node) -> void:
	if not is_instance_valid(p_owner): return
	var bullet := preload(BULLET_SCENE_PATH).instantiate()
	bullet.init_from_weapon(weapon_data, dir, p_owner, true)
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	bullet.rotation = dir.angle()


# ============================================================
# == _physics_process
# ============================================================
func _physics_process(delta: float) -> void:
	life_timer += delta

	if projectile_type == "gaea_core_main":
		var core_bullet = load("res://Gres/Scenes/Bullets/gaea_core_bullet.tscn").instantiate()
		get_tree().root.add_child(core_bullet)
		core_bullet.global_position = global_position
		core_bullet.init_from_weapon({"damage": damage, "speed": speed, "fire_rate": fire_rate}, direction, bullet_owner)
		set_physics_process(false)
		call_deferred("queue_free")
		return

	match projectile_type:
		"line", "cone_3", "cone_5", "piercing", "twin", "wave", "trail_line", "blood_nexus_main":
			_move(delta)

		"homing", "tide_homing":
			if target and target.is_inside_tree():
				var dir := (target.global_position - global_position).normalized()
				direction = direction.lerp(dir, 0.08)
			_move(delta)

		"bounce", "seismic_bounce":
			_move(delta)
			_handle_bounce()

		"gaea_core":
			_move(delta)
			if life_timer >= 0.8 and not spawned:
				_spawn_gaea_core_fragments()
				spawned = true
				set_physics_process(false)
				call_deferred("queue_free")

		"gaea_fragment":
			if not spawned:
				_spawn_gaea_fragments()
				spawned = true
				set_physics_process(false)
				call_deferred("queue_free")
			_move(delta)

		"boomerang":
			_move(delta)
			traveled_distance += direction.length() * speed * delta
			if traveled_distance >= return_distance:
				var orig = get_meta("original_dir", null)
				if orig:
					direction = -orig

		"follow_stop":
			if target and target.is_inside_tree() and life_timer < max_life:
				direction = (target.global_position - global_position).normalized()
			_move(delta)

		"explode_after":
			if life_timer >= max_life and not spawned and randi() % 100 < 40:
				spawn_explosion(8)
				spawned = true
				set_physics_process(false)
				call_deferred("queue_free")
			else:
				_move(delta)

		"wave_split":
			if life_timer >= max_life and not spawned:
				split_wave()
				spawned = true
				set_physics_process(false)
				call_deferred("queue_free")
			else:
				_move(delta)

		"zigzag", "chain_lightning":
			zigzag_timer += delta
			var forward = direction.normalized() * speed * delta
			var perp    = Vector2(-direction.y, direction.x)
			var offset  = perp * sin(zigzag_timer * zigzag_frequency) * zigzag_amplitude * delta
			position += forward + offset

		"MeteorShower":
			if life_timer >= max_life and not spawned:
				for i in range(6):
					spawn_meteor(global_position + Vector2(randf_range(-200, 200), -400))
				spawned = true
				set_physics_process(false)
				call_deferred("queue_free")
			else:
				_move(delta)

		"Orbitals":
			if not spawned:
				for i in range(3):
					var player = get_tree().get_first_node_in_group("player")
					if player:
						spawn_orbital(player, i)
				spawned = true
				set_physics_process(false)
				call_deferred("queue_free")

		"DeadLine":
			set_meta("original_dir", direction)
			var phoenix = load("res://Gres/Scenes/weapons/bullet/PhinixBullet.tscn").instantiate()
			get_parent().add_child(phoenix)
			phoenix.global_position = global_position
			phoenix.direction = -direction
			_move(delta)

		"VoidRift":
			_move(delta)
			if rift_timer > 0.2:
				if randi() % 100 < 5:
					var rift = load("res://Gres/Scenes/weapons/bullet/void_rift.tscn").instantiate()
					get_parent().add_child(rift)
					rift.global_position = global_position
				rift_timer = 0.0
			else:
				rift_timer += delta

		"ImplosionBurst":
			_move(delta)
			if collided:
				if not spawned:
					var center = global_position
					for i in range(10):
						var b = load("res://Gres/Scenes/weapons/bullet/implossion_shard.tscn").instantiate()
						get_parent().call_deferred("add_child", b)
						var angle = (TAU / 10) * i
						var spawn_pos = center + Vector2(cos(angle), sin(angle)) * 200
						b.global_position = spawn_pos
						b.direction = (center - spawn_pos).normalized()
					spawned = true
					set_physics_process(false)
					call_deferred("queue_free")
					
			if life_timer >= 2.0:
				if not spawned and randi() % 100 < 30:
					var center = global_position
					for i in range(10):
						var b = load("res://Gres/Scenes/weapons/bullet/implossion_shard.tscn").instantiate()
						get_parent().call_deferred("add_child", b)
						var angle = (TAU / 10) * i
						var spawn_pos = center + Vector2(cos(angle), sin(angle)) * 200
						b.global_position = spawn_pos
						b.direction = (center - spawn_pos).normalized()
					spawned = true
					set_physics_process(false)
					call_deferred("queue_free")

		"piercing_burn":
			_move(delta)

		"nullborn_sovereign_shot":
			_move(delta)
			if life_timer >= 4.0 and not spawned:
				_nullborn_freeze_burst()
				spawned = true
				set_physics_process(false)
				call_deferred("queue_free")

		"oblivion_herald_shot":
			_move(delta)
			if rift_timer >= 0.15:
				_spawn_gravity_trail_node()
				rift_timer = 0.0
			else:
				rift_timer += delta

		"voidfather_eclipse_shot":
			_move(delta)
			if life_timer < 0.05 and is_instance_valid(bullet_owner):
				bullet_owner.apply_buff("invincible", 1.5)
			if life_timer >= 6.0 and not spawned:
				_voidfather_dimensional_collapse()
				spawned = true
				set_physics_process(false)
				call_deferred("queue_free")

		"aegis_storm_shot":
			if target and target.is_inside_tree():
				var dir := (target.global_position - global_position).normalized()
				direction = direction.lerp(dir, 0.10)
			_move(delta)

		"mind_fracture_shot":
			_move(delta)

		"wall_caster_shot":
			_move(delta)

		"proximity_mine_shot":
			if not _is_mine:
				_move(delta)
				if life_timer >= _mine_stop_time:
					_is_mine = true
					speed = 0
					set_deferred("monitoring", true)
					get_tree().create_timer(0.3).timeout.connect(func(): _mine_armed = true)
					# Spawn bounce scale per feedback visivo
					var t := create_tween()
					t.tween_property(bullet_sprite, "scale", Vector2(1.8, 1.8), 0.12).set_trans(Tween.TRANS_BOUNCE)
					t.tween_property(bullet_sprite, "scale", Vector2(1.3, 1.3), 0.1)
			else:
				if _mine_armed:
					_check_mine_proximity()
				if life_timer >= 12.0:
					queue_free()

		"graviton_pulse_shot":
			if life_timer < 0.3:
				_move(delta)
			else:
				speed = 0
				# Spawn nodo campo gravitazionale (una volta sola)
				if not _graviton_spawned:
					_graviton_spawned = true
					_ensure_graviton_node()
					# Questo bullet non fa più niente — il nodo GravitonFieldNode gestisce tutto
					set_physics_process(false)
					set_process(false)
					call_deferred("queue_free")

		"phantom_echo_shot":
			_move(delta)
			var echo_delay: float = weapon_info.get("echo_delay", 0.3)
			var echo_count: int   = weapon_info.get("echo_count", 3)
			if life_timer >= echo_delay and not _echo_spawned:
				_echo_spawned = true
				for i in range(echo_count):
					await get_tree().create_timer(echo_delay * 0.5 * i).timeout
					if not is_instance_valid(self) or not is_inside_tree(): break
					var echo_data = weapon_info.duplicate(true)
					echo_data["projectile_type"] = "line"
					echo_data["damage"] = int(damage * weapon_info.get("echo_damage_mult", 0.75))
					var b = preload(BULLET_SCENE_PATH).instantiate()
					b.init_from_weapon(echo_data, direction, bullet_owner, true)
					get_parent().add_child(b)
					b.global_position = global_position
					b.rotation = rotation
					b.modulate = Color(0.6, 0.6, 1.0, 0.7 - i * 0.15)

		"chrono_ripper_shot":
			_move(delta)

		"soul_leech_shot":
			_move(delta)

		"entropy_cannon_shot":
			_move(delta)
			if rift_timer >= 0.05:
				var trail_dmg: float = weapon_info.get("trail_damage", 8.0)
				for e in get_tree().get_nodes_in_group("enemy"):
					if not (e is Node2D): continue
					if global_position.distance_to(e.global_position) < 20.0:
						if e.has_method("take_damage"):
							e.take_damage(trail_dmg, self)
				rift_timer = 0.0
			else:
				rift_timer += delta

		"necro_pulse_shot":
			_move(delta)

		"rift_blade_shot":
			_move(delta)
			if rift_timer >= 0.06:
				_spawn_rift_scar_segment()
				rift_timer = 0.0
			else:
				rift_timer += delta

		"storm_caller_shot":
			_move(delta)

		"dimensional_swap_shot":
			_move(delta)

	if is_out_of_screen(400):
		set_physics_process(false)
		call_deferred("queue_free")


# ============================================================
# == HELPER NUOVE ARMI (identici alla versione precedente)
# ============================================================

func _check_mine_proximity() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D and is_instance_valid(e)): continue
		if global_position.distance_to(e.global_position) <= _mine_trigger_radius:
			_mine_explode()
			return

func _mine_explode() -> void:
	if not is_instance_valid(self) or not is_inside_tree(): return
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D and is_instance_valid(e)): continue
		if global_position.distance_to(e.global_position) <= _mine_explosion_radius:
			if e.has_method("take_damage"):
				e.take_damage(damage, self)
	# Flash esplosione: cerchio bianco che si espande via draw (nodo temporaneo)
	var flash := _ExplosionFlash.new()
	flash.global_position = global_position
	flash.radius_max = _mine_explosion_radius
	get_parent().add_child(flash)
	set_physics_process(false)
	call_deferred("queue_free")


# --- Nodo interno per il flash esplosione mina ---
class _ExplosionFlash extends Node2D:
	var radius_max: float = 200.0
	var _age: float = 0.0
	var _dur: float = 0.35
	func _process(delta: float) -> void:
		_age += delta
		queue_redraw()
		if _age >= _dur: queue_free()
	func _draw() -> void:
		var t := _age / _dur
		var r  := radius_max * ease(t, -2.0)
		var a  := 1.0 - t
		draw_circle(Vector2.ZERO, r,       Color(1.0, 0.3, 0.0, a * 0.25))
		draw_arc(Vector2.ZERO,    r, 0, TAU, 48, Color(1.0, 0.6, 0.0, a * 0.7), 3.0, true)
		draw_circle(Vector2.ZERO, r * 0.3, Color(1.0, 1.0, 0.8, a * 0.5))


func _graviton_tick(delta: float) -> void:
	pass  # gestito da _GravitonFieldNode

func _spawn_rift_scar_segment() -> void:
	_ensure_rift_line()
	var scar_dps: float   = weapon_info.get("rift_scar_dps", 30.0)
	var scar_width: float = weapon_info.get("rift_width", 40.0)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D and is_instance_valid(e)): continue
		if global_position.distance_to(e.global_position) < scar_width * 0.5:
			if e.has_method("take_damage"):
				e.take_damage(scar_dps * 0.06, self)
			if e.has_method("apply_buff"):
				e.apply_buff("no_dodge", 0.3)

func _apply_chrono_field(hit_pos: Vector2) -> void:
	var field_radius: float  = weapon_info.get("time_field_radius", 150.0)
	var slow_duration: float = weapon_info.get("slow_duration", 3.0)
	var slow_amount: float   = weapon_info.get("slow_amount", 0.15)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D and is_instance_valid(e)): continue
		if hit_pos.distance_to(e.global_position) <= field_radius:
			if e.has_method("apply_buff"):
				e.apply_buff("slowed", slow_duration, {"amount": slow_amount})

func _apply_soul_leech(amount_dealt: float) -> void:
	if not is_instance_valid(bullet_owner): return
	if randi() % 100 < 15:
		var leech_pct: float    = weapon_info.get("leech_percent", 0.15)
		var overheal: bool      = weapon_info.get("leech_overheal", true)
		var overheal_max: float = weapon_info.get("leech_overheal_max", 1.20)
		var restored := amount_dealt * leech_pct
		var cap := Global.player_max_hp * (overheal_max if overheal else 1.0)
		Global.player_hp = min(Global.player_hp + restored, cap)

func _get_entropy_damage_mult() -> float:
	var dist_traveled := _spawn_pos.distance_to(global_position)
	var max_range: float = weapon_info.get("max_range_px", 800.0)
	var min_mult: float  = weapon_info.get("min_range_bonus", 0.5)
	var max_mult: float  = weapon_info.get("max_range_bonus", 3.0)
	return lerp(min_mult, max_mult, clamp(dist_traveled / max_range, 0.0, 1.0))

func _apply_mind_fracture_effects(body: Node) -> void:
	var poison_chance: int  = weapon_info.get("poison_chance", 20)
	var control_chance: int = weapon_info.get("control_chance", 30)
	var control_duration: float = weapon_info.get("control_duration", 10.0)
	var hp_drain: float = weapon_info.get("control_hp_drain", 10.0)
	if randi() % 100 < poison_chance:
		if body.has_method("apply_buff"):
			body.apply_buff("burn", 4.0, {"dps": damage * 0.1, "interval": 1.0})
	if randi() % 100 < control_chance:
		if body.has_method("_become_ally"):
			body._become_ally(control_duration)
		elif body.has_method("apply_buff"):
			body.apply_buff("mind_controlled", control_duration, {
				"dps": body.max_hp * (hp_drain / 100.0), "interval": 1.0
			})

func _apply_chain_lightning(origin: Node) -> void:
	var lightning_chance: int   = weapon_info.get("lightning_chance", 20)
	if randi() % 100 >= lightning_chance: return
	var chain_count: int        = weapon_info.get("lightning_chain", 3)
	var chain_decay: float      = weapon_info.get("lightning_chain_decay", 0.7)
	var lightning_dmg: float    = weapon_info.get("lightning_damage", 40.0 * Global.player_damage)
	var enemies := get_tree().get_nodes_in_group("enemy")
	enemies.shuffle()
	var hit_targets: Array = [origin]
	var chain_points: Array[Vector2] = [origin.global_position]
	var current_dmg := lightning_dmg
	for e in enemies:
		if hit_targets.size() > chain_count: break
		if not (e is Node2D and is_instance_valid(e)): continue
		if e in hit_targets: continue
		if e.has_method("take_damage"):
			e.take_damage(current_dmg, self)
		hit_targets.append(e)
		chain_points.append(e.global_position)
		current_dmg *= chain_decay
	# Spawna il fulmine visivo
	if chain_points.size() >= 2:
		var bolt := _LightningBolt.new()
		bolt.pts = chain_points
		get_parent().add_child(bolt)


# --- Nodo interno per il fulmine ---
class _LightningBolt extends Node2D:
	var pts: Array[Vector2] = []
	var _age: float = 0.0
	var _dur: float = 0.18
	var _jitter: Array = []
	func _ready() -> void:
		for i in range(pts.size() - 1):
			var segs: Array[Vector2] = []
			var p1 := pts[i]; var p2 := pts[i + 1]
			var steps := 8
			for s in range(steps + 1):
				var t := float(s) / float(steps)
				var base := p1.lerp(p2, t)
				var perp := (p2 - p1).orthogonal().normalized()
				var off := perp * randf_range(-14.0, 14.0) * sin(t * PI)
				segs.append(base + off)
			_jitter.append(segs)
	func _process(delta: float) -> void:
		_age += delta
		queue_redraw()
		if _age >= _dur: queue_free()
	func _draw() -> void:
		var a := 1.0 - _age / _dur
		for seg_pts in _jitter:
			for i in range(seg_pts.size() - 1):
				var p1: Vector2 = seg_pts[i]     - global_position
				var p2: Vector2 = seg_pts[i + 1] - global_position
				draw_line(p1, p2, Color(1.0, 1.0, 1.0, a * 0.9), 2.5, true)
				draw_line(p1, p2, Color(1.0, 0.9, 0.2, a * 0.6), 6.0, true)
		# Punti di impatto
		for p in pts:
			draw_circle(p - global_position, 5.0 * a, Color(1.0, 1.0, 0.5, a * 0.8))


func _apply_necro_revive(body: Node) -> void:
	if randi() % 100 >= weapon_info.get("revive_chance", 25): return
	if not is_instance_valid(body): return
	var revive_duration: float = weapon_info.get("revive_duration", 8.0)
	var revive_hp_pct: float   = weapon_info.get("revive_hp_percent", 0.30)
	if "group" in body:
		body.group = "enemy"
		body.hp = int(body.max_hp * revive_hp_pct)
		body.not_dead = true
		body.can_shoot = true
		body.can_move = true
		body.can_follow = true
		body.is_revived = true
		body.modulate = Color(0.3, 0.9, 0.4, 0.85)
		get_tree().create_timer(revive_duration).timeout.connect(func():
			if is_instance_valid(body):
				body.modulate = Color.WHITE
				var explo_dmg = body.max_hp * 1.0
				for e2 in get_tree().get_nodes_in_group("enemy"):
					if not (e2 is Node2D and is_instance_valid(e2)): continue
					if body.global_position.distance_to(e2.global_position) < 150.0:
						if e2.has_method("take_damage"):
							e2.take_damage(explo_dmg, null)
				body.die()
		)

func _apply_dimensional_swap(body: Node) -> void:
	if randi() % 100 >= weapon_info.get("swap_chance", swap_percent): return
	if not is_instance_valid(bullet_owner): return
	var player_pos = bullet_owner.global_position
	var enemy_pos  = body.global_position
	# Portal visivo su entrambe le posizioni
	for pos in [player_pos, enemy_pos]:
		var portal := _SwapPortal.new()
		portal.global_position = pos
		get_parent().add_child(portal)
	bullet_owner.global_position = enemy_pos
	bullet_owner.apply_buff("invincible", weapon_info.get("swap_invincible_time", 0.8))
	body.global_position = player_pos
	if body.has_method("apply_buff"):
		body.apply_buff("frozen", weapon_info.get("swap_stun_duration", 1.5))
	var stacks: int = bullet_owner.get_meta("swap_power_stacks", 0)
	bullet_owner.set_meta("swap_power_stacks", stacks + 3)


# --- Nodo interno portale swap ---
class _SwapPortal extends Node2D:
	var _age: float = 0.0
	var _dur: float = 0.4
	func _process(delta: float) -> void:
		_age += delta
		queue_redraw()
		if _age >= _dur: queue_free()
	func _draw() -> void:
		var t := _age / _dur
		var r: float
		if t < 0.5:
			r = ease(t * 2.0, -2.5) * 70.0
		else:
			r = (1.0 - ease((t - 0.5) * 2.0, 2.5)) * 70.0
		var a := sin(t * PI)
		draw_circle(Vector2.ZERO, r * 0.65, Color(0.4, 0.0, 0.8, a * 0.2))
		draw_arc(Vector2.ZERO, r,       0, TAU, 48, Color(0.8, 0.2, 1.0, a * 0.9), 4.0, true)
		draw_arc(Vector2.ZERO, r * 0.7, 0, TAU, 32, Color(0.3, 0.7, 1.0, a * 0.6), 2.0, true)
		var cross := r * 0.3
		draw_line(Vector2(-cross, 0), Vector2(cross, 0), Color(1.0, 1.0, 1.0, a), 2.0)
		draw_line(Vector2(0, -cross), Vector2(0, cross), Color(1.0, 1.0, 1.0, a), 2.0)


func _try_spawn_wall() -> void:
	var wall_chance: int = weapon_info.get("wall_chance", 10)
	if randi() % 100 >= wall_chance: return
	var wall_duration: float = weapon_info.get("wall_duration", 4.0)
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player): return
	var wall_pos = player.global_position + player.transform.x * 80.0
	if ResourceLoader.exists("res://Gres/Scenes/weapons/void_wall.tscn"):
		var wall = load("res://Gres/Scenes/weapons/void_wall.tscn").instantiate()
		get_tree().current_scene.add_child(wall)
		wall.global_position = wall_pos
		wall.rotation = player.rotation
		get_tree().create_timer(wall_duration).timeout.connect(func():
			if is_instance_valid(wall): wall.queue_free()
		)

# ============================================================
# == COLLISIONI
# ============================================================

# Add this helper function at the top of your functions section
func _deal_damage(body: Node, amount: float) -> void:
	if not body.has_method("take_damage"):
		return
	
	# Check if the method expects a second argument
	var method_info = body.get_method_list()
	var takes_source = false
	for method in method_info:
		if method["name"] == "take_damage":
			takes_source = method["args"].size() > 1
			break
	
	if takes_source:
		body.take_damage(amount, self)
	else:
		body.take_damage(amount)

func _on_body_entered(body: Node) -> void:
	if not body: return

	if body.is_in_group("enemy") and body.has_method("take_damage"):
		var actual_damage: float = damage
		if projectile_type == "entropy_cannon_shot":
			actual_damage *= _get_entropy_damage_mult()
		if is_instance_valid(bullet_owner) and bullet_owner.has_meta("swap_power_stacks"):
			var stacks: int = bullet_owner.get_meta("swap_power_stacks", 0)
			if stacks > 0:
				actual_damage *= 2.0
				bullet_owner.set_meta("swap_power_stacks", stacks - 1)

		if randf() < GlobalStats.huge_dmg / 100.0:
			var dmg = body.max_hp * 0.5
			_deal_damage(body, dmg)
			if randi() % 100 < 10:
				Global.player_hp += dmg / 8
				if Global.player_hp >= Global.player_max_hp:
					Global.player_hp = Global.player_max_hp
				var effect_scene = load("res://Gres/Scenes/Effects/hp_drain.tscn")
				var effect = effect_scene.instantiate()
				get_parent().add_child(effect)
				effect.global_position = global_position

		if randi() % 100 < GlobalStats.critical:
			var crit_dmg = actual_damage * GlobalStats.critical_damage
			_deal_damage(body, crit_dmg)
			if Global.enemy_type == "enemy":
				GlobalStats.damage_inf_mob_lvl += crit_dmg
				GlobalStats.damage_inf_mob_total += crit_dmg
			if Global.enemy_type == "mini_boss":
				GlobalStats.damage_inf_miniboss_lvl += crit_dmg
				GlobalStats.damage_inf_miniboss_total += crit_dmg
			GlobalStats.damage_inf_total_lvl += crit_dmg
			GlobalStats.damage_inf_total += crit_dmg
			if randi() % 100 < 40 and GlobalStats.critical_vampire:
				Global.player_hp += 3
		else:
			_deal_damage(body, actual_damage)
			if Global.enemy_type == "enemy":
				GlobalStats.damage_inf_mob_lvl += actual_damage
				GlobalStats.damage_inf_mob_total += actual_damage
			if Global.enemy_type == "mini_boss":
				GlobalStats.damage_inf_miniboss_lvl += actual_damage
				GlobalStats.damage_inf_miniboss_total += actual_damage
			GlobalStats.damage_inf_total_lvl += actual_damage
			GlobalStats.damage_inf_total += actual_damage

		if projectile_type == "ImplosionBurst": collided = true

		if projectile_type == "nullborn_sovereign_shot" and not spawned:
			_nullborn_freeze_burst(); spawned = true
			set_physics_process(false); call_deferred("queue_free"); return

		if projectile_type == "oblivion_herald_shot" and not spawned:
			_oblivion_black_hole(); spawned = true
			set_physics_process(false); call_deferred("queue_free"); return

		if projectile_type == "voidfather_eclipse_shot" and not spawned:
			_voidfather_dimensional_collapse(); spawned = true
			set_physics_process(false); call_deferred("queue_free"); return

		if projectile_type == "mind_fracture_shot" and not _mind_effect_applied:
			_mind_effect_applied = true
			_apply_mind_fracture_effects(body)

		if projectile_type == "wall_caster_shot":
			_try_spawn_wall()

		if projectile_type == "chrono_ripper_shot" and not _chrono_field_applied:
			_chrono_field_applied = true
			_apply_chrono_field(global_position)

		if projectile_type == "soul_leech_shot":
			_apply_soul_leech(actual_damage)

		if projectile_type == "necro_pulse_shot":
			get_tree().create_timer(0.05).timeout.connect(func():
				if is_instance_valid(body) and body.get("hp") != null and body.hp <= 0:
					_apply_necro_revive(body)
			)

		if projectile_type == "storm_caller_shot":
			_apply_chain_lightning(body)

		if projectile_type == "dimensional_swap_shot" and not _swap_done:
			_swap_done = true
			_apply_dimensional_swap(body)

		if projectile_type == "entropy_cannon_shot":
			var dist_traveled := _spawn_pos.distance_to(global_position)
			var max_range: float = weapon_info.get("max_range_px", 800.0)
			if dist_traveled >= max_range * 0.9:
				if body.has_method("apply_buff"):
					body.apply_buff("frozen", 1.0)
					body.apply_buff("slowed", 3.0, {"amount": 0.6})
		
		# ========== NUOVO: catena Herald Judgment ==========
		if not has_meta("chain_triggered"):
			var source = bullet_owner
			if is_instance_valid(source) and source.has_meta("herald_judgment_active"):
				if body.has_method("has_buff") and body.has_buff("marked"):
					set_meta("chain_triggered", true)
					var chain_damage = actual_damage * 0.7
					for enemy in get_tree().get_nodes_in_group("marked"):
						if enemy != body and enemy.has_method("has_buff") and enemy.has_buff("marked"):
							_deal_damage(enemy, chain_damage)
		# ===================================================
	 
		if projectile_type != "piercing_burn":
			queue_free()
		return

	if body.is_in_group("chest") and body.has_method("open"):
		body.open()
		if projectile_type != "piercing_burn": queue_free()
		return

	if body.is_in_group("e_base") and body.has_method("damage"):
		body.damage()
		if projectile_type != "piercing_burn": queue_free()
		return

	if body.has_method("apply_burn"):
		body.apply_burn(damage, 1.5)
	
	else: queue_free()


func _on_area_shape_entered(_a, area: Area2D, _b, _c) -> void:
	if area.is_in_group("chest") and area.has_method("open"):
		area.open()
		queue_free()

func _on_killer_timeout() -> void:
	queue_free()


# ============================================================
# == VOID WEAPON HELPERS ORIGINALI
# ============================================================
func _nullborn_freeze_burst() -> void:
	# Usa call_deferred per disabilitare la collisione in modo sicuro
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	var freeze_radius := 300.0
	
	# Applica effetti ai nemici nel raggio
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D): 
			continue
		if global_position.distance_to(e.global_position) > freeze_radius: 
			continue
		if e.has_method("apply_buff"): 
			e.apply_buff("frozen", 3.5)
		if e.has_method("take_damage"): 
			e.take_damage(damage * 0.5, self)
	
	# Crea i proiettili shard
	for i in range(24):
		var shard = preload("res://Gres/Scenes/weapons/bullet/player_bullet_ice_shard.tscn").instantiate()
		var angle = (TAU / 24.0) * i
		var shard_dir := Vector2(cos(angle), sin(angle))
		shard.init_from_weapon(
			{"damage": damage * 0.4, "speed": speed * 0.85,
			 "bullet_texture": weapon_info.get("bullet_texture", ""),
			 "projectile_type": "homing"}, shard_dir, bullet_owner, true)
		shard.target = find_nearest_enemy()
		
		# Aggiungi il proiettile in modo sicuro usando call_deferred se necessario
		if get_parent():
			# Se stai ancora elaborando segnali fisici, usa call_deferred
			get_parent().call_deferred("add_child", shard)
		else:
			call_deferred("add_child", shard)
		
		shard.global_position = global_position

func _spawn_gravity_trail_node() -> void:
	var trail_radius := 120.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D): continue
		if global_position.distance_to(e.global_position) > trail_radius: continue
		if e.has_method("apply_buff"):  e.apply_buff("slowed", 2.2, {"amount": 0.4})
		if e.has_method("take_damage"): e.take_damage(15.0 * 0.1, self)

func _oblivion_black_hole() -> void:
	var bh_radius := 500.0; var pull_force := 1200.0
	var bh_dps := 80.0; var bh_duration := 2.8; var hp_per_kill := 12.0
	var center := global_position
	var tick_count := int(bh_duration / 0.1)
	for _tick in range(tick_count):
		await get_tree().create_timer(0.1).timeout
		for e in get_tree().get_nodes_in_group("enemy"):
			if not (e is Node2D and is_instance_valid(e)): continue
			var dist := center.distance_to(e.global_position)
			if dist > bh_radius: continue
			var pull_dir = (center - e.global_position).normalized()
			if "velocity" in e: e.velocity += pull_dir * pull_force * 0.1
			if e.has_method("take_damage"):
				var hp_before: float = e.hp
				e.take_damage(bh_dps * 0.1, self)
				if e.hp <= 0 and hp_before > 0 and is_instance_valid(bullet_owner):
					Global.player_hp = min(Global.player_hp + hp_per_kill, Global.player_max_hp)

func _voidfather_dimensional_collapse() -> void:
	var collapse_radius := 500.0
	var hp_bonus_dmg := 0.0
	if is_instance_valid(bullet_owner):
		var hp_cost := Global.player_hp * 0.05
		hp_bonus_dmg = min(hp_cost * 1.4, 150.0)
		Global.player_hp = max(Global.player_hp - hp_cost, 1.0)
		bullet_owner.apply_buff("invincible", 1.5)
	var total_damage = damage + hp_bonus_dmg
	var kill_count = 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D and is_instance_valid(e)): continue
		if global_position.distance_to(e.global_position) > collapse_radius: continue
		if "type" in e and e.type == "boss":
			if e.has_method("take_damage"): e.take_damage(e.max_hp * 0.2, self)
		else:
			if e.has_method("take_damage"): e.take_damage(e.max_hp / 2, self)
			kill_count += 1
	if is_instance_valid(bullet_owner):
		var stacks: int = bullet_owner.get_meta("void_empowerment", 0)
		bullet_owner.set_meta("void_empowerment", min(stacks + kill_count, 50))


# ============================================================
# == HELPERS BASE
# ============================================================
func _move(delta: float) -> void:
	position += direction.normalized() * speed * delta

func is_out_of_screen(margin: int = 200) -> bool:
	var cam := get_viewport().get_camera_2d()
	if not cam: return false
	var vp_size := get_viewport_rect().size * cam.zoom
	var half    := vp_size * 0.5
	var screen_rect := Rect2(cam.global_position - half, vp_size)
	return not screen_rect.grow(margin).has_point(global_position)

func find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var min_dist := INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D): continue
		var d := global_position.distance_to(e.global_position)
		if d < min_dist: min_dist = d; nearest = e
	return nearest

func spawn_explosion(count: int = 8) -> void:
	if not is_instance_valid(bullet_owner): return
	for i in range(count):
		var angle := deg_to_rad((360 / count) * i)
		var dir := Vector2.RIGHT.rotated(angle)
		var bullet := preload(BULLET_SCENE_PATH).instantiate()
		bullet.init_from_weapon(
			{"damage": damage, "speed": speed,
			 "bullet_texture": base_texture.resource_path if base_texture else "",
			 "projectile_type": "line"}, dir, bullet_owner, true)
		get_parent().add_child(bullet)
		bullet.global_position = global_position

func split_wave() -> void:
	if not is_instance_valid(bullet_owner): return
	for a in [-30, -15, 15, 30]:
		var dir := direction.rotated(deg_to_rad(a))
		var bullet := preload(BULLET_SCENE_PATH).instantiate()
		bullet.init_from_weapon(
			{"damage": damage, "speed": speed,
			 "bullet_texture": base_texture.resource_path if base_texture else "",
			 "projectile_type": "line"}, dir, bullet_owner, true)
		get_parent().add_child(bullet)
		bullet.global_position = global_position

func _spawn_gaea_fragments() -> void:
	if not is_instance_valid(bullet_owner) or not bullet_owner.is_inside_tree(): return
	var count = bullet_owner.get_meta("gaea_fragments_count", 6)
	var frag_path := "res://Gres/Scenes/Bullets/gaea_fragment.tscn"
	for i in range(count):
		var frag_scene = load(frag_path)
		if not frag_scene: continue
		var frag = frag_scene.instantiate()
		bullet_owner.add_child(frag)
		var spawn_offset = Vector2(cos((TAU / float(count)) * float(i)), sin((TAU / float(count)) * float(i))) * 88.0
		frag.global_position = bullet_owner.global_position + spawn_offset
		frag.call_deferred("init_fragment", bullet_owner, (TAU / float(count)) * float(i), 80.0, 1.5, damage)

func _spawn_gaea_core_fragments() -> void:
	if not is_instance_valid(bullet_owner) or not bullet_owner.is_inside_tree(): return
	var frag_path := "res://Gres/Scenes/Bullets/gaea_fragment.tscn"
	for i in range(6):
		var frag_scene = load(frag_path)
		var frag = frag_scene.instantiate()
		bullet_owner.add_child(frag)
		frag.global_position = bullet_owner.global_position
		frag.call_deferred("init_fragment", bullet_owner, (TAU / 6.0) * float(i), 80.0, 1.5, damage)

func spawn_meteor(pos: Vector2) -> void:
	var meteor_scene = load("res://Gres/Scenes/Projectiles/meteor.tscn")
	var meteor = meteor_scene.instantiate()
	get_parent().add_child(meteor)
	meteor.global_position = pos

func spawn_orbital(player: Node2D, index: int) -> void:
	if not is_instance_valid(player): return
	var orbital_scene = load("res://Gres/Scenes/weapons/bullet/orbital.tscn")
	var orbital = orbital_scene.instantiate()
	player.add_child(orbital)
	orbital.start_angle = index * 120

func _handle_bounce() -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var vp_size := get_viewport_rect().size * cam.zoom
	var half    := vp_size * 0.5
	var bounds  := Rect2(cam.global_position - half, vp_size)
	var bounced := false
	if global_position.x <= bounds.position.x or global_position.x >= bounds.position.x + bounds.size.x:
		direction.x = -direction.x; bounced = true
	if global_position.y <= bounds.position.y or global_position.y >= bounds.position.y + bounds.size.y:
		direction.y = -direction.y; bounced = true
	if bounced and projectile_type == "seismic_bounce":
		speed *= 0.9
		_spawn_seismic_wave()

func _spawn_seismic_wave() -> void:
	if not ResourceLoader.exists("res://Gres/Scenes/Effects/SeismicWave.tscn"): return
	var w = preload("res://Gres/Scenes/Effects/SeismicWave.tscn").instantiate()
	w.global_position = global_position
	get_tree().current_scene.add_child(w)
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.global_position.distance_to(global_position) < 120:
			if e.has_method("take_damage"): e.take_damage(damage * 0.8)
