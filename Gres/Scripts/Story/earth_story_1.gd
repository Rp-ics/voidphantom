extends Node2D

var next = 0

func _ready() -> void:
	if not Global.in_tutorial:
		call_deferred("change_scene_safe", "res://Gres/Scenes/UI/main_menu.tscn")

	$Next.connect("pressed", _on_next_pressed)
	$story.play("p1")

	
func change_scene_safe(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

func _on_story_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"p1": 
			$story.play("p1_2")
			Global.story_line = 1
			next += 1
		"p3": 
			$story.play("p3_2")
			Global.story_line = 2
			next += 1
			_on_next_pressed()
		"p4": 
			$story.play("p5")
		"p5": 
			get_tree().change_scene_to_file("res://Gres/Scenes/UI/tutorial.tscn")

func _on_next_pressed() -> void:
	if next == 1:
		$story.play("p3")
	elif next == 2:
		$story.play("p4")
	
func _on_skip_pressed() -> void:
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/tutorial.tscn")
