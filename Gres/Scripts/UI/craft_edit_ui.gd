extends Control

var btn = ""

func _ready() -> void:
	$Craft.connect("pressed", _on_craft_pressed)
	$Edit.connect("pressed", _on_edit_pressed)
	$CloseButton.connect("pressed", _on_close_pressed)

func _on_trs_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close":
		if btn == "craft":
			get_tree().change_scene_to_file("res://Gres/Scenes/UI/crafting_menu.tscn")
		elif btn == "edit":
			get_tree().change_scene_to_file("res://Gres/Scenes/UI/ship_editor.tscn")
		else:
			get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")
			
func _on_craft_pressed() -> void:
	btn = "craft"
	$trs.play("close")
	
func _on_edit_pressed() -> void:
	btn = "edit"
	$trs.play("close")
	
func _on_close_pressed() -> void:
	btn = "close"
	$trs.play("close")


func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/void_shop.tscn")
