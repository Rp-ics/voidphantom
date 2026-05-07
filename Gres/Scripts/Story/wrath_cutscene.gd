extends Node2D


func _on_present_animation_finished(anim_name: StringName) -> void:
	Global.boss_mame = "gaias_wrath"
	get_tree().change_scene_to_file("res://Gres/Scenes/arena/earth_1_4_boss.tscn")
