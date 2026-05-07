extends Area2D
class_name ImplosionShard

@export var speed: float = 400.0
@export var damage: float = 12.0
@export var max_life: float = 1.5   # vita breve

var direction: Vector2 = Vector2.ZERO
var life_timer: float = 0.0

func _ready() -> void:
	add_to_group("p_bullet")
	

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	life_timer += delta
	if life_timer >= max_life:
		queue_free()
	
	# fuori schermo → free
	if is_out_of_screen(200):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

# --- helper ---
func is_out_of_screen(margin: int = 200) -> bool:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return false
	var vp_size := get_viewport_rect().size * cam.zoom
	var half := vp_size * 0.5
	var screen_rect := Rect2(cam.global_position - half, vp_size)
	return not screen_rect.grow(margin).has_point(global_position)
