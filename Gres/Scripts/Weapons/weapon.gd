extends Node2D

@export var damage: int = 10
@export var fire_rate: float = 0.5 # secondi tra colpi
@export var bullet_scene: PackedScene
@export var spread: float = 0.0 # per shotgun o armi random

var can_shoot: bool = true
var owner_ref: Node = null # player o chi la usa

func _ready():
	if owner_ref == null:
		push_warning("Weapon senza owner_ref!")

func shoot():
	if not can_shoot:
		return

	if bullet_scene == null:
		push_error("Weapon senza bullet_scene!")
		return

	# istanzia proiettile
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.rotation = global_rotation

	# aggiungi spread (se shotgun)
	if spread > 0.0:
		var offset = deg_to_rad(randf_range(-spread, spread))
		bullet.rotation += offset

	# passa danno al proiettile
	if bullet.has_variable("damage"):
		bullet.damage = damage

	get_tree().current_scene.add_child(bullet)

	# cooldown
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
