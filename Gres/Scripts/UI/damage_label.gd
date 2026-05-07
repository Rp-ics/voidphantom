extends Label

var float_height: float = 50.0
var duration: float = 0.8

func show_damage(dmg: int, start_pos: Vector2, is_crit: bool = false) -> void:
	text = str(dmg)
	position = start_pos
	pivot_offset = size / 2.0
	
	if is_crit:
		text = "💥 " + str(dmg) + "!"
		modulate = Color(1, 0.2, 0.2)   # rosso crit
		float_height = 70.0
	else:
		modulate = Color(1, 0.9, 0.1)   # giallo normale
	
	scale = Vector2(0.1, 0.1)  # parte piccolo
	modulate.a = 1.0

	var tween = create_tween()
	tween.set_parallel(false)

	# FASE 1 — punch in: esplode veloce
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# FASE 2 — settle + sale + svanisce (parallele)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(self, "position", start_pos + Vector2(randf_range(-15, 15), -float_height), duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration)\
		.set_delay(duration * 0.4)  # resta leggibile un po'

	tween.set_parallel(false)
	tween.tween_callback(queue_free)
