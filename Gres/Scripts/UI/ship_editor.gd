extends Control

var ship_part := "body"
var current_highlight: Node = null
var active_tween: Tween = null

func _ready() -> void:
	# Nebula-Forged Form
	# Edit your ship.
	GlobalStats.achievements["Nebula-Forged Form"] = true
	
	$ClosEditor.connect("pressed", _close_editor)
	match ship_part:
		"body":
			$ColorsMan/SlideR.value = Global.body_red_factor
			$ColorsMan/SlideG.value = Global.body_green_factor
			$ColorsMan/SlideB.value = Global.body_blue_factor
			$ColorsMan/Slide_saturation.value = Global.body_saturation
			$ColorsMan/Slide_brightness.value = Global.body_brightness
			$ColorsMan/Slide_contrast.value = Global.body_contrast
			$ColorsMan/Slide_hue_shift.value = Global.body_hue_shift
			$ColorsMan/Slide_gamma.value = Global.body_gamma
			
			$ColorsMan/SlideR/ValueR.text = str(Global.body_red_factor)
			$ColorsMan/SlideG/ValueG.text = str(Global.body_green_factor)
			$ColorsMan/SlideB/ValueB.text = str(Global.body_blue_factor)
			$ColorsMan/Slide_saturation/ValueSat.text = str(Global.body_saturation)
			$ColorsMan/Slide_brightness/ValueBri.text = str(Global.body_brightness)
			$ColorsMan/Slide_contrast/ValueCont.text = str(Global.body_contrast)
			$ColorsMan/Slide_hue_shift/ValueHue.text = str(Global.body_hue_shift)
			$ColorsMan/Slide_gamma/ValueGam.text = str(Global.body_gamma)
		"wings":
			$ColorsMan/SlideR.value = Global.wings_red_factor
			$ColorsMan/SlideG.value = Global.wings_green_factor
			$ColorsMan/SlideB.value = Global.wings_blue_factor
			$ColorsMan/Slide_saturation.value = Global.wings_saturation
			$ColorsMan/Slide_brightness.value = Global.wings_brightness
			$ColorsMan/Slide_contrast.value = Global.wings_contrast
			$ColorsMan/Slide_hue_shift.value = Global.wings_hue_shift
			$ColorsMan/Slide_gamma.value = Global.wings_gamma
			
			$ColorsMan/SlideR/ValueR.text = str(Global.wings_red_factor)
			$ColorsMan/SlideG/ValueG.text = str(Global.wings_green_factor)
			$ColorsMan/SlideB/ValueB.text = str(Global.wings_blue_factor)
			$ColorsMan/Slide_saturation/ValueSat.text = str(Global.wings_saturation)
			$ColorsMan/Slide_brightness/ValueBri.text = str(Global.wings_brightness)
			$ColorsMan/Slide_contrast/ValueCont.text = str(Global.wings_contrast)
			$ColorsMan/Slide_hue_shift/ValueHue.text = str(Global.wings_hue_shift)
			$ColorsMan/Slide_gamma/ValueGam.text = str(Global.wings_gamma)
		"prop":
			$ColorsMan/SlideR.value = Global.prop_red_factor
			$ColorsMan/SlideG.value = Global.prop_green_factor
			$ColorsMan/SlideB.value = Global.prop_blue_factor
			$ColorsMan/Slide_saturation.value = Global.prop_saturation
			$ColorsMan/Slide_brightness.value = Global.prop_brightness
			$ColorsMan/Slide_contrast.value = Global.prop_contrast
			$ColorsMan/Slide_hue_shift.value = Global.prop_hue_shift
			$ColorsMan/Slide_gamma.value = Global.prop_gamma
			
			$ColorsMan/SlideR/ValueR.text = str(Global.prop_red_factor)
			$ColorsMan/SlideG/ValueG.text = str(Global.prop_green_factor)
			$ColorsMan/SlideB/ValueB.text = str(Global.prop_blue_factor)
			$ColorsMan/Slide_saturation/ValueSat.text = str(Global.prop_saturation)
			$ColorsMan/Slide_brightness/ValueBri.text = str(Global.prop_brightness)
			$ColorsMan/Slide_contrast/ValueCont.text = str(Global.prop_contrast)
			$ColorsMan/Slide_hue_shift/ValueHue.text = str(Global.prop_hue_shift)
			$ColorsMan/Slide_gamma/ValueGam.text = str(Global.prop_gamma)
	
	$ColorsMan/SlideR.connect("value_changed", _on_SlideR_value_changed)
	$ColorsMan/SlideG.connect("value_changed", _on_SlideG_value_changed)
	$ColorsMan/SlideB.connect("value_changed", _on_SlideB_value_changed)
	$ColorsMan/Slide_saturation.connect("value_changed", _on_Slide_saturation_value_changed)
	$ColorsMan/Slide_brightness.connect("value_changed", _on_Slide_brightness_value_changed)
	$ColorsMan/Slide_contrast.connect("value_changed", _on_Slide_contrast_value_changed)
	$ColorsMan/Slide_hue_shift.connect("value_changed", _on_Slide_hue_shift_value_changed)
	$ColorsMan/Slide_gamma.connect("value_changed", _on_Slide_gamma_value_changed)
	
	$Body/BodyB.connect('mouse_entered', _on_body_mouse_entered)
	$Wings/WingsB.connect('mouse_entered', _on_wings_mouse_entered)
	$Prop/PropB.connect('mouse_entered', _on_prop_mouse_entered)
	
	$Body/BodyB.connect('mouse_exited', _on_body_mouse_exited)
	$Wings/WingsB.connect('mouse_exited', _on_wings_mouse_exited)
	$Prop/PropB.connect('mouse_exited', _on_prop_mouse_exited)
	
	$Body/BodyB.connect('pressed', _on_body_pressed)
	$Wings/WingsB.connect('pressed', _on_wings_pressed)
	$Prop/PropB.connect('pressed', _on_prop_pressed)
	
	$ColorsMan/SlideR/ResetR.connect("pressed", _on_reset_r_pressed)
	$ColorsMan/SlideG/ResetG.connect("pressed", _on_reset_g_pressed)
	$ColorsMan/SlideB/ResetB.connect("pressed", _on_reset_b_pressed)
	$ColorsMan/Slide_saturation/ResetSat.connect("pressed", _on_reset_sat_pressed)
	$ColorsMan/Slide_brightness/ResetBri.connect("pressed", _on_reset_bri_pressed)
	$ColorsMan/Slide_contrast/ResetCont.connect("pressed", _on_reset_cont_pressed)
	$ColorsMan/Slide_hue_shift/ResetHue.connect("pressed", _on_reset_hue_pressed)
	$ColorsMan/Slide_gamma/ResetGam.connect("pressed", _on_reset_gam_pressed)
