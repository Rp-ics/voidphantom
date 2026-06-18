extends Area2D

# ============================================================
# MU_BULLET - Versione multiplayer con supporto armi PvP
# ============================================================
signal damage_dealt(shooter_id: int, target_id: int, damage: float)

var damage: float = 10.0
var speed: float = 500.0
var direction: Vector2 = Vector2.RIGHT
var shooter_peer_id: int = 0
var lifetime: float = 3.0
var age: float = 0.0
var projectile_type: String = "line"
var weapon_data: Dictionary = {}

@onready var collision_shape = $CollisionShape2D
@onready var bullet_sprite = $Sprite2D if has_node("Sprite2D") else null

# Variabili per comportamenti speciali
var target: Node2D = null
var traveled_distance: float = 0.0
var return_distance: float = 500.0
var life_timer: float = 0.0
var max_life: float = 5.0
var spawned: bool = false
var collided: bool = false
var _is_mine: bool = false
var _mine_armed: bool = false
var _mine_stop_time: float = 0.5
var _mine_trigger_radius: float = 80.0
var _mine_explosion_radius: float = 200.0
var _echo_spawned: bool = false
var _chrono_field_applied: bool = false
var _mind_effect_applied: bool = false
var _swap_done: bool = false
var _trail_points: Array[Vector2] = []
var _trail_max_points: int = 20
var _draw_time: float = 0.0

# Riferimento al proprietario (player)
var bullet_owner: Node = null

func _ready():
	add_to_group("p_bullet")
	_draw_time = 0.0
	print("[Bullet] _ready - authority: ", is_multiplayer_authority(), " shooter: ", shooter_peer_id)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
	print("[Bullet] Server bullet attivo - tipo: ", projectile_type)

func _physics_process(delta):
	age += delta
	life_timer += delta
	_draw_time += delta
	
	# Movimento in base al tipo di proiettile
	match projectile_type:
		"line", "cone_3", "cone_5":
			_move(delta)
		
		"homing":
			if target and is_instance_valid(target):
				var dir = (target.global_position - global_position).normalized()
				direction = direction.lerp(dir, 0.08)
			_move(delta)
		
		"bounce":
			_move(delta)
			_handle_bounce()
		
		"wave_split":
			if life_timer >= 0.1 and not spawned:
				_split_wave()
				spawned = true
				queue_free()
			else:
				_move(delta)
		
		"explode_after":
			if life_timer >= 1.5 and not spawned:
				_spawn_explosion(6)
				spawned = true
				queue_free()
			else:
				_move(delta)
		
		"follow_stop":
			if target and is_instance_valid(target) and life_timer < 0.5:
				direction = (target.global_position - global_position).normalized()
			_move(delta)
		
		"proximity_mine_shot":
			if not _is_mine:
				_move(delta)
				if life_timer >= _mine_stop_time:
					_is_mine = true
					speed = 0
					set_deferred("monitoring", true)
					get_tree().create_timer(0.3).timeout.connect(func(): _mine_armed = true)
			else:
				if _mine_armed:
					_check_mine_proximity()
				if life_timer >= 12.0:
					queue_free()
		
		"graviton_pulse_shot":
			if life_timer < 1.0:
				_move(delta)
			else:
				speed = 0
				if not spawned:
					spawned = true
					_spawn_graviton_field()
		
		"phantom_echo_shot":
			_move(delta)
			var echo_delay = weapon_data.get("echo_delay", 0.3)
			if life_timer >= echo_delay and not _echo_spawned:
				_echo_spawned = true
				var echo_count = weapon_data.get("echo_count", 3)
				for i in range(echo_count):
					await get_tree().create_timer(0.15).timeout
					if not is_instance_valid(self): break
					_spawn_echo_bullet()
		
		"chrono_ripper_shot":
			_move(delta)
		
		"soul_leech_shot":
			_move(delta)
		
		"entropy_cannon_shot":
			_move(delta)
		
		"dimensional_swap_shot":
			_move(delta)
		
		_:
			_move(delta)
	
	_update_trail(delta)
	
	if _is_out_of_screen(400):
		queue_free()

func _move(delta: float):
	global_position += direction.normalized() * speed * delta

