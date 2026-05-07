extends Node2D


func _ready() -> void:
	get_tree().paused = false
	$ButtonsManager/Upgrade.connect("pressed", _on_update_pressed)
	$ButtonsManager/Settings.connect("pressed", _on_setting_pressed)
	$ButtonsManager/Missions.connect("pressed", _on_missions_pressed)
	$ButtonsManager/BackSett.connect("pressed", _on_back_pressed)
	# Unica connessione per Menu
	$ButtonsManager/Menu.connect("pressed", _on_main_menu_pressed)
	
func _on_update_pressed() -> void:
	$UpgradeMan.modulate = Color(1,1,1,0)
	$UpgradeMan.show()
	var tw = create_tween()
	tw.tween_property($UpgradeMan, "modulate:a", 1, 0.3)
	
func _on_setting_pressed() -> void:
	$SettingsMan.modulate = Color(1,1,1,0)
	$SettingsMan.show()
	var tw = create_tween()
	tw.tween_property($SettingsMan, "modulate:a", 1, 0.3)
	
func _on_missions_pressed() -> void:
	$Quests/show.play("show")
	
func _on_menu_pressed() -> void:
	pass
	
func _on_back_pressed() -> void:
	get_tree().paused = false
	Global.can_show_map = true
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))

func _on_main_menu_pressed() -> void:
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var tree = main_loop as SceneTree
		tree.paused = false
		tree.change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")
	else:
		push_error("Impossibile ottenere lo SceneTree")
