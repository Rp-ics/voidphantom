extends Node2D

# =====================
# CONFIGURAZIONE
# =====================

# Lista dei body totali
const MAX_BODY = 15



# Lista di quelli sbloccati dal player
# (questa in futuro la carichi dal salvataggio)
var unlocked_bodies = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]


func _ready() -> void:
	$BodyIcon/Right.connect('pressed', on_right_pressed)
	$BodyIcon/Left.connect('pressed', on_left_pressed)
	$CloseBody.connect('pressed', on_close_body_pressed)
	var body_path = "res://Gres/Assets/player/body/body_%s.png" % Global.texture_body
	$BodyIcon/icon.texture = load(body_path)

# =====================
# FUNZIONI
# =====================
func _show_body():
	var body_path = "res://Gres/Assets/player/body/body_%s.png" % Global.texture_body
	$BodyIcon/icon.texture = load(body_path)


func _get_next_body(direction: int) -> int:
	var next = Global.texture_body + direction
	
	# Loop circolare
	if next > MAX_BODY:
		next = 1
	elif next < 1:
		next = MAX_BODY
	
	# Se è bloccato e non sbloccato, salta finché trovi uno valido
	while next in Global.LOCKED_BODIES and next not in unlocked_bodies:
		next += direction
		if next > MAX_BODY:
			next = 1
		elif next < 1:
			next = MAX_BODY
	
	return next

func _process(delta: float) -> void:
	if Input.is_action_pressed("rotate"):
		$Player.look_at(get_global_mouse_position())

func on_right_pressed() -> void:
	Global.texture_body = _get_next_body(+1)
	_show_body()


func on_left_pressed() -> void:
	Global.texture_body = _get_next_body(-1)
	_show_body()


func apear():
	GlobalTweens.fade($Player/Body, 0.0, 1.0, 0.2)
	GlobalTweens.fade($Player/Prop, 0.0, 1.0, 0.2)
	GlobalTweens.fade($Player, 0.0, 1.0, 0.2)
	GlobalTweens.fade($BodyIcon, 0.0, 1.0, 0.2)

func on_close_body_pressed() -> void:
	GlobalTweens.blink($Player/Body, 3, 0.3)
	GlobalTweens.blink($Player/Wing, 5, 0.1)
	GlobalTweens.blink($Player/Prop, 6, 0.2)
	GlobalTweens.blink($BodyIcon)
	GlobalTweens.fade($Player/Body, 1.0, 0.0, 0.2)
	GlobalTweens.fade($Player/Prop, 1.0, 0.0, 0.4)
	GlobalTweens.fade($Player, 1.0, 0.0, 0.6)
	GlobalTweens.fade($BodyIcon, 1.0, 0.0, 0.8)
	GlobalTweens.fade($"../ColorsMan", 1.0, 0.0, 1.2)
	await  get_tree().create_timer(1.0).timeout
	self.hide()
	apear()