func _process(delta: float) -> void:
	$Player.look_at(get_global_mouse_position())

func _highlight_part(part_name: String) -> void:
	if not $Player.has_node(part_name):
		return
	
	# Kill tween attivo se esiste
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	
	current_highlight = $Player.get_node(part_name)
	GlobalTweens.blink(current_highlight)
	
	active_tween = create_tween().parallel()
	for part in ["Body", "Wing", "Prop"]:
		var node = $Player.get_node(part)
		var target_alpha = 1.0 if part == part_name else 0.2
		active_tween.tween_property(node, "modulate:a", target_alpha, 0.3)


func _reset_highlight() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	
	var tw = create_tween().parallel()
	for part in ["Body", "Wing", "Prop"]:
		tw.tween_property($Player.get_node(part), "modulate:a", 1.0, 0.3)
	
	current_highlight = null
	active_tween = tw
	
# buttons #
func _on_body_mouse_entered() -> void:
	_highlight_part("Body")

func _on_wings_mouse_entered() -> void:
	_highlight_part("Wing")

func _on_prop_mouse_entered() -> void:
	_highlight_part("Prop")

func _on_body_mouse_exited() -> void:
	_reset_highlight()

func _on_wings_mouse_exited() -> void:
	_reset_highlight()

func _on_prop_mouse_exited() -> void:
	_reset_highlight()