func _update_trail(delta):
	_trail_points.append(global_position)
	if _trail_points.size() > _trail_max_points:
		_trail_points.remove_at(0)
	queue_redraw()

func _draw():
	if _trail_points.size() < 2:
		return
	var pts := _to_local_trail()
	var n := pts.size()
	var head := Color(0.0, 0.6, 1.0, 0.9)
	var tail := Color(0.0, 0.2, 0.5, 0.0)
	match projectile_type:
		"line", "cone_3", "cone_5":
			head = Color(1.0, 0.8, 0.2, 0.9); tail = Color(1.0, 0.4, 0.0, 0.0)
		"homing":
			head = Color(0.2, 1.0, 0.6, 0.9); tail = Color(0.0, 0.5, 0.2, 0.0)
		"bounce":
			head = Color(0.8, 0.4, 1.0, 0.9); tail = Color(0.4, 0.0, 0.6, 0.0)
		"wave_split":
			head = Color(0.2, 0.8, 1.0, 0.9); tail = Color(0.0, 0.3, 0.6, 0.0)
		"explode_after":
			head = Color(1.0, 0.3, 0.1, 0.9); tail = Color(0.6, 0.0, 0.0, 0.0)
		"graviton_pulse_shot":
			head = Color(0.6, 0.2, 1.0, 0.9); tail = Color(0.3, 0.0, 0.6, 0.0)
		"chrono_ripper_shot":
			head = Color(0.2, 0.9, 1.0, 0.9); tail = Color(0.0, 0.4, 0.6, 0.0)
		"soul_leech_shot":
			head = Color(1.0, 0.1, 0.2, 0.9); tail = Color(0.5, 0.0, 0.0, 0.0)
		"entropy_cannon_shot":
			head = Color(1.0, 0.5, 0.0, 0.9); tail = Color(0.4, 0.2, 0.0, 0.0)
		"dimensional_swap_shot":
			head = Color(0.7, 0.3, 1.0, 0.9); tail = Color(0.3, 0.0, 0.6, 0.0)
		"proximity_mine_shot":
			head = Color(0.9, 0.9, 0.3, 0.9); tail = Color(0.5, 0.4, 0.0, 0.0)
		"phantom_echo_shot":
			head = Color(0.3, 0.7, 1.0, 0.9); tail = Color(0.1, 0.2, 0.5, 0.0)
		"nullborn_sovereign_shot":
			head = Color(0.0, 0.0, 0.0, 0.9); tail = Color(0.3, 0.0, 0.3, 0.0)
		"oblivion_herald_shot":
			head = Color(0.8, 0.0, 0.4, 0.9); tail = Color(0.4, 0.0, 0.2, 0.0)
		"voidfather_eclipse_shot":
			head = Color(1.0, 1.0, 1.0, 0.9); tail = Color(0.3, 0.3, 0.3, 0.0)
	for i in range(n - 1):
		var t := float(i) / float(n)
		var col := tail.lerp(head, t)
		col.a = t * 0.85
		var w = lerp(1.0, 4.0, t)
		draw_line(pts[i], pts[i + 1], col, w, true)
	for i in range(n - 1):
		var t := float(i) / float(n)
		var gc := head
		gc.a = t * 0.15
		draw_line(pts[i], pts[i + 1], gc, 7.0 * t, true)
	if n > 3:
		for k in range(3):
			var idx := n - 2 - k * 2
			if idx < 0:
				break
			var lc := head
			lc.a = (1.0 - float(k) * 0.3) * 0.6
			draw_line(pts[idx], pts[min(idx + 1, n - 1)], lc, 3.0 * (1.0 - float(k) * 0.25), true)
	var pulse := sin(_draw_time * 14.0) * 0.5 + 0.5
	draw_circle(Vector2.ZERO, 3.0 + pulse * 2.0, head)
	draw_circle(Vector2.ZERO, 1.5, Color(1.0, 1.0, 1.0, 0.85))

func _to_local_trail() -> Array[Vector2]:
	var local: Array[Vector2] = []
	var inv_rot := -rotation
	for p in _trail_points:
		local.append((p - global_position).rotated(inv_rot))
	return local

