extends Control

@export var player_path: NodePath
@export var enemy_group: String = "enemy"

var player: Node2D

# ============================================================
# PARAMETRI ESPORTABILI – ANIMAZIONI PRINCIPALI
# ============================================================
@export_category("Sweep Radar")
@export_range(0.1, 10.0) var sweep_speed: float = 2.0
@export var sweep_color: Color = Color(0.2, 1.0, 0.3, 0.6)
@export_range(1, 8) var sweep_trail_segments: int = 4          # numero di code della linea sweep
@export var sweep_line_width: float = 2.0

@export_category("Anelli Ping")
@export_range(0.1, 5.0) var ping_interval: float = 2.5
@export_range(0.5, 5.0) var ping_lifetime: float = 1.5
@export var ping_color: Color = Color(0.3, 0.8, 1.0, 0.5)
@export_range(0.5, 5.0) var ping_thickness: float = 2.5

@export_category("Sfondo & Griglia")
@export var bg_color: Color = Color(0, 0, 0, 0.3)
@export var grid_color: Color = Color(0.2, 0.6, 0.8, 0.15)
@export_range(0.5, 3.0) var grid_pulse_speed: float = 3.0
@export_range(0.0, 1.0) var grid_pulse_amount: float = 0.02
@export_range(0.1, 1.0) var grid_line_count: int = 3        # quanti cerchi interni fissi
@export var border_color: Color = Color(1, 1, 1, 0.6)
@export_range(0.5, 3.0) var border_glow_speed: float = 5.0
@export_range(0.0, 1.0) var border_glow_amount: float = 0.2

@export_category("Effetti Tecnologici")
@export var crt_scan_lines: bool = true
@export var scan_line_color: Color = Color(1, 1, 1, 0.05)
@export_range(0.5, 5.0) var scan_line_speed: float = 1.0
@export var glitch_enabled: bool = true
@export_range(0.0, 1.0) var glitch_intensity: float = 0.1
@export_range(0.1, 5.0) var glitch_interval: float = 1.8

@export_category("Icone – Giocatore")
@export var player_color: Color = Color(0.2, 0.6, 1.0)
@export_range(1.0, 8.0) var player_size: float = 4.0
@export_range(0.5, 2.0) var player_halo_size: float = 5.5
@export_range(1.0, 10.0) var player_pulse_speed: float = 6.0

@export_category("Icone – Nemici")
@export var enemy_color: Color = Color(1, 0.2, 0.2)
@export_range(1.0, 6.0) var enemy_size: float = 3.0
@export_range(0.5, 2.0) var enemy_halo_size: float = 5.0
@export_range(1.0, 15.0) var enemy_threat_pulse_speed: float = 8.0

@export_category("Icone – Altri Oggetti")
@export var chest_color: Color = Color(1, 1, 0.2)
@export_range(1.0, 10.0) var star_outer_radius: float = 5.0
@export_range(0.5, 5.0) var star_inner_radius: float = 2.0

@export var enemy_base_color: Color = Color(1.0, 0.0, 0.5)
@export_range(1.0, 8.0) var enemy_base_size: float = 4.0

@export var player_base_color: Color = Color(0.0, 1.0, 0.3)
@export_range(2.0, 12.0) var player_base_triangle_size: float = 6.0

@export var bonus_color: Color = Color(0.0, 1.0, 1.0)
@export_range(1.0, 8.0) var bonus_diamond_size: float = 4.0

@export var boss_color: Color = Color(0.9, 0.9, 0.9)
@export_range(3.0, 12.0) var boss_skull_size: float = 6.0
@export var boss_eye_color: Color = Color(1, 0, 0)

@export var dungeon_color: Color = Color(0.5, 0.3, 0.7)
@export_range(3.0, 12.0) var dungeon_skull_size: float = 6.0

# ============================================================
# VARIABILI INTERNE
# ============================================================
var _angle: float = 0.0
var _ping_timer: float = 0.0
var _pings: Array[float] = []
var _global_time: float = 0.0
var _glitch_offset: Vector2 = Vector2.ZERO
var _glitch_timer: float = 0.0

func _ready() -> void:
	if player_path != NodePath():
		player = get_node(player_path)
	queue_redraw()

func _process(delta: float) -> void:
	_global_time += delta
	_angle += delta * sweep_speed
	if _angle > TAU: _angle -= TAU

	# Anelli di ping
	_ping_timer += delta
	if _ping_timer >= ping_interval:
		_ping_timer -= ping_interval
		_pings.append(_global_time)

	for i in range(_pings.size()-1, -1, -1):
		if _global_time - _pings[i] > ping_lifetime:
			_pings.remove_at(i)

	# Glitch casuale
	if glitch_enabled:
		_glitch_timer += delta
		if _glitch_timer > glitch_interval:
			_glitch_timer = 0.0
			_glitch_offset = Vector2(randf_range(-glitch_intensity, glitch_intensity),
									 randf_range(-glitch_intensity, glitch_intensity)) * 10.0
		else:
			_glitch_offset = lerp(_glitch_offset, Vector2.ZERO, delta * 5.0)

	queue_redraw()

