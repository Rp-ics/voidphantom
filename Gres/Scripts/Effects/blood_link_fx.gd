extends Node2D

var source: Node2D
var target: Node2D
var color := Color(1, 0, 0, 0.8)

@onready var line := $Line

func _ready():
	line.width = 4
	line.default_color = color
	set_process(true)

func setup(src: Node2D, trg: Node2D):
	source = src
	target = trg

func _process(delta):
	if not is_instance_valid(source) or not is_instance_valid(target):
		queue_free()
		return

	line.points = [
		source.global_position,
		target.global_position
	]
