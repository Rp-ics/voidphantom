extends Node2D

var owner_node: Node = null
var targets: Array = []
var duration: float = 2.0
var dps: float = 40.0
var pull_force: float = 900.0

var timer := 0.0

func _process(delta: float) -> void:
	if timer >= duration:
		queue_free()
		return

	for target in targets:
		if not is_instance_valid(target):
			continue
		# Pull verso owner
		var dir = (owner_node.global_position - target.global_position).normalized()
		if target.has_method("move_and_slide"):
			target.position += dir * pull_force * delta
		# Apply DPS
		if target.has_method("take_damage"):
			target.take_damage(dps * delta, null)

	timer += delta
