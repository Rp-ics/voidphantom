extends Node2D

@export var fire_rate := 2.0
@export var rotation_speed := 6.0

@onready var canon: Node2D = $Canon
@onready var muzzle: Node2D = $Canon/Muzzle
@onready var dir: RayCast2D = $Canon/Direction
@onready var range_area: Area2D = $Range

var targets: Array = []
var shoot_timer := 0.0


func _ready() -> void:
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		targets.append(body)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("enemy"):
		targets.erase(body)


func _physics_process(delta: float) -> void:
	if targets.is_empty():
		return

	var target = targets[0]  # prendi sempre il primo
	if not is_instance_valid(target):
		targets.remove_at(0)
		return

	_rotate_canon(target.global_position, delta)
	_try_shoot(delta)


# =========================================================
# ROTAZIONE SMOOTH DEL CANON
# =========================================================
func _rotate_canon(target_pos: Vector2, delta: float) -> void:
	var desired_angle := (target_pos - canon.global_position).angle()
	canon.rotation = lerp_angle(canon.rotation, desired_angle, delta * rotation_speed)


# =========================================================
# SHOOTING
# =========================================================
func _try_shoot(delta: float) -> void:
	shoot_timer -= delta
	if shoot_timer > 0:
		return
	
	shoot_timer = fire_rate
	_shoot(targets[0] if targets.size() > 0 else null)


func _shoot(target: Node) -> void:
	if not target or not is_instance_valid(target):
		return

	var bullet_scene = preload("res://Gres/Scenes/weapons/bullet/player_bullet.tscn")
	var b: PlayerBullet = bullet_scene.instantiate()
	b.global_position = muzzle.global_position

	# Direzione dal RayCast2D
	var shoot_dir: Vector2
	if dir.is_colliding():
		shoot_dir = (dir.get_collision_point() - dir.global_position).normalized()
	else:
		shoot_dir = dir.global_transform.x.normalized() # punta davanti al canon se niente target

	# Passa la direzione al bullet
	b.init_from_weapon({
		"damage": 5,
		"speed": 800,
		"projectile_type": "line"
	}, shoot_dir, self) # self come bullet_owner

	get_tree().current_scene.add_child(b)
