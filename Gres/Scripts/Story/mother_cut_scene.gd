extends Node2D



func _ready() -> void:
	Global.boss_mame = "blood_mother"


func _on_anim_animation_finished(anim_name: StringName) -> void:
	if anim_name == "present": get_tree().change_scene_to_file("res://Gres/Scenes/arena/earth_1_4_boss.tscn")
