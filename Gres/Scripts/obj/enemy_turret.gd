extends Node2D

@export var fire_rate_min := 0.2
@export var fire_rate_max := 0.6
@export var rotation_speed := 10.0
@export var range := 3000.0

@onready var canon: Node2D = $Canon
@onready var muzzle: Node2D = $Canon/Muzzle
@onready var range_area: Area2D = $Range

var targets: Array = []
var shoot_timer := 0.0

func _ready() -> void:
	await get_tree().create_timer(5.0).timeout
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)
	GlobalTweens.activate($Range/CollisionShape2D)
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and is_instance_valid(body):
		targets.append(body)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		targets.erase(body)

func _physics_process(delta: float) -> void:
	# Pulisce i target non validi
	targets = targets.filter(is_instance_valid)
	if targets.is_empty():
		return

	var target = targets[0] # sempre primo
	_rotate_canon(target.global_position, delta)
	_try_shoot(delta, target)

func _rotate_canon(target_pos: Vector2, delta: float) -> void:
	var desired_angle := (target_pos - canon.global_position).angle()
	canon.rotation = lerp_angle(canon.rotation, desired_angle, delta * rotation_speed)

func _try_shoot(delta: float, target: Node) -> void:
	shoot_timer -= delta
	if shoot_timer > 0:
		return
	_shoot(target)
	shoot_timer = randf_range(fire_rate_min, fire_rate_max)

func _shoot(target: Node) -> void:
	if not target or not is_instance_valid(target):
		return

	var bullet_scene = preload("res://Gres/Scenes/enemies/bullets/enemy_bullet_1.tscn")
	var b: EnemyBullet = bullet_scene.instantiate()
	b.global_position = muzzle.global_position

	# Direzione verso il target
	var shoot_dir = (target.global_position - muzzle.global_position).normalized()
	b.set_direction(shoot_dir)

	get_tree().current_scene.add_child(b)
