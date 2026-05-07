extends Node2D


func emit_wave():
	var wave# = preload("res://Gres/Scenes/Effects/plasma_wave.tscn").instantiate()
	get_tree().current_scene.add_child(wave)
	wave.global_position = global_position
