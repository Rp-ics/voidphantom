extends Node2D


func _ready() -> void:
	match Global.dificulty:
		"easy":
			Global.dungeons['lvl_1']['easy'] = true
		"normal":
			Global.dungeons['lvl_1']['normal'] = true
		"hard":
			Global.dungeons['lvl_1']['hard'] = true

func _on_dead_animation_finished(anim_name: StringName) -> void:
	Global.boss_mame = ""
	Global.boss_killed = false
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/level_selector.tscn")
