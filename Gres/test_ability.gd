extends Node2D
class_name TestAbility

@export var cooldown: float = 5.0
var _ready: bool = true

func activate(position: Vector2) -> void:
	if not ready:
		return
	_ready = false
	_show_effect(position)
	await get_tree().create_timer(cooldown).timeout
	_ready = true

func _show_effect(position: Vector2) -> void:
	var circle = CircleShape2D.new()
	var effect = ColorRect.new()
	effect.color = Color(1,0,0,0.5)
	effect.position = position
	effect.size = Vector2(100,100)
	get_tree().current_scene.add_child(effect)
	await get_tree().create_timer(0.3).timeout
	effect.queue_free()
