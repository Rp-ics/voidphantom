extends Node2D

var anim := "start"

func _on_open_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close_all":
		get_tree().change_scene_to_file("res://Gres/Scenes/UI/daily_wheel.tscn")
	if anim_name == "start":
		$open.play("closed_loop")
		anim = "closed_loop"

func _on_void_b_pressed() -> void:
	GlobalTweens.deactivate($VoidB)
	$Exlossive.emitting = true
	GlobalTweens.bounce($chestBG, 30, 0.6)
	GlobalTweens.bounce($VoidChest, 30, 0.6)
	GlobalTweens.bounce($Void, 30, 0.6)
	match anim:
		"closed_loop": anim = "open_and_gold"; $open.play(anim)
		"open_and_gold": anim = "open_craft"; $open.play(anim)
		"open_craft": anim = "open_spin"; $open.play(anim)
		"open_spin": anim = "open_skin"; $open.play(anim)
	$se_1.play()
	
func _on_take_pressed() -> void:
	$open.play("close_all")
