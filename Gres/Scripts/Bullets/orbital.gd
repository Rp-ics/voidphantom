extends Area2D
class_name Orbital

@export var base_radius := 120.0       # valore che puoi cambiare da editor
@export var alt_radius := 200.0        # valore alternativo, sempre editabile
@export var speed := 2.0

var damage = GlobalWeapons.weapons["VOIDLANCE"]['rare']["damage"]
var start_angle := 0.0
var radius := 120.0
var time := 1.0

func _ready() -> void:
	# 50% probabilità 120, 50% 200
	radius = base_radius if randi() % 100 < 50 else alt_radius

func _process(delta: float) -> void:
	time += delta * speed
	if not get_parent():
		queue_free()
		return

	global_position = get_parent().global_position \
		+ Vector2(cos(time + start_angle), sin(time + start_angle)) * radius

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
