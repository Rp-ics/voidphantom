extends Sprite2D

# =======================
# CONFIG
# =======================

@export var float_range: float = 800.0
@export var float_speed: float = 10.0

var tween: Tween
var start_position: Vector2


# =======================
# READY
# =======================
func _ready():
	start_position = Vector2(self.position.x, self.position.y)
	_start_floating()

# =======================
# FLOATING
# =======================
func _start_floating():
	if tween:
		tween.kill()
	
	tween = get_tree().create_tween()
	_move_randomly()
	tween.tween_callback(_start_floating)

func _move_randomly():
	var target_offset = Vector2(randf_range(-float_range, float_range), randf_range(-float_range, float_range))
	var target_position = start_position + target_offset
	tween.tween_property(self, "position", target_position, float_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start_position, float_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
