extends Area2D

@export var speed := 350.0
@export var damage := 15.0
@export var max_life := 1.5   # vita breve
var direction := Vector2.ZERO

var life_timer := 0.0

func _ready() -> void:
	add_to_group("p_bullet")

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	life_timer += delta
	if life_timer >= max_life:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