func init_from_weapon(weapon_dict: Dictionary, dir: Vector2, _owner_node):
	direction = dir.normalized()
	damage = weapon_dict.get("damage", 10.0)
	speed = weapon_dict.get("speed", 500.0)
	projectile_type = weapon_dict.get("projectile_type", "line")
	weapon_data = weapon_dict.duplicate(true)
	bullet_owner = _owner_node
	
	# Durata proiettile: usa "life" se specificata, altrimenti scala con rarità
	if weapon_dict.has("life"):
		lifetime = weapon_dict["life"]
	else:
		var rarity_life = {"common": 2.0, "rare": 3.0, "epic": 4.5, "legendary": 6.0}
		lifetime = rarity_life.get(weapon_dict.get("rarity", "common"), 3.0)
	
	# Imposta target per homing
	if projectile_type == "homing":
		var nearest_player = _find_nearest_player()
		target = nearest_player
	
	# Aggiorna rotazione
	rotation = direction.angle()
	
	# ============================================================
	# CARICA LA TEXTURE DEL PROIETTILE DALLA WEAPON_DATA
	# ============================================================
	if bullet_sprite:
		var tex_path = ""
		if weapon_dict.has("bullet_texture"):
			tex_path = weapon_dict["bullet_texture"]
		elif weapon_data.has("bullet_texture"):
			tex_path = weapon_data["bullet_texture"]
		
		if typeof(tex_path) == TYPE_STRING and tex_path != "" and ResourceLoader.exists(tex_path):
			bullet_sprite.texture = load(tex_path)
			print("[Bullet] Texture caricata: ", tex_path)
		else:
			var default_tex = "res://Gres/Assets/player/bullets/blaster_bulletC.png"
			if ResourceLoader.exists(default_tex):
				bullet_sprite.texture = load(default_tex)
				print("[Bullet] Texture di default caricata")
		
		bullet_sprite.scale = Vector2(0.5, 0.5)

func _find_nearest_player() -> Node2D:
	var nearest: Node2D = null
	var min_dist = INF
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p):
			continue
		# Evita il player che ha sparato (confronto peer ID)
		var shooter_id = p.get_multiplayer_authority()
		if shooter_id == shooter_peer_id:
			continue
		# Evita player morti
		if p.get("mp_is_dead") == true:
			continue
		var d = global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest = p
	return nearest

