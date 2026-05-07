extends Area2D

@export var speed: float = 400.0         # velocità dell'effetto
@export var target_group: String = "player"  # il gruppo da seguire
@export var damage_percent: float = 0.5  # 50% HP massima per drain (opzionale)
@export var is_drain: bool = false       # se true fa drain HP

var target: Node = null

func _ready() -> void:
	# cerca il target più vicino nel gruppo
	var targets = get_tree().get_nodes_in_group(target_group)
	if targets.size() > 0:
		target = targets[0]  # puoi implementare nearest logic se vuoi
		look_at(target.global_position)

func _process(delta: float) -> void:
	if target and target.is_inside_tree():
		var dir = (target.global_position - global_position).normalized()
		position += dir * speed * delta
	else:
		queue_free()  # target sparito? self destruct

func _on_Area2D_body_entered(body: Node) -> void:
	if body.is_in_group(target_group):
		queue_free()
