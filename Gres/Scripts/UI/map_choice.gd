extends Control

var mode := ""

func _ready() -> void:
	$Buttons/Endless.connect("pressed", _on_endless_pressed)
	$Buttons/BossRide.connect("pressed", _on_dungeon_pressed)
	$Buttons/Void.connect("pressed", _on_void_pressed)
	
func _on_endless_mouse_entered() -> void:
	$Title.text = "Endelss Mode"
	
func _on_dungeon_mouse_entered() -> void:
	$Title.text = "Dungeon & Boss"

func _on_void_mouse_entered() -> void:
	$Title.text = "Void Arena (beta)"


func _on_endless_pressed() -> void:
	mode = "endless"
	$trs.play("close")
func _on_dungeon_pressed() -> void:
	mode = "dungeon"
	$trs.play("close")
func _on_void_pressed() -> void:
	$VoidChoice.show()
	GlobalTweens.blink($VoidChoice)
	
func _on_trs_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close":
		match mode:
			"endless": get_tree().change_scene_to_file("res://Gres/Scenes/arena/arena.tscn")
			"dungeon": get_tree().change_scene_to_file("res://Gres/Scenes/UI/level_selector.tscn")
			"menu": get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")
			"void1": get_tree().change_scene_to_file("res://Gres/Scenes/arena/arena_void_1.tscn")
			"void2": get_tree().change_scene_to_file("res://Gres/Scenes/arena/arena_void_2.tscn")
	
func _on_close_button_pressed() -> void:
	mode = "menu"
	$trs.play("close")


func _on_map_1_pressed() -> void:
	mode = "void1"
	$trs.play("close")
	

func _on_map_2_pressed() -> void:
	mode = "void2"
	$trs.play("close")
	


func _on_back_pressed() -> void:
	GlobalTweens.blink($VoidChoice)
	await get_tree().create_timer(0.4).timeout
	$VoidChoice.hide()
