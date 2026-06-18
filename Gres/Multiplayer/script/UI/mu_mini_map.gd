extends Control

# ============================================================
# MU_MINIMAP — Radar per MU_ARENA (multigiocatore)
# ============================================================

@export var enemy_group: String = "player"          # i player PvP sono in gruppo "player"
@export var show_king_zone: bool = true
@export var king_zone_color: Color = Color(0.2, 0.8, 0.5, 0.7)

# ============================================================
# PARAMETRI ESPORTABILI – ANIMAZIONI PRINCIPALI
# ============================================================
@export_category("Sweep Radar")
@export_range(0.1, 10.0) var sweep_speed: float = 2.0
@export var sweep_color: Color = Color(0.2, 1.0, 0.3, 0.6)
@export_range(1, 8) var sweep_trail_segments: int = 4
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
@export_range(0.1, 1.0) var grid_line_count: int = 3
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

@export_category("Icone – Nemici (PvP)")
@export var enemy_color: Color = Color(1, 0.2, 0.2)
@export_range(1.0, 6.0) var enemy_size: float = 3.0
@export_range(0.5, 2.0) var enemy_halo_size: float = 5.0
@export_range(1.0, 15.0) var enemy_threat_pulse_speed: float = 8.0

@export_category("Icone – Altri Oggetti (es. Forzieri, Bonus, ecc.)")
@export var chest_color: Color = Color(1, 1, 0.2)
@export_range(1.0, 10.0) var star_outer_radius: float = 5.0
@export_range(0.5, 5.0) var star_inner_radius: float = 2.0
@export var bonus_color: Color = Color(0.0, 1.0, 1.0)
@export_range(1.0, 8.0) var bonus_diamond_size: float = 4.0

# ============================================================
# VARIABILI INTERNE
# ============================================================
var _angle: float = 0.0
var _ping_timer: float = 0.0
var _pings: Array[float] = []
var _global_time: float = 0.0
var _glitch_offset: Vector2 = Vector2.ZERO
var _glitch_timer: float = 0.0

var _king_zone_center: Vector2 = Vector2.ZERO
var _king_zone_radius: float = 0.0

func _ready() -> void:
	# Se il giocatore non è ancora pronto, aspetta
	if not Global.player:
		await get_tree().process_frame
	queue_redraw()

func _process(delta: float) -> void:
	if not Global.player:
		return

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

	# Recupera la zona King of the Hill dalla scena arena
	if show_king_zone and has_node("/root/Main/Arena"):
		var arena = get_node("/root/Main/Arena")
		if arena.has_method("get_king_zone_info"):
			var info = arena.get_king_zone_info()
			_king_zone_center = info.position
			_king_zone_radius = info.radius

	queue_redraw()

func _draw() -> void:
	if not Global.player:
		return
	
	var base_radius = Global.radar_radius
	var center = size * 0.5 + _glitch_offset   # ← fix: size invece di rect_size
	var player_world = Global.player.global_position

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

	# ========== KING ZONE ==========
	if show_king_zone and _king_zone_radius > 0:
		var zone_radar_pos = center + _to_radar_pos(_king_zone_center, player_world, base_radius)
		var zone_radar_radius = (_king_zone_radius / Global.radar_range) * base_radius
		if zone_radar_radius > 0:
			draw_arc(zone_radar_pos, zone_radar_radius, 0, TAU, 64, king_zone_color, 2.0)
			# Cerchio interno pulsante
			var pulse = 0.5 + sin(_global_time * 8.0) * 0.5
			draw_circle(zone_radar_pos, zone_radar_radius * 0.2 * pulse, king_zone_color)

	# ========== ICONE GIOCATORI PVP ==========
	var my_id = multiplayer.get_unique_id() if multiplayer.multiplayer_peer else 1
	for node in get_tree().get_nodes_in_group("player"):
		if not node is Node2D: continue
		if node == Global.player: continue   # già disegnato dopo
		var pos = center + _to_radar_pos(node.global_position, player_world, base_radius)
		var threat = 1.0 + sin(_global_time * enemy_threat_pulse_speed + pos.x * 0.1) * 0.2
		draw_circle(pos, enemy_size * threat, enemy_color)
		draw_circle(pos, enemy_halo_size * threat, Color(enemy_color, 0.3))

	# ========== GIOCATORE LOCALE (centro) ==========
	var player_pulse = 1.0 + sin(_global_time * player_pulse_speed) * 0.3
	draw_circle(center, player_size * player_pulse, player_color)
	draw_circle(center, player_halo_size * player_pulse, Color(player_color, 0.3))

	# ========== OGGETTI AGGIUNTIVI (opzionali) ==========
	# Forzieri (stelle rotanti)
	for chest in get_tree().get_nodes_in_group("chest"):
		if chest is Node2D:
			var pos = center + _to_radar_pos(chest.global_position, player_world, base_radius)
			_draw_animated_star(pos, 5, star_outer_radius, star_inner_radius, chest_color, _global_time * 2.0)

	# Bonus (rombo ruotante)
	for bonus in get_tree().get_nodes_in_group("bonus"):
		if bonus is Node2D:
			var pos = center + _to_radar_pos(bonus.global_position, player_world, base_radius)
			_draw_rotated_diamond(pos, bonus_diamond_size, bonus_color, _global_time * 3.0)

# ============================================================
# HELPER DI DISEGNO
# ============================================================

func _draw_sweep_line(center: Vector2, radius: float) -> void:
	var end = center + Vector2.RIGHT.rotated(_angle) * radius
	draw_line(center, end, sweep_color, sweep_line_width)
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

func _to_radar_pos(world_pos: Vector2, player_pos: Vector2, radius: float) -> Vector2:
	var relative := (world_pos - player_pos)
	var radar_pos := relative / Global.radar_range * radius
	if radar_pos.length() > radius:
		radar_pos = radar_pos.normalized() * radius
	return radar_pos
