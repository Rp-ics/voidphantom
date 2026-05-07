extends Node2D
class_name GaiaLaser

@export var rotation_speed: float = 4.0
@export var damage: int = 10
@export var laser_length: float = 200.0
@export var laser_width: float = 6.0
@export var lifetime: float = 5.0
@export var color: Color = Color(0.2, 1.0, 0.2, 0.8) # verde energetico
@export var flicker_speed: float = 0.08

var flicker_time := 0.0
var active := true

@onready var ray: RayCast2D = $RayCast2D
@onready var line: Line2D = $Line2D

func _ready() -> void:
	ray.target_position = Vector2(laser_length, 0)
	line.width = laser_width
	line.default_color = color
	line.clear_points()
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2(laser_length, 0))
	
	# autodistruzione
	await get_tree().create_timer(lifetime).timeout
	_fade_out()

func _process(delta: float) -> void:
	if not active:
		return

	rotation += rotation_speed * delta
	
	# effetto "flicker"
	flicker_time += delta
	if flicker_time >= flicker_speed:
		flicker_time = 0.0
		line.visible = not line.visible
	
	# rileva collisione e infligge danno
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.is_in_group("player"):
			Global.player_hp -= damage
			#if collider.has_method("_on_damage"):
				#collider._on_damage(damage)

func _fade_out() -> void:
	active = false
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.8)
	await tween.finished
	queue_free()
