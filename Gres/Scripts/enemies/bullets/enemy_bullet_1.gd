extends Area2D
class_name EnemyBullet

@export var speed: float = 300.0
@export var original_speed: float = 300.0
@export var damage: int = 5
@export var lifetime: float = 60.0
@export var margin: int = 200
var group = "player"

# Tipi di potere
enum BulletPower { NONE, PIERCING, BOUNCE, HOMING, SPLIT, ACCELERATE, ZIGZAG }
@export var power: BulletPower = BulletPower.NONE
@export var power_value: float = 1.0  # intensità del potere

# --- VARIABILI INTERNE ---
var direction := Vector2.RIGHT
var bounces_left := 3
var zigzag_timer := 0.0
var accel_timer := 0.0

# ============================================================
# AEGIS STORM: flag per sapere se il proiettile è stato
# deflesso e ora appartiene al player (colpisce i nemici)
# ============================================================
var is_deflected: bool = false

# --- NODES ---
@onready var sprite: Sprite2D = $Sprite
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = lifetime
	timer.start()

	if Global.mode == "dungeon":
		match Global.dificulty:
			"easy":
				damage = randi_range(5, 10)
				speed = float(randi_range(100, 300))
				original_speed = speed
			"normal":
				damage = randi_range(10, 40)
				speed = float(randi_range(200, 600))
				original_speed = speed
			"hard":
				damage = randi_range(50, 100)
				speed = float(randi_range(400, 800))
				original_speed = speed

	if Global.mode == "endless":
		var wave := Global.wave
		var max_wave := 100
		damage = int(remap(wave, 1, max_wave, 5, 100))
		damage = clamp(damage, 5, 100)
		original_speed = speed

func set_texture(tex: Texture2D) -> void:
	if sprite:
		sprite.texture = tex

func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	# Gestione slow-motion
	if GlobalStats.time_slow:
		match GlobalStats.time_slow_bonus:
			1: speed = 250
			2: speed = 150
			3: speed = 100
	else:
		speed = original_speed

	# ============================================================
	# AEGIS STORM DEFLECT: se il proiettile è stato deflesso
	# vola come un proiettile del player verso i nemici.
	# Visivamente: dovrebbe cambiare colore a viola/bianco
	# per indicare il cambio di "squadra".
	# ANIMAZIONE: Tween sul modulate da colore originale
	# a Color(0.8, 0.2, 1.0) in 0.1s quando is_deflected = true.
	# ------------------------------------------------
	if is_deflected:
		# Si comporta come proiettile homing verso i nemici
		var enemies := get_tree().get_nodes_in_group("enemy")
		var nearest: Node2D = null
		var min_dist := INF
		for e in enemies:
			if e is Node2D:
				var d := global_position.distance_to(e.global_position)
				if d < min_dist:
					min_dist = d
					nearest = e
		if nearest:
			var target_dir := (nearest.global_position - global_position).normalized()
			direction = direction.lerp(target_dir, 0.06)

	# Effetti speciali normali
	match power:
		BulletPower.HOMING:
			if not is_deflected:
				var target := get_tree().get_first_node_in_group(group)
				if target:
					var target_dir = (target.global_position - global_position).normalized()
					direction = direction.lerp(target_dir, 0.05 * power_value)
		BulletPower.ZIGZAG:
			zigzag_timer += delta * 10.0 * power_value
			var perp = Vector2(-direction.y, direction.x)
			direction = (direction + perp * sin(zigzag_timer) * 0.1).normalized()
		BulletPower.ACCELERATE:
			accel_timer += delta
			speed = original_speed + (accel_timer * 50.0 * power_value)
		_:
			pass

	# Movimento
	position += direction * speed * delta

	# Uscita dallo schermo
	var camera := get_viewport().get_camera_2d()
	if camera:
		var screen_rect := Rect2(camera.get_screen_center_position() - get_viewport_rect().size / 2, get_viewport_rect().size)
		var extended_rect := screen_rect.grow(margin)
		if not extended_rect.has_point(global_position):
			if power == BulletPower.BOUNCE and bounces_left > 0:
				if randf() < 0.5:
					direction.x *= -1
				else:
					direction.y *= -1
				bounces_left -= 1
			else:
				queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("wall_skill"): queue_free()
	# ============================================================
	# DEFLESSO: ora colpisce i nemici
	# ============================================================
	if is_deflected:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
		return

	# Comportamento normale
	if body.is_in_group(group) and !Global.player_immunity:
		if body.has_method("take_damage"):
			if GlobalSkills.zodiac['aries']:
				if randi() % 100 < 20:
					body.take_damage(damage / 2)
					_track_damage(damage / 2)
				else:
					body.take_damage(damage)
					_track_damage(damage)
			else:
				body.take_damage(damage)
				_track_damage(damage)

		Global.hurt = true
		Global.player_hp -= damage
		GlobalStats.player_damage_total += damage
		GlobalStats.player_damage_lvl += damage

		if power != BulletPower.PIERCING:
			if power == BulletPower.SPLIT:
				_split()
			queue_free()

	if body.is_in_group('base'):
		Global.base_hurt = true
		queue_free()

	# ============================================================
	# AEGIS STORM SHIELD: intercetta il proiettile se tocca
	# la CollisionArea del player (gestita in player.gd)
	# Nota: la deflection vera è chiamata da player._on_aegis_deflect()
	# ============================================================

	if body.is_in_group("enemy") or body.is_in_group("object") or body.is_in_group("base"):
		if power != BulletPower.PIERCING:
			queue_free()
	else: queue_free()

func _track_damage(amount: int) -> void:
	if Global.enemy_type == "mini_boss":
		GlobalStats.damage_rec_miniboss_lvl += amount
		GlobalStats.damage_rec_lvl += amount
		GlobalStats.damage_rec_total += amount
	if Global.enemy_type == "enemy":
		GlobalStats.damage_rec_total += amount
		GlobalStats.damage_rec_lvl += amount

func _on_timer_timeout() -> void:
	if power == BulletPower.SPLIT:
		_split()
	queue_free()

# --- SPLIT ---
func _split():
	for i in range(3):
		var b = load("res://Gres/Scenes/enemies/bullets/enemy_bullet.tscn").instantiate()
		b.global_position = global_position
		b.set_direction(Vector2.RIGHT.rotated(randf() * TAU))
		b.power = BulletPower.NONE
		get_parent().add_child(b)

# Aggiungi questa funzione in EnemyBullet.gd
func set_deflected(value: bool) -> void:
	is_deflected = value
	if is_deflected:
		# Cambia colore a viola/bianco
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(0.8, 0.2, 1.0, 1.0), 0.1)
		
