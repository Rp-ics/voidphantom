extends Node2D


func _ready() -> void:
	call_deferred("change_scene_safe", "res://Gres/Scenes/Story/earth_story_1.tscn")

func change_scene_safe(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
