extends Node2D

# =====================
# CONFIGURAZIONE WINGS
# =====================

const MAX_WING = 15

var unlocked_wings = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]


func _ready() -> void:
	$WingsIcon/Right.connect('pressed', on_right_pressed)
	$WingsIcon/Left.connect('pressed', on_left_pressed)
	$CloseBody.connect('pressed', on_close_body_pressed)
	var wing_path = "res://Gres/Assets/player/wings/wing_%s.png" % Global.texture_wing
	$WingsIcon/icon.texture = load(wing_path)

# =====================
# FUNZIONI
# =====================

func _show_wing():
	var wing_path = "res://Gres/Assets/player/wings/wing_%s.png" % Global.texture_wing
	$WingsIcon/icon.texture = load(wing_path)


func _get_next_wing(direction: int) -> int:
	var next = Global.texture_wing + direction
	
	# Loop circolare
	if next > MAX_WING:
		next = 1
	elif next < 1:
		next = MAX_WING
	
	# Skip di quelli bloccati non sbloccati
	while next in Global.LOCKED_WINGS and next not in unlocked_wings:
		next += direction
		if next > MAX_WING:
			next = 1
		elif next < 1:
			next = MAX_WING
	
	return next


func _process(delta: float) -> void:
	if Input.is_action_pressed("rotate"):
		$Player.look_at(get_global_mouse_position())

func on_right_pressed() -> void:
	Global.texture_wing = _get_next_wing(+1)
	_show_wing()


func on_left_pressed() -> void:
	Global.texture_wing = _get_next_wing(-1)
	_show_wing()

func apear():
	GlobalTweens.fade($Player/Body, 0.0, 1.0, 0.2)
	GlobalTweens.fade($Player/Prop, 0.0, 1.0, 0.2)
	GlobalTweens.fade($Player, 0.0, 1.0, 0.2)
	GlobalTweens.fade($WingsIcon, 0.0, 1.0, 0.2)
	
func on_close_body_pressed() -> void:
	GlobalTweens.blink($Player/Body, 3, 0.3)
	GlobalTweens.blink($Player/Wing, 5, 0.1)
	GlobalTweens.blink($Player/Prop, 6, 0.2)
	GlobalTweens.blink($WingsIcon)
	GlobalTweens.fade($Player/Body, 1.0, 0.0, 0.2)
	GlobalTweens.fade($Player/Prop, 1.0, 0.0, 0.4)
	GlobalTweens.fade($Player, 1.0, 0.0, 0.6)
	GlobalTweens.fade($WingsIcon, 1.0, 0.0, 0.8)
	GlobalTweens.fade($"../ColorsMan", 1.0, 0.0, 1.2)
	await  get_tree().create_timer(1.0).timeout
	self.hide()
	apear()
	
