extends Camera2D

@export var target_path: NodePath

var target: Node2D
var velocity := Vector2.ZERO
var shake_offset := Vector2.ZERO

@export var enable_lookahead := true
@export var current := true
const CONFIG_PATH := "user://config_camera.cfg"


func _ready():
	current = true
	if has_node(target_path):
		target = get_node(target_path)
	
	load_settings()

func _process(delta):
	if not target:
		return
	
	var desired_position = target.global_position

	if enable_lookahead and target.has_method("get_velocity"):
		var dir = target.get_velocity().normalized()
		desired_position += dir * Global.lookahead_distance

	if Global.shake_strength > 0:
		var rand = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		).normalized()
		shake_offset = rand * Global.shake_strength
		Global.shake_strength = lerp(Global.shake_strength, 0.0, delta * Global.shake_decay)
	else:
		shake_offset = Vector2.ZERO

	global_position = global_position.lerp(
		desired_position + shake_offset,
		delta * Global.smoothing_speed
	)

# ⚡ Chiamabile per causare lo shake
func shake(strength: float = 10.0):
	Global.shake_strength = strength

# 🔁 Carica dal file
func load_settings():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	if err != OK:
		print("⚠ Nessun config camera trovato, uso valori di default.")
		return

	Global.smoothing_speed = config.get_value("camera", "smoothing_speed", Global.smoothing_speed)
	Global.lookahead_distance = config.get_value("camera", "lookahead_distance", Global.lookahead_distance)
	Global.lookahead_speed = config.get_value("camera", "lookahead_speed", Global.lookahead_speed)
	enable_lookahead = config.get_value("camera", "enable_lookahead", enable_lookahead)
	Global.shake_decay = config.get_value("camera", "shake_decay", Global.shake_decay)

# 💾 Salva nel file
func save_settings():
	var config = ConfigFile.new()
	config.set_value("camera", "smoothing_speed", Global.smoothing_speed)
	config.set_value("camera", "lookahead_distance", Global.lookahead_distance)
	config.set_value("camera", "lookahead_speed", Global.lookahead_speed)
	config.set_value("camera", "enable_lookahead", enable_lookahead)
	config.set_value("camera", "shake_decay", Global.shake_decay)

	var err = config.save(CONFIG_PATH)
	if err != OK:
		push_error("❌ Errore nel salvataggio config camera.")
