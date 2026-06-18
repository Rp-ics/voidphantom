extends Node2D

func _ready() -> void:
	$BackGUI.connect("pressed", _on_back_pressed)
	$PFPBG/player_name.text = GlobalSteamScript.player_name
	
func _process(delta: float) -> void:
	$HPBar/HPCounter.visible = Global.hp_show
	$STMBar/STCounter.visible = Global.stm_show
	
	$HPBar/ShowHideHP.button_pressed = Global.hp_show
	$STMBar/ShowHideSTM.button_pressed = Global.stm_show
	
	var img = "res://Gres/Assets/Icons/pfp/pfp_%s.png" % Global.texture_pfp_icon
	$PFPBG/PFPIcon.texture = load(img)
	#$"../../../../PlayerUI/PFPBG/PFPIcon".texture = load(img)
func _on_show_hide_hp_toggled(toggled_on: bool) -> void:
	Global.hp_show = toggled_on

func _on_show_hide_stm_toggled(toggled_on: bool) -> void:
	Global.stm_show = toggled_on

func _on_back_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))