func _draw() -> void:
	if not player:
		return

	var base_radius = Global.radar_radius
	var center = Vector2.ZERO + _glitch_offset   # spostamento glitch globale

	# ========== SFONDO ==========
	draw_circle(center, base_radius * (1.0 + sin(_global_time * grid_pulse_speed) * grid_pulse_amount), bg_color)

	# Griglia concentrica pulsante
	for i in range(1, grid_line_count + 1):
		var r = base_radius * (i / float(grid_line_count + 1))
		draw_arc(center, r, 0, TAU, 32, grid_color, 1.0)

	# Bordo esterno con glow intermittente
	var edge_alpha = 0.6 + sin(_global_time * border_glow_speed) * border_glow_amount
	draw_arc(center, base_radius, 0, TAU, 64, Color(border_color, edge_alpha), 2.0)

	# Scanlines orizzontali (effetto CRT)
	if crt_scan_lines:
		var scan_offset = fmod(_global_time * scan_line_speed * base_radius, base_radius * 2)
		for y in range(-int(base_radius), int(base_radius), 4):
			var y_shifted = y + scan_offset
			if abs(y_shifted) < base_radius:
				var x_limit = sqrt(base_radius*base_radius - y_shifted*y_shifted)
				draw_line(center + Vector2(-x_limit, y_shifted), center + Vector2(x_limit, y_shifted), scan_line_color, 1.0)

	# ========== SWEEP LINE ==========
	_draw_sweep_line(center, base_radius)

	# ========== ANELLI PING ==========
	for ping_start in _pings:
		var age = _global_time - ping_start
		var t = age / ping_lifetime
		var r = base_radius * t
		var alpha = 1.0 - t
		draw_arc(center, r, 0, TAU, 48, Color(ping_color, alpha), ping_thickness)

	# ========== ICONE ==========
	# Giocatore (centro) con alone pulsante
	var player_pulse = 1.0 + sin(_global_time * player_pulse_speed) * 0.3
	draw_circle(center, player_size * player_pulse, player_color)
	draw_circle(center, player_halo_size * player_pulse, Color(player_color, 0.3))

	# Nemici
	for enemy in get_tree().get_nodes_in_group(enemy_group):
		if enemy is Node2D:
			var pos = center + _to_radar_pos(enemy.global_position)
			var threat = 1.0 + sin(_global_time * enemy_threat_pulse_speed + pos.x * 0.1) * 0.2
			draw_circle(pos, enemy_size * threat, enemy_color)
			draw_circle(pos, enemy_halo_size * threat, Color(enemy_color, 0.3))

	# Forzieri (stelle rotanti)
	for chest in get_tree().get_nodes_in_group("chest"):
		if chest is Node2D:
			var pos = center + _to_radar_pos(chest.global_position)
			_draw_animated_star(pos, 5, star_outer_radius, star_inner_radius, chest_color, _global_time * 2.0)

	# Base nemica (quadrato con bordi intermittenti)
	for base in get_tree().get_nodes_in_group("e_base"):
		if base is Node2D:
			var pos = center + _to_radar_pos(base.global_position)
			var sz = enemy_base_size + sin(_global_time * 10.0) * 0.5
			draw_rect(Rect2(pos - Vector2(sz, sz), Vector2(sz*2, sz*2)), enemy_base_color)
			if fmod(_global_time, 0.8) < 0.4:
				draw_rect(Rect2(pos - Vector2(sz+1, sz+1), Vector2((sz+1)*2, (sz+1)*2)),
						 Color(enemy_base_color, 0.6), false, 1.0)

	# Base alleata (triangolo verde)
	for base in get_tree().get_nodes_in_group("base"):
		if base is Node2D:
			var pos = center + _to_radar_pos(base.global_position)
			var scale_tri = 1.0 + sin(_global_time * 4.0) * 0.15
			_draw_triangle(pos, player_base_triangle_size * scale_tri, player_base_color)
			draw_arc(pos, player_base_triangle_size + 2.0, 0, TAU, 16, Color(player_base_color, 0.5), 1.0)

	# Bonus (rombo ruotante)
	for bonus in get_tree().get_nodes_in_group("bonus"):
		if bonus is Node2D:
			var pos = center + _to_radar_pos(bonus.global_position)
			_draw_rotated_diamond(pos, bonus_diamond_size, bonus_color, _global_time * 3.0)

	# Boss (teschio con alone rosso)
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss is Node2D:
			var pos = center + _to_radar_pos(boss.global_position)
			var skull_pulse = 1.0 + sin(_global_time * 12.0) * 0.1
			_draw_skull_demon(pos, boss_skull_size * skull_pulse, boss_color, boss_eye_color)
			draw_circle(pos, boss_skull_size * 1.3 * skull_pulse, Color(1, 0, 0, 0.2))

	# Dungeon (teschio violaceo)
	for dungeon in get_tree().get_nodes_in_group("dungeon"):
		if dungeon is Node2D:
			var pos = center + _to_radar_pos(dungeon.global_position)
			var d_pulse = 1.0 + cos(_global_time * 5.0) * 0.08
			_draw_skull_demon(pos, dungeon_skull_size * d_pulse, dungeon_color, Color(0.5, 0, 0.5))

