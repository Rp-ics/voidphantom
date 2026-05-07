extends Node2D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var body_path = "res://Gres/Assets/player/body/body_%s.png" % Global.texture_body
	var wing_path = "res://Gres/Assets/player/wings/wing_%s.png" % Global.texture_wing
	var prop_path = "res://Gres/Assets/player/propuls/prop_%s.png" % Global.texture_prop
	
	$Body.texture = load(body_path)
	$Wing.texture = load(wing_path)
	$Prop.texture = load(prop_path)
	
	$Body.material.set_shader_parameter("red_factor", Global.body_red_factor)
	$Body.material.set_shader_parameter("green_factor", Global.body_green_factor)
	$Body.material.set_shader_parameter("blue_factor", Global.body_blue_factor)
	$Body.material.set_shader_parameter("saturation", Global.body_saturation)
	$Body.material.set_shader_parameter("brightness", Global.body_brightness)
	$Body.material.set_shader_parameter("contrast", Global.body_contrast)
	$Body.material.set_shader_parameter("hue_shift", Global.body_hue_shift)
	$Body.material.set_shader_parameter("gamma", Global.body_gamma)
	
	$Wing.material.set_shader_parameter("red_factor", Global.wings_red_factor)
	$Wing.material.set_shader_parameter("green_factor", Global.wings_green_factor)
	$Wing.material.set_shader_parameter("blue_factor", Global.wings_blue_factor)
	$Wing.material.set_shader_parameter("saturation", Global.wings_saturation)
	$Wing.material.set_shader_parameter("brightness", Global.wings_brightness)
	$Wing.material.set_shader_parameter("contrast", Global.wings_contrast)
	$Wing.material.set_shader_parameter("hue_shift", Global.wings_hue_shift)
	$Wing.material.set_shader_parameter("gamma", Global.wings_gamma)
	
	$Prop.material.set_shader_parameter("red_factor", Global.prop_red_factor)
	$Prop.material.set_shader_parameter("green_factor", Global.prop_green_factor)
	$Prop.material.set_shader_parameter("blue_factor", Global.prop_blue_factor)
	$Prop.material.set_shader_parameter("saturation", Global.prop_saturation)
	$Prop.material.set_shader_parameter("brightness", Global.prop_brightness)
	$Prop.material.set_shader_parameter("contrast", Global.prop_contrast)
	$Prop.material.set_shader_parameter("hue_shift", Global.prop_hue_shift)
	$Prop.material.set_shader_parameter("gamma", Global.prop_gamma)
