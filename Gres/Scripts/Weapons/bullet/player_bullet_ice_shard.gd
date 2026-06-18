extends Area2D
class_name PlayerBulletIceShard

# Proprietà base
var damage: float = 0.0
var speed: float = 0.0
var bullet_owner = null
var target: Node2D = null
var homing_strength: float = 3.0
var lifetime: float = 3.0
var bullet_texture: String = ""

# Nodi
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
#@onready var hitbox: Area2D = $Hitbox  # Se hai un'Area2D separata per i danni

func _ready() -> void:
	# Configura la texture se specificata
	if bullet_texture and not bullet_texture.is_empty():
		var tex = load(bullet_texture)
		if tex and sprite:
			sprite.texture = tex
	
	# Timer per autodistruzione
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_end)
	add_child(timer)
	timer.start()

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func init_from_weapon(weapon_data: Dictionary, direction: Vector2, owner_node, is_player_bullet: bool = true) -> void:
	damage = weapon_data.get("damage", 0.0)
	speed = weapon_data.get("speed", 0.0)
	bullet_texture = weapon_data.get("bullet_texture", "")
	bullet_owner = owner_node
	
	# Imposta la direzione iniziale
	var dir = direction.normalized()
	rotation = dir.angle()
	
	# Imposta il tipo di proiettile
	var projectile_type = weapon_data.get("projectile_type", "linear")
	match projectile_type:
		"homing":
			homing_strength = 3.0
		"linear":
			homing_strength = 0.0
		_:
			homing_strength = 0.0
	
	# Imposta i layer di collisione
	collision_layer = 0
	collision_mask = 0
	if is_player_bullet:
		collision_mask = 2  # Layer nemici (modifica in base al tuo setup)
	else:
		collision_mask = 1  # Layer giocatore
	
	# Configura il CollisionShape2D
	if collision_shape:
		collision_shape.set_deferred("disabled", false)

func _physics_process(delta: float) -> void:
	# Movimento homing
	if target and is_instance_valid(target) and homing_strength > 0:
		var desired_dir = (target.global_position - global_position).normalized()
		var current_dir = Vector2.RIGHT.rotated(rotation)
		var new_dir = current_dir.lerp(desired_dir, homing_strength * delta).normalized()
		rotation = new_dir.angle()
	
	# Movimento nella direzione corrente
	var velocity = Vector2.RIGHT.rotated(rotation) * speed
	global_position += velocity * delta

# Funzione pubblica per trovare il nemico più vicino
func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var min_dist = INF
	
	for enemy in enemies:
		if not enemy is Node2D:
			continue
		var dist = global_position.distance_squared_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy
	
	return nearest

# Gestione collisioni hitbox
func _on_hitbox_area_entered(area: Area2D) -> void:
	_handle_collision(area)

func _on_hitbox_body_entered(body: Node2D) -> void:
	_handle_collision(body)

# Gestione collisioni dirette
func _on_area_entered(area: Area2D) -> void:
	_handle_collision(area)

func _on_body_entered(body: Node2D) -> void:
	_handle_collision(body)

# Gestione unificata delle collisioni
func _handle_collision(target_node: Node) -> void:
	# Evita di colpire il proprietario
	if target_node == bullet_owner:
		return
	
	# Applica danno
	if target_node.has_method("take_damage"):
		target_node.take_damage(damage, self)
	
	# Applica effetto congelamento se presente
	if target_node.has_method("apply_buff"):
		target_node.apply_buff("frozen", 1.5)  # Durata minore per i proiettili
	
	# Distruggi il proiettile
	queue_free()

func _on_lifetime_end() -> void:
	# Effetto di dissolvenza opzionale
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()

# Funzione per aggiornare il target
func set_target(new_target: Node2D) -> void:
	target = new_target