func _on_body_entered(body: Node):
	
	print("[Bullet] Collisione con: ", body.name, " shooter: ", shooter_peer_id)

	# ============================================================
	# PVE MODE - Danno ai nemici
	# ============================================================
	if GameModes.is_pve_mode() and (body.is_in_group("enemy") or body.is_in_group("enemy_ex")):
		var enemy_node = body
		
		# Controlla se il nemico è già morto
		var enemy_hp = 0
		if enemy_node.has_method("get_hp"):
			enemy_hp = enemy_node.get_hp()
		elif enemy_node.has_meta("hp"):
			enemy_hp = enemy_node.get_meta("hp")
		elif "hp" in enemy_node:
			enemy_hp = enemy_node.hp
		
		if enemy_hp <= 0:
			_explode()
			queue_free()
			return
		
		var final_damage = damage
		
		if projectile_type == "entropy_cannon_shot":
			final_damage *= _get_entropy_damage_mult()
		
		if bullet_owner and bullet_owner.has_meta("swap_power_stacks"):
			var stacks = bullet_owner.get_meta("swap_power_stacks", 0)
			if stacks > 0:
				final_damage *= 2.0
				if is_multiplayer_authority():
					bullet_owner.set_meta("swap_power_stacks", stacks - 1)
		
		# Ottieni enemy_id in modo sicuro
		var enemy_id = 0
		if enemy_node.has_method("get_enemy_id"):
			enemy_id = enemy_node.get_enemy_id()
		elif enemy_node.has_meta("enemy_id"):
			enemy_id = enemy_node.get_meta("enemy_id")
		elif "enemy_id" in enemy_node:
			enemy_id = enemy_node.enemy_id
		
		if multiplayer.is_server():
			if enemy_node.has_method("take_damage"):
				enemy_node.take_damage(final_damage, shooter_peer_id)
				# Aggiorna HP sincronizzato
				var new_hp = 0
				if enemy_node.has_method("get_hp"):
					new_hp = enemy_node.get_hp()
				_sync_pve_enemy_hp.rpc(enemy_id, new_hp)
		else:
			report_pve_damage_to_server.rpc_id(1, enemy_id, final_damage)
		
		_apply_pve_special_effects(body)
		_explode()
		queue_free()
		return
	
	# ============================================================
	# PVP MODE - Danno ai giocatori
	# ============================================================
	if body.is_in_group("player"):
		if GameModes.is_pve_mode():
			_explode()
			queue_free()
			return

		var target_body = body
		if target_body.get_multiplayer_authority() == shooter_peer_id:
			print("[Bullet] Colpito se stesso, ignoro")
			return
			
		if target_body.get("can_be_damaged") == false or target_body.get("mp_is_dead") == true:
			_explode()
			queue_free()
			return
		
		var final_damage = damage
		
		if projectile_type == "entropy_cannon_shot":
			final_damage *= _get_entropy_damage_mult()
		
		if weapon_data.get("homing_marked", false):
			final_damage *= 2.0
		
		if bullet_owner and bullet_owner.has_meta("swap_power_stacks"):
			var stacks = bullet_owner.get_meta("swap_power_stacks", 0)
			if stacks > 0:
				final_damage *= 2.0
				if is_multiplayer_authority():
					bullet_owner.set_meta("swap_power_stacks", stacks - 1)
		
		print("[Bullet] Danno a player ", target_body.get_multiplayer_authority(), " danno: ", final_damage)
		
		if is_multiplayer_authority():
			# Emetti segnale per il punteggio (prima di applicare il danno)
			damage_dealt.emit(shooter_peer_id, target_body.get_multiplayer_authority(), final_damage)
			
			# PATCH: salva il killer per determinarlo in Arena (_get_last_killer)
			target_body.set_meta("last_hit_by", shooter_peer_id)
			
			var target_auth = target_body.get_multiplayer_authority()
			# FIX: For bots (negative peer IDs), call damage directly since RPC doesn't work
			if target_auth < 0:
				# Solo per i bot - chiamata diretta
				target_body.take_pvp_damage_direct(final_damage)
			else:
				# Per i giocatori umani - RPC
				target_body.rpc_id(target_auth, "take_pvp_damage", final_damage)
		
		_apply_special_effects(body)
		
		_explode()
		queue_free()

@rpc("any_peer", "reliable")
func report_pve_damage_to_server(enemy_id: int, damage_amount: float):
	if not multiplayer.is_server():
		return
	var arena = get_tree().current_scene
	if not arena:
		return
	var wave_manager = arena.get_node_or_null("PVEWaveManager")
	if not wave_manager:
		return
	var enemy_node = null
	for child in wave_manager.get_children():
		# CORREZIONE: usa has_method e has_meta invece di get() con due argomenti
		var child_enemy_id = 0
		if child.has_method("get_enemy_id"):
			child_enemy_id = child.get_enemy_id()
		elif child.has_meta("enemy_id"):
			child_enemy_id = child.get_meta("enemy_id")
		elif "enemy_id" in child:
			child_enemy_id = child.enemy_id
		
		if child_enemy_id == enemy_id:
			enemy_node = child
			break
	
	if is_instance_valid(enemy_node) and enemy_node.has_method("take_damage"):
		enemy_node.take_damage(damage_amount, shooter_peer_id)
		
		# Ottieni l'HP aggiornato in modo sicuro
		var new_hp = 0.0
		if enemy_node.has_method("get_hp"):
			new_hp = enemy_node.get_hp()
		elif enemy_node.has_meta("hp"):
			new_hp = enemy_node.get_meta("hp")
		elif "hp" in enemy_node:
			new_hp = enemy_node.hp
			
		_sync_pve_enemy_hp.rpc(enemy_id, new_hp)

