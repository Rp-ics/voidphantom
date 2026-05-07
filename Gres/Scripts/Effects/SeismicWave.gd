extends Node2D

var max_radius := 120.0
var life := 0.25
var t := 0.0

func _process(delta):
	t += delta
	if t >= life:
		queue_free()
		return
	queue_redraw() # ridisegna

func _draw():
	var progress := t / life
	var radius = lerp(0.0, max_radius, progress)

	# cerchio esterno semi-trasparente (onda d'urto)
	var alpha := 1.0 - progress
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(1, 1, 1, alpha), 3.0)
