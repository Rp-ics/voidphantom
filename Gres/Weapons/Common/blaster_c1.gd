extends WeaponBase

@onready var muzzle: Marker2D = $Marker2D

func fire():
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.rotation = rotation
		bullet.set_direction(Vector2.RIGHT.rotated(rotation))
		get_tree().current_scene.add_child(bullet)
