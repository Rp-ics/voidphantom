extends Control

# === CAMERA INFO (colorato con BBCode) ===
const CAMERA_INFO = {
	"shake_strength": """[color=#ff7b00]SHAKE STRENGTH – Camera shake intensity[/color]
Controls how strongly the camera shakes during hits or intense events.
[color=#00c8ff]Low[/color] = barely noticeable vibration.
[color=#ff3b3b]High[/color] = powerful cinematic shake that can be overwhelming.""",

	"smoothing_speed": """[color=#ff7b00]SMOOTHING SPEED – Camera follow responsiveness[/color]
How quickly the camera catches up to the player.
[color=#00c8ff]Low[/color] = soft but laggy movement.
[color=#ff3b3b]High[/color] = snappy and responsive but less smooth.""",

	"lookahead_distance": """[color=#ff7b00]LOOKAHEAD DISTANCE – Forward offset[/color]
How far the camera shifts ahead in the player’s movement direction.
[color=#00c8ff]Zero[/color] = always centered.
[color=#ff3b3b]High[/color] = player appears farther back on screen, giving more view ahead.""",

	"lookahead_speed": """[color=#ff7b00]LOOKAHEAD SPEED – Lookahead movement speed[/color]
How fast the camera transitions to the lookahead position.
[color=#00c8ff]Low[/color] = slow, smooth adjustment.
[color=#ff3b3b]High[/color] = quick, sharp transitions that may feel twitchy.""",

	"shake_decay": """[color=#ff7b00]SHAKE DECAY – Shake fade-out speed[/color]
Controls how quickly the camera shake effect fades.
[color=#00c8ff]Low[/color] = long-lasting vibration.
[color=#ff3b3b]High[/color] = fast fade-out for a short, punchy effect."""
}


func prew():
	$CameraL/ShakeStr.value = Global.shake_strength
	$CameraL/SmoothSpd.value = Global.smoothing_speed
	$CameraL/LookDis.value = Global.lookahead_distance
	$CameraL/LookSpd.value = Global.lookahead_speed
	$CameraL/ShakeDec.value = Global.shake_decay

	$CameraL/ShakeStrL.text = "SHAKE STRENGTH: " + str(Global.shake_strength)
	$CameraL/SmoothSpdL.text = "SMOOTHING SPEED: " + str(Global.smoothing_speed)
	$CameraL/LookDisL.text = "LOOKAHEAD DISTANCE: " + str(Global.lookahead_distance)
	$CameraL/LookSpdL.text = "LOOKAHEAD SPEED: " + str(Global.lookahead_speed)
	$CameraL/ShakeDecL.text = "SHAKE DECAY: " + str(Global.shake_decay)


func _ready() -> void:
	prew()
	$ButtonsManager/BackGM.connect("pressed", on_back_pressed)
	$CameraL/Reset.connect("pressed", _on_reset_pressed)

	# Mappa nodi-info
	var info_map = {
		$CameraL/ShakeStrL/ShakeInfo: "shake_strength",
		$CameraL/SmoothSpdL/SmoothSpdInfo: "smoothing_speed",
		$CameraL/LookDisL/LookDisInfo: "lookahead_distance",
		$CameraL/LookSpdL/LookSpdInfo: "lookahead_speed",
		$CameraL/ShakeDecL/ShakeDecInfo: "shake_decay"
	}

	for node in info_map.keys():
		node.connect("mouse_entered", func(): _show_info(info_map[node]))
		node.connect("mouse_exited", _hide_info)

	$CameraL/ShakeStr.connect("value_changed", _on_shakestr_value_changed)
	$CameraL/SmoothSpd.connect("value_changed", _on_smootspd_value_changed)
	$CameraL/LookDis.connect("value_changed", _on_lookdis_value_changed)
	$CameraL/LookSpd.connect("value_changed", _on_lookspd_value_changed)
	$CameraL/ShakeDec.connect("value_changed", _on_shakedec_value_changed)


func on_back_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))


func _on_reset_pressed() -> void:
	var tw = create_tween()
	tw.tween_property($CameraL, "scale", Vector2(1.0, 1.1), 0.3)
	tw.tween_property($CameraL, "scale", Vector2(1.0, 1.0), 0.3)

	Global.shake_strength = 20.0
	Global.smoothing_speed = 8.0
	Global.lookahead_distance = 10.0
	Global.lookahead_speed = 6.0
	Global.shake_decay = 5.0
	prew()


func _on_shakestr_value_changed(value: float) -> void:
	Global.shake_strength = value
	$CameraL/ShakeStrL.text = "SHAKE STRENGTH: " + str(value)

func _on_smootspd_value_changed(value: float) -> void:
	Global.smoothing_speed = value
	$CameraL/SmoothSpdL.text = "SMOOTHING SPEED: " + str(value)

func _on_lookdis_value_changed(value: float) -> void:
	Global.lookahead_distance = value
	$CameraL/LookDisL.text = "LOOKAHEAD DISTANCE: " + str(value)

func _on_lookspd_value_changed(value: float) -> void:
	Global.lookahead_speed = value
	$CameraL/LookSpdL.text = "LOOKAHEAD SPEED: " + str(value)

func _on_shakedec_value_changed(value: float) -> void:
	Global.shake_decay = value
	$CameraL/ShakeDecL.text = "SHAKE DECAY: " + str(value)


func _show_info(key: String) -> void:
	$CameraL/InfoS.bbcode_enabled = true
	$CameraL/InfoS.text = CAMERA_INFO[key]
	$CameraL/InfoS.modulate = Color(1,1,1,0)
	$CameraL/InfoS.show()
	var tw = create_tween()
	tw.tween_property($CameraL/InfoS, "modulate:a", 1, 0.3)


func _hide_info() -> void:
	$CameraL/InfoS.hide()


func _on_map_pressed() -> void:
	Global.can_show_map = true
