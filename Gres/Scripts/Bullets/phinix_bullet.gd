extends Area2D
class_name PhoenixBullet

@export var speed: float = 900.0
@export var damage: int = 10
var direction: Vector2 = Vector2.ZERO
var life_time: float = 0.0
var max_life: float = 3.0   # vive 3 secondi prima di svanire

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	life_time += delta
	if life_time >= max_life:
		queue_free()
	
	position -= direction * speed * delta

	# fuori schermo → delete
	if is_out_of_screen(200):
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

# --- Helper ---
func is_out_of_screen(margin: int = 200) -> bool:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return false
	var vp_size := get_viewport_rect().size * cam.zoom
	var half := vp_size * 0.5
	var screen_rect := Rect2(cam.global_position - half, vp_size)
	return not screen_rect.grow(margin).has_point(global_position)


func _on_anim_animation_finished(anim_name: StringName) -> void:
	queue_free()
