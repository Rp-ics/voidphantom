extends Area2D
# ================================================================
# BulletPvP — Proiettile per la modalità PvP
# Aggiungi i tuoi tipi speciali dentro _setup_by_type()
# ================================================================

var damage:          float   = 20.0
var speed:           float   = 700.0
var direction:       Vector2 = Vector2.RIGHT
var owner_peer_id:   int     = 0
var projectile_type: String  = "line"
var max_life:        float   = 3.0

func _ready() -> void:
	rotation = direction.angle()
	_setup_by_type()
	var t = Timer.new()
	t.wait_time = max_life
	t.one_shot  = true
	t.autostart = true
	t.timeout.connect(queue_free)
	add_child(t)

func _setup_by_type() -> void:
	# Aggiungi qui i tuoi tipi PvP
	# match projectile_type:
	#   "fast":   speed *= 1.8
	#   "spread": direction = direction.rotated(randf_range(-0.3, 0.3))
	pass

func _physics_process(_delta: float) -> void:
	position += direction.normalized() * speed * _delta
	if _is_out_of_bounds():
		queue_free()

func _is_out_of_bounds() -> bool:
	var cam = get_viewport().get_camera_2d()
	if not cam:
		return false
	var vp_size = get_viewport_rect().size
	var rect    = Rect2(cam.global_position - vp_size * 0.5, vp_size)
	return not rect.grow(200).has_point(global_position)

func _on_body_entered(body: Node) -> void:
	if not body is CharacterBody2D:
		return
	if not body.has_method("take_damage_rpc"):
		return
	if body.peer_id == owner_peer_id:
		return
	body.take_damage_rpc.rpc_id(body.peer_id, damage, owner_peer_id)
	queue_free()
