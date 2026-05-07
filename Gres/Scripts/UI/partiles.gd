extends GPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_particles()


func _update_particles():
	for p in get_tree().get_nodes_in_group("particles"):
		var base_amount = p.get_meta("base_amount", p.amount)
		p.amount = int(base_amount * (Global.particle_quality / 100.0))
