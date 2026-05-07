extends Area2D
class_name GaeaFragment

@export var orbit_radius := 80.0
@export var orbit_speed := 1.5
@export var lifetime := 6.0

var damage = GlobalWeapons.current_weapon["damage"]
var owner_ref: Node2D
var start_angle := 0.0
var time := 0.0

func init_fragment(owner: Node2D, start_angle_val: float, orbit_radius_val: float, orbit_speed_val: float, damage_val: float) -> void:
	owner_ref = owner
	start_angle = start_angle_val
	orbit_radius = orbit_radius_val
	orbit_speed = orbit_speed_val
	damage = damage_val
	add_to_group("p_bullet")

func _ready():
	orbit_radius = GlobalWeapons.weapons['GAEA CORE']['legendary']["pulse_radius"]
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	if not is_instance_valid(owner_ref):
		queue_free()
		return

	time += delta
	var angle = start_angle + time * orbit_speed
	global_position = owner_ref.global_position + Vector2(cos(angle), sin(angle)) * orbit_radius
	rotation = angle

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy") and area.has_method("take_damage"):
		area.take_damage(damage)
		area.queue_free()
	if area.is_in_group("e_bullet") and randi() % 100 < 10:
		area.queue_free()
		if randi() % 100 < 15:
			Global.player_stamina += 5

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		body.queue_free()
	
	if body.is_in_group("e_base") and body.has_method("damage"):
		body.damage()
		queue_free()
