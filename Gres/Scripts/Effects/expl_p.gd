extends Node2D

func _on_expl_animation_finished(anim_name: StringName) -> void:
	queue_free()
