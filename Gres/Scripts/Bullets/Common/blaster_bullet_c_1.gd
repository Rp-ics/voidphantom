extends Area2D
class_name BaseBullet

@export var speed: float = 800.0
var direction: Vector2 = Vector2.ZERO


func set_direction(dir: Vector2):
	direction = dir.normalized()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(Global.player_damage)
		queue_free()
	elif body.is_in_group("object"):
		queue_free()
