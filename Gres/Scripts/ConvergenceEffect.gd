extends Node2D
# ConvergenceEffect.gd

@export var owner_node: Node = null
var targets: Array = []
var duration: float = 2.0
var dps: float = 40.0
var pull_force: float = 900.0

var elapsed := 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if not is_instance_valid(owner_node):
		queue_free()
		return
	elapsed += delta
	# each frame pull targets toward owner and apply DPS
	for t in targets.duplicate():
		if not is_instance_valid(t):
			targets.erase(t)
			continue
		# compute pull vector
		var dir = owner_node.global_position - t.global_position
		var dist = dir.length()
		if dist > 4:
			var pull_step = dir.normalized() * min(pull_force * delta, dist)
			# try to move enemy in a safe way: if enemy has move method prefer it
			if t.has_method("global_translate"): # fallback
				t.global_translate(pull_step)
			else:
				# direct position change (ok for short forced movement)
				t.global_position += pull_step

		# apply DPS (per-frame)
		var dmg = dps * delta
		if t.has_method("take_damage"):
			t.take_damage(dmg)
	# end loop

	if elapsed >= duration or targets.is_empty():
		queue_free()