@rpc("authority", "reliable", "call_local")
func _sync_pve_enemy_hp(enemy_id: int, new_hp: float):
	var arena = get_tree().current_scene
	if not arena:
		return
	var wave_manager = arena.get_node_or_null("PVEWaveManager")
	if not wave_manager:
		return
	var enemy_node = wave_manager.get_node_or_null("Enemy_%d" % enemy_id)
	if is_instance_valid(enemy_node):
		enemy_node.hp = new_hp

func _apply_pve_special_effects(body: Node):
	var effect_type = weapon_data.get("projectile_type", "")
	match effect_type:
		"chrono_ripper_shot":
			if body.has_method("apply_buff"):
				body.apply_buff("slowed", 2.0, {"amount": 0.5})

func _apply_special_effects(body: Node):
	match projectile_type:
		"line":
			var fc = weapon_data.get("freeze_chance", 0)
			var fd = weapon_data.get("freeze_duration", 1.0)
			if fc > 0 and randi() % 100 < fc and body.has_method("apply_buff"):
				body.apply_buff("frozen", fd)
		
		"mind_fracture_shot":
			if not _mind_effect_applied:
				_mind_effect_applied = true
				if randi() % 100 < 25:
					if body.has_method("apply_buff"):
						body.apply_buff("frozen", 1.5)
		
		"chrono_ripper_shot":
			if not _chrono_field_applied:
				_chrono_field_applied = true
				if body.has_method("apply_buff"):
					body.apply_buff("slowed", 2.0, {"amount": 0.5})
		
		"dimensional_swap_shot":
			if not _swap_done and bullet_owner:
				_swap_done = true
				if randi() % 100 < 25:
					var player_pos = bullet_owner.global_position
					var enemy_pos = body.global_position
					bullet_owner.global_position = enemy_pos
					body.global_position = player_pos
					if body.has_method("apply_buff"):
						body.apply_buff("frozen", 1.0)
		
		"soul_leech_shot":
			if randi() % 100 < 15 and bullet_owner:
				var healed = damage * 0.15
				bullet_owner.take_pvp_damage(-healed)

		"fist_of_god":
			# EXCLUSIVE: Obey the Fist! - Devastating effect
			if body.has_method("apply_buff"):
				body.apply_buff("frozen", 3.0)
				body.apply_buff("burning", 5.0, {"damage": 50.0})
			if bullet_owner and body.has_method("take_pvp_damage"):
				body.take_pvp_damage(damage * 2.0)  # Double damage on hit

func _get_entropy_damage_mult() -> float:
	var dist_traveled = age * speed
	var max_range = weapon_data.get("max_range_px", 800.0)
	var min_mult = weapon_data.get("min_range_bonus", 0.5)
	var max_mult = weapon_data.get("max_range_bonus", 3.0)
	return lerp(min_mult, max_mult, clamp(dist_traveled / max_range, 0.0, 1.0))

func _handle_bounce():
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return
	var vp_size = get_viewport_rect().size * cam.zoom
	var half = vp_size * 0.5
	var bounds = Rect2(cam.global_position - half, vp_size)
	var bounced = false
	
	if global_position.x <= bounds.position.x or global_position.x >= bounds.position.x + bounds.size.x:
		direction.x = -direction.x
		bounced = true
	if global_position.y <= bounds.position.y or global_position.y >= bounds.position.y + bounds.size.y:
		direction.y = -direction.y
		bounced = true
	
	if bounced:
		rotation = direction.angle()
		_fx_bounce()

func _fx_bounce():
	if bullet_sprite:
		var tween = create_tween()
		tween.tween_property(bullet_sprite, "scale", Vector2(0.7, 1.3), 0.05)
		tween.tween_property(bullet_sprite, "scale", Vector2(0.5, 0.5), 0.1)

func _split_wave():
	if not bullet_owner:
		return
	for angle in [-30, -15, 15, 30]:
		var dir = direction.rotated(deg_to_rad(angle))
		var bullet = _create_child_bullet({"damage": damage * 0.7, "speed": speed, "projectile_type": "line"}, dir)
		if bullet:
			bullet.global_position = global_position
			get_parent().add_child(bullet)

func _spawn_explosion(count: int):
	for i in range(count):
		var angle = deg_to_rad((360 / count) * i)
		var dir = Vector2.RIGHT.rotated(angle)
		var bullet = _create_child_bullet({"damage": damage * 0.5, "speed": speed * 0.8, "projectile_type": "line"}, dir)
		if bullet:
			bullet.global_position = global_position
			get_parent().add_child(bullet)

