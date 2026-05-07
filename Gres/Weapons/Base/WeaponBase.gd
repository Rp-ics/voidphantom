extends Node2D
class_name WeaponBase

@export var fire_rate: float = 0.2
@export var bullet_scene: PackedScene
@export var auto_fire := true

var _cooldown := 0.0
var weapon_owner: Node2D  # impostato dal player

func _process(delta: float) -> void:
	if weapon_owner:
		global_position = weapon_owner.global_position
		rotation = weapon_owner.rotation

	if _cooldown > 0:
		_cooldown -= delta

	if _cooldown <= 0:
		if auto_fire and Input.is_action_pressed("fire"):
			fire()
			_cooldown = fire_rate
		elif not auto_fire and Input.is_action_just_pressed("fire"):
			fire()
			_cooldown = fire_rate

func fire() -> void:
	pass  # Override nelle armi concrete