# ============================================================
# HELPER DI DISEGNO
# ============================================================

func _draw_sweep_line(center: Vector2, radius: float) -> void:
	var end = center + Vector2.RIGHT.rotated(_angle) * radius
	draw_line(center, end, sweep_color, sweep_line_width)
	# Coda dinamica
	for i in range(1, sweep_trail_segments + 1):
		var alpha = 0.6 - i * (0.6 / sweep_trail_segments)
		var arc_r = radius * (1.0 - i * 0.02)
		var start_angle = _angle - i * 0.05
		var end_angle = _angle + 0.1
		draw_arc(center, arc_r, start_angle, end_angle, 8, Color(sweep_color, alpha), 1.5)

func _draw_animated_star(center: Vector2, points_count: int, outer_r: float, inner_r: float, color: Color, rotation: float) -> void:
	var pts = []
	var step = TAU / (points_count * 2)
	for i in range(points_count * 2):
		var r = outer_r if i % 2 == 0 else inner_r
		var angle = rotation + i * step
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_polygon(pts, [color])
	# punte brillanti
	for i in range(points_count):
		var angle = rotation + i * 2 * step
		var tip = center + Vector2(cos(angle), sin(angle)) * outer_r
		draw_circle(tip, 1.2, Color(1.0, 1.0, 0.8))

func _draw_rotated_diamond(center: Vector2, size: float, color: Color, rot: float) -> void:
	var half = size
	var points = [
		center + Vector2(0, -half).rotated(rot),
		center + Vector2(half, 0).rotated(rot),
		center + Vector2(0, half).rotated(rot),
		center + Vector2(-half, 0).rotated(rot)
	]
	draw_polygon(points, [color])
	draw_polyline(points, Color(1,1,1,0.5), 1.0)

func _draw_triangle(center: Vector2, size: float, color: Color) -> void:
	var p1 = center + Vector2(0, -size)
	var p2 = center + Vector2(size * 0.8, size)
	var p3 = center + Vector2(-size * 0.8, size)
	draw_polygon([p1, p2, p3], [color])

func _draw_skull_demon(center: Vector2, size: float, skull_color: Color = Color(0.9, 0.9, 0.9), eye_color: Color = Color(1, 0, 0)) -> void:
	# Cranio
	var skull_points = [
		center + Vector2(-size, -size * 0.5),
		center + Vector2(-size * 0.7, -size),
		center + Vector2(size * 0.7, -size),
		center + Vector2(size, -size * 0.5),
		center + Vector2(size * 0.7, size * 0.4),
		center + Vector2(-size * 0.7, size * 0.4)
	]
	draw_polygon(skull_points, [skull_color])

	# Occhi
	var eye_offset_y = -size * 0.1
	var eye_offset_x = size * 0.45
	var eye_size = size * 0.35

	var left_eye = [
		center + Vector2(-eye_offset_x - eye_size * 0.3, eye_offset_y - eye_size * 0.3),
		center + Vector2(-eye_offset_x + eye_size * 0.5, eye_offset_y - eye_size * 0.1),
		center + Vector2(-eye_offset_x - eye_size * 0.3, eye_offset_y + eye_size * 0.4)
	]
	draw_polygon(left_eye, [eye_color])

	var right_eye = [
		center + Vector2(eye_offset_x + eye_size * 0.3, eye_offset_y - eye_size * 0.3),
		center + Vector2(eye_offset_x - eye_size * 0.5, eye_offset_y - eye_size * 0.1),
		center + Vector2(eye_offset_x + eye_size * 0.3, eye_offset_y + eye_size * 0.4)
	]
	draw_polygon(right_eye, [eye_color])

	# Mascella
	var jaw_points = [
		center + Vector2(-size * 0.5, size * 0.4),
		center + Vector2(size * 0.5, size * 0.4),
		center + Vector2(size * 0.3, size * 0.9),
		center + Vector2(-size * 0.3, size * 0.9)
	]
	draw_polygon(jaw_points, [skull_color])
	draw_line(center + Vector2(-size * 0.6, size * 0.4), center + Vector2(size * 0.6, size * 0.4), Color(0, 0, 0), 1.5)

func _to_radar_pos(world_pos: Vector2) -> Vector2:
	var relative := (world_pos - player.global_position)
	var radar_pos := relative / Global.radar_range * Global.radar_radius
	if radar_pos.length() > Global.radar_radius:
		radar_pos = radar_pos.normalized() * Global.radar_radius
	return radar_pos
