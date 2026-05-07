extends Node2D

func _ready() -> void:
	get_tree().paused = false
	$ButtonsManager/Upgrade.connect("pressed", _on_update_pressed)
	$ButtonsManager/Settings.connect("pressed", _on_setting_pressed)
	$ButtonsManager/Stats.connect("pressed", _on_stats_pressed)
	$ButtonsManager/Menu.connect("pressed", _on_menu_pressed)
	$ButtonsManager/BackSett.connect("pressed", _on_back_pressed)
	$ButtonsManager/Menu.connect("pressed", _on_main_menu_pressed)
	$VoidShard.text = str(GlobalStats.void_shard)
	$MagmaShard.text = str(GlobalStats.magma_shard)
	$IceShard.text = str(GlobalStats.ice_shard)
	$LightShard.text = str(GlobalStats.light_shard)
	$Tablet.text = str(GlobalStats.tablet)
	
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
	
func _on_stats_pressed() -> void:
	$StatsMan.modulate = Color(1,1,1,0)
	$StatsMan.show()
	var tw = create_tween()
	tw.tween_property($StatsMan, "modulate:a", 1, 0.3)
	
func _on_menu_pressed() -> void:
	pass
	
func _on_back_pressed() -> void:
	get_tree().paused = false
	Global.can_show_map = true
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))

func _on_main_menu_pressed()-> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")
