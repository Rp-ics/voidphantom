extends Area2D

@export var speed: float = 300.0
@export var original_speed: float = 300.0
@export var damage: int = 5
@export var lifetime: float = 10.0
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

# --- NODES ---
@onready var sprite: Sprite2D = $Sprite
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = lifetime
	timer.start()
	GlobalTweens.rotate($Sprite, 3600.0, lifetime) if randi() % 100 < 50 else GlobalTweens.rotate($Sprite, -3600.0, lifetime)
	# Scala danno in base alla wave
	var wave := Global.wave
	# Qui ipotizzo che la wave massima "utile" sia 100 (modifica a piacere)
	var max_wave := 100
	
	# Lineare da 5 a 100
	damage = int(remap(wave, 1, max_wave, 5, 100))
	damage = clamp(damage, 5, 100)
	

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
	
	# Effetti speciali
	match power:
		BulletPower.HOMING:
			var player := get_tree().get_first_node_in_group(group)
			if player:
				var target_dir = (player.global_position - global_position).normalized()
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
	if body.is_in_group(group) and !Global.player_immunity:
		if body.has_method("take_damage"):
			if GlobalSkills.zodiac['aries']:
				body.take_damage(damage / 2) if randi() % 100 < 10 else body.take_damage(damage)
			else:
				body.take_damage(damage)
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
	
	if body.is_in_group("enemy") or body.is_in_group("object") or body.is_in_group("base"):
		if power != BulletPower.PIERCING:
			queue_free()

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
