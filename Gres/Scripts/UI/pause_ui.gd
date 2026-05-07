extends Control


#func _ready() -> void:
	#if GlobalStats.show_fps:
		#$FPS_Label.show()
		#$Manager/SettingsMan/GraphicMan/ShowFPS.set_pressed_no_signal(true)
#
#func _process(delta: float) -> void:
	#$FPS_Label.text = str("FPS: ", Engine.get_frames_per_second())

func show_game_over():
	visible = true
	get_tree().paused = true


func _on_pause_b_pressed() -> void:
	Global.can_show_map = false
	get_tree().paused = true
	
	
	$Manager.modulate = Color(1,1,1,0)
	$Manager.show()
	var tw = create_tween()
	tw.tween_property($Manager, "modulate:a", 1, 0.3)
	
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")


func _on_show_fps_toggled(toggled_on: bool) -> void:
	if toggled_on:
		GlobalStats.show_fps = true
		$FPS_Label.show()
		
