extends Node2D

@export var fx_node_path: NodePath = ""
@export var enable_dash := true
@export var dash_speed := 600.0
@export var dash_duration := 0.15
@export var dash_cooldown := 1.0

var dash_timer := 0.0
var dash_cd_timer := 0.0
var is_dashing := false
var fx_node: Node = null

func color_check():
	$PropulsorSprite.material.set_shader_parameter("red_factor", Global.prop_red_factor)
	$PropulsorSprite.material.set_shader_parameter("green_factor", Global.prop_green_factor)
	$PropulsorSprite.material.set_shader_parameter("blue_factor", Global.prop_blue_factor)
	$PropulsorSprite.material.set_shader_parameter("saturation", Global.prop_saturation)
	$PropulsorSprite.material.set_shader_parameter("brightness", Global.prop_brightness)
	$PropulsorSprite.material.set_shader_parameter("contrast", Global.prop_contrast)
	$PropulsorSprite.material.set_shader_parameter("hue_shift", Global.prop_hue_shift)
	$PropulsorSprite.material.set_shader_parameter("gamma", Global.prop_gamma)
	
func _ready():
	var prop_path = "res://Gres/Assets/player/propuls/prop_%s.png" % Global.texture_prop
	$PropulsorSprite.texture = load(prop_path)
	
	var shader = preload("res://Gres/Shaders/ColorShader.gdshader")
	
	var mat_prop = ShaderMaterial.new()
	mat_prop.shader = shader
	$PropulsorSprite.material = mat_prop
	color_check()

	
	if has_node(fx_node_path):
		fx_node = get_node(fx_node_path)

func _process(delta):
	if fx_node:
		fx_node.visible = is_moving()

	# Timer dash
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			stop_dash()
	else:
		dash_cd_timer = max(dash_cd_timer - delta, 0.0)

	# Input per dash
	if enable_dash and Input.is_action_just_pressed("dash") and dash_cd_timer <= 0.0:
		start_dash()

func is_moving() -> bool:
	var player = get_parent()
	if player and player.has_method("get_current_velocity"):
		return player.get_current_velocity().length() > 10
	return false

func start_dash():
	if Global.player_hp > 0:
		is_dashing = true
		dash_timer = dash_duration
		dash_cd_timer = dash_cooldown
		$"../Audio/dash".play()
		
		var player = get_parent()
		if player:
			# ⚠️ Fixato da input_vector a input_direction
			var dir = player.input_direction
			if dir == Vector2.ZERO:
				dir = Vector2.UP  # default
			player.velocity = dir.normalized() * dash_speed
			

func stop_dash():
	is_dashing = false