func desapear():
	GlobalTweens.fade($Body, 1.0, 0.1, 0.2)
	GlobalTweens.fade($Wings, 1.0, 0.1, 0.4)
	GlobalTweens.fade($Prop, 1.0, 0.1, 0.3)
	GlobalTweens.fade($Player, 1.0, 0.1, 0.2)
	GlobalTweens.fade($ColorsMan, 0.0, 1.0, 1.0)
	var time = Timer.new()
	time.one_shot = true
	time.wait_time = 0.6
	# Collegamento corretto
	time.connect("timeout", Callable(self, "_on_wait_time"))
	# Aggiungi il Timer alla scena
	add_child(time)
	# Avvio
	time.start()

	
func _on_wait_time():
	GlobalTweens.fade($Body, 0.0, 1.0, 0.2)
	GlobalTweens.fade($Wings, 0.0, 1.0, 0.4)
	GlobalTweens.fade($Prop, 0.0, 1.0, 0.3)
	GlobalTweens.fade($Player, 0.0, 1.0, 0.2)

func _on_body_pressed() -> void:
	ship_part = "body"
	desapear()
	$BodyMan.show()
	GlobalTweens.fade($BodyMan, 0.0, 1.0, 0.8)
	
func _on_wings_pressed() -> void:
	ship_part = "wings"
	desapear()
	$WingsMan.show()
	GlobalTweens.fade($WingsMan, 0.0, 1.0, 0.8)
	
func _on_prop_pressed() -> void:
	ship_part = "prop"
	desapear()
	$PropMan.show()
	GlobalTweens.fade($PropMan, 0.0, 1.0, 0.8)
	

func _on_reset_r_pressed() -> void:
	var tw = create_tween()
	tw.tween_property($ColorsMan/SlideR, 'value', 1.0, 0.4)
	match ship_part:
		'body':
			Global.body_red_factor = 1.0
		'wings':
			Global.wings_red_factor = 1.0
		'prop':
			Global.prop_red_factor = 1.0
func _on_reset_g_pressed() -> void:
	var tw = create_tween()
	tw.tween_property($ColorsMan/SlideG, 'value', 1.0, 0.4)
	match ship_part:
		'body':
			Global.body_green_factor = 1.0
		'wings':
			Global.wings_green_factor = 1.0
		'prop':
			Global.prop_green_factor = 1.0
func _on_reset_b_pressed() -> void:
	var tw = create_tween()
	tw.tween_property($ColorsMan/SlideB, 'value', 1.0, 0.4)
	match ship_part:
		'body':
			Global.body_blue_factor = 1.0
		'wings':
			Global.wings_blue_factor = 1.0
		'prop':
			Global.prop_blue_factor = 1.0
func _on_reset_sat_pressed() -> void:
	var tw = create_tween()
	tw.tween_property($ColorsMan/Slide_saturation, 'value', 1.0, 0.4)
	match ship_part:
		'body':
			Global.body_saturation = 1.0
		'wings':
			Global.wings_saturation = 1.0
		'prop':
			Global.prop_saturation = 1.0
func _on_reset_bri_pressed() -> void:
	var tw = create_tween()
	tw.tween_property($ColorsMan/Slide_brightness, 'value', 0.0, 0.4)
	match ship_part:
		'body':
			Global.body_brightness = 0.0
		'wings':
			Global.wings_brightness = 0.0
		'prop':
			Global.prop_brightness = 0.0
func _on_reset_cont_pressed() -> void:
	var tw = create_tween()
	tw.tween_property($ColorsMan/Slide_contrast, 'value', 1.0, 0.4)
	match ship_part:
		'body':
			Global.body_contrast = 1.0
		'wings':
			Global.wings_contrast = 1.0
		'prop':
			Global.prop_contrast = 1.0
func _on_reset_hue_pressed() -> void:
	var tw = create_tween()
	tw.tween_property($ColorsMan/Slide_hue_shift, 'value', 0.0, 0.4)
	match ship_part:
		'body':
			Global.body_hue_shift = 0.0
		'wings':
			Global.wings_hue_shift = 0.0
		'prop':
			Global.prop_hue_shift = 0.0
func _on_reset_gam_pressed() -> void:
	var tw = create_tween()
	tw.tween_property($ColorsMan/Slide_gamma, 'value', 1.0, 0.4)
	match ship_part:
		'body':
			Global.body_gamma = 1.0
		'wings':
			Global.wings_gamma = 1.0
		'prop':
			Global.prop_gamma = 1.0


