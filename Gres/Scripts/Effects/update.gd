extends GPUParticles2D

func _ready() -> void:
	_update_particles()


func _update_particles():
	for p in get_tree().get_nodes_in_group("particles"):
		var base_amount = p.get_meta("base_amount", p.amount)
		p.amount = int(base_amount * (Global.particle_quality / 100.0))

func _on_anim_animation_finished(anim_name: StringName) -> void:
	queue_free()
