extends Node2D

func color_check():
	$WingsSprite.material.set_shader_parameter("red_factor",   Global.wings_red_factor)
	$WingsSprite.material.set_shader_parameter("green_factor", Global.wings_green_factor)
	$WingsSprite.material.set_shader_parameter("blue_factor",  Global.wings_blue_factor)
	$WingsSprite.material.set_shader_parameter("saturation",   Global.wings_saturation)
	$WingsSprite.material.set_shader_parameter("brightness",   Global.wings_brightness)
	$WingsSprite.material.set_shader_parameter("contrast",     Global.wings_contrast)
	$WingsSprite.material.set_shader_parameter("hue_shift",    Global.wings_hue_shift)
	$WingsSprite.material.set_shader_parameter("gamma",        Global.wings_gamma)

func _ready() -> void:
	var shader    = preload("res://Gres/Shaders/ColorShader.gdshader")
	var mat_wings = ShaderMaterial.new()
	mat_wings.shader       = shader
	$WingsSprite.material  = mat_wings

	# BUGFIX: Solo il player locale carica la propria texture e colori da Global.
	# Se tutti i nodi Wings caricano da Global indipendentemente,
	# le ali dell'avversario mostrano la texture e i colori del computer locale,
	# rendendo il personaggio dell'avversario identico al proprio.
	# Il player remoto riceve la texture corretta via _apply_skin() in mp_player.gd.
	if not get_parent() or get_parent().is_multiplayer_authority():
		var wing_path = "res://Gres/Assets/player/wings/wing_%s.png" % Global.texture_wing
		$WingsSprite.texture = load(wing_path)
		color_check()