func _on_SlideR_value_changed(value: float) -> void:
	match ship_part:
		"body": 
			Global.body_red_factor = value
			$ColorsMan/SlideR/ValueR.text = str(Global.body_red_factor)
		"wings":
			Global.wings_red_factor = value
			$ColorsMan/SlideR/ValueR.text = str(Global.wings_red_factor)
		"prop":
			Global.prop_red_factor = value
			$ColorsMan/SlideR/ValueR.text = str(Global.prop_red_factor)
			
func _on_SlideG_value_changed(value: float) -> void:
	match ship_part:
		"body": 
			Global.body_green_factor = value
			$ColorsMan/SlideG/ValueG.text = str(Global.body_green_factor)
		"wings":
			Global.wings_green_factor = value
			$ColorsMan/SlideG/ValueG.text = str(Global.wings_green_factor)
		"prop":
			Global.prop_green_factor = value
			$ColorsMan/SlideG/ValueG.text = str(Global.prop_green_factor)
		
func _on_SlideB_value_changed(value: float) -> void:
	match ship_part:
		"body": 
			Global.body_blue_factor = value
			$ColorsMan/SlideB/ValueB.text = str(Global.body_blue_factor)
		"wings":
			Global.wings_blue_factor = value
			$ColorsMan/SlideB/ValueB.text = str(Global.wings_blue_factor)
		"prop":
			Global.prop_blue_factor = value
			$ColorsMan/SlideB/ValueB.text = str(Global.prop_blue_factor)
		
func _on_Slide_saturation_value_changed(value: float) -> void:
	match ship_part:
		"body": 
			Global.body_saturation = value
			$ColorsMan/Slide_saturation/ValueSat.text = str(Global.body_saturation)
		"wings":
			Global.wings_saturation = value
			$ColorsMan/Slide_saturation/ValueSat.text = str(Global.wings_saturation)
		"prop":
			Global.prop_saturation = value
			$ColorsMan/Slide_saturation/ValueSat.text = str(Global.prop_saturation)
		
func _on_Slide_brightness_value_changed(value: float) -> void:
	match ship_part:
		"body": 
			Global.body_brightness = value
			$ColorsMan/Slide_brightness/ValueBri.text = str(Global.body_brightness)
		"wings":
			Global.wings_brightness = value
			$ColorsMan/Slide_brightness/ValueBri.text = str(Global.wings_brightness)
		"prop":
			Global.prop_brightness = value
			$ColorsMan/Slide_brightness/ValueBri.text = str(Global.prop_brightness)
		
func _on_Slide_contrast_value_changed(value: float) -> void:
	match ship_part:
		"body": 
			Global.body_contrast = value
			$ColorsMan/Slide_contrast/ValueCont.text = str(Global.body_contrast)
		"wings":
			Global.wings_contrast = value
			$ColorsMan/Slide_contrast/ValueCont.text = str(Global.wings_contrast)
		"prop":
			Global.prop_contrast = value
			$ColorsMan/Slide_contrast/ValueCont.text = str(Global.prop_contrast)
		
func _on_Slide_hue_shift_value_changed(value: float) -> void:
	match ship_part:
		"body": 
			Global.body_hue_shift = value
			$ColorsMan/Slide_hue_shift/ValueHue.text = str(Global.body_hue_shift)
		"wings":
			Global.wings_hue_shift = value
			$ColorsMan/Slide_hue_shift/ValueHue.text = str(Global.wings_hue_shift)
		"prop":
			Global.prop_hue_shift = value
			$ColorsMan/Slide_hue_shift/ValueHue.text = str(Global.prop_hue_shift)
		
func _on_Slide_gamma_value_changed(value: float) -> void:
	match ship_part:
		"body": 
			Global.body_gamma = value
			$ColorsMan/Slide_gamma/ValueGam.text = str(Global.body_gamma)
		"wings":
			Global.wings_gamma = value
			$ColorsMan/Slide_gamma/ValueGam.text = str(Global.wings_gamma)
		"prop":
			Global.prop_gamma = value
			$ColorsMan/Slide_gamma/ValueGam.text = str(Global.prop_gamma)

func _on_close_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")

func _close_editor() -> void:
	$Trs.play("close")

func _on_trs_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close": 
		get_tree().change_scene_to_file("res://Gres/Scenes/UI/craft_edit_ui.tscn")