func _create_child_bullet(data: Dictionary, dir: Vector2):
	var bullet_scene = load("res://Gres/Multiplayer/scene/bullets/mu_bullet.tscn")
	var bullet = bullet_scene.instantiate()
	bullet.init_from_weapon(data, dir, bullet_owner)
	bullet.shooter_peer_id = shooter_peer_id
	bullet.set_multiplayer_authority(1)
	return bullet

func _spawn_echo_bullet():
	var echo_data = weapon_data.duplicate(true)
	echo_data["damage"] = int(damage * weapon_data.get("echo_damage_mult", 0.75))
	echo_data["projectile_type"] = "line"
	var bullet = _create_child_bullet(echo_data, direction)
	if bullet:
		bullet.global_position = global_position
		bullet.modulate = Color(0.6, 0.6, 1.0, 0.7)
		get_parent().add_child(bullet)

func _spawn_graviton_field():
	var field = _GravitonFieldNode.new()
	field.global_position = global_position
	field.magnet_radius = weapon_data.get("magnet_radius", 300.0)
	field.duration = weapon_data.get("magnet_duration", 3.5)
	field.tick_dmg = weapon_data.get("magnet_tick_damage", 7.0)
	field.bullet_owner = bullet_owner
	field.shooter_peer_id = shooter_peer_id
	get_parent().add_child(field)

func _check_mine_proximity():
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D and is_instance_valid(e)):
			continue
		if global_position.distance_to(e.global_position) <= _mine_trigger_radius:
			_mine_explode()
			return

func _mine_explode():
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D and is_instance_valid(e)):
			continue
		if global_position.distance_to(e.global_position) <= _mine_explosion_radius:
			if e.has_method("take_damage"):
				e.take_damage(damage, self)
	_explode()

func _explode():
	var explosion = preload("res://Gres/Scenes/Effects/expl_p.tscn").instantiate()
	explosion.global_position = global_position
	get_parent().add_child(explosion)

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var min_dist = INF
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Node2D):
			continue
		var d = global_position.distance_to(e.global_position)
		if d < min_dist:
			min_dist = d
			nearest = e
	return nearest

func _is_out_of_screen(margin: int = 200) -> bool:
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return false
	var vp_size = get_viewport_rect().size * cam.zoom
	var half = vp_size * 0.5
	var screen_rect = Rect2(cam.global_position - half, vp_size)
	return not screen_rect.grow(margin).has_point(global_position)


# ============================================================
# CLASSE PER CAMPO GRAVITAZIONALE
# ============================================================
class _GravitonFieldNode extends Node2D:
	var magnet_radius: float = 300.0
	var duration: float = 3.5
	var tick_dmg: float = 7.0
	var bullet_owner: Node = null
	var shooter_peer_id: int = 0
	var _age: float = 0.0
	var _tick_t: float = 0.0
	
	func _ready():
		set_physics_process(true)
	
	func _physics_process(delta):
		_age += delta
		_tick_t += delta
		
		if _tick_t >= 0.5:
			_tick_t = 0.0
			for e in get_tree().get_nodes_in_group("enemy"):
				if not (e is Node2D and is_instance_valid(e)):
					continue
				if global_position.distance_to(e.global_position) <= magnet_radius:
					var pull_dir = (global_position - e.global_position).normalized()
					if "velocity" in e:
						e.velocity += pull_dir * 600.0
					if e.has_method("take_damage"):
						e.take_damage(tick_dmg, bullet_owner)
		
		queue_redraw()
		if _age >= duration:
			queue_free()
	
	func _draw():
		var fade = clamp(1.0 - _age / duration, 0.0, 1.0)
		draw_arc(Vector2.ZERO, magnet_radius * 0.8, 0, TAU, 48, Color(0.5, 0.0, 1.0, fade * 0.5), 2.0, true)
		draw_arc(Vector2.ZERO, magnet_radius * 0.4, 0, TAU, 32, Color(0.8, 0.0, 1.0, fade * 0.7), 1.5, true)
