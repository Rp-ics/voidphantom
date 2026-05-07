extends Area2D

@export var lifetime := 2.0 # implode dopo 2 secondi se non colpisce
@export var bullets := 10   # quanti proiettili spawnare
@export var bullet_scene: PackedScene

var collided := false

func _ready() -> void:
	# implode automatico dopo X secondi
	var t = Timer.new()
	t.wait_time = lifetime
	t.one_shot = true
	add_child(t)
	t.start()
	t.timeout.connect(_on_implode)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and not collided:
		collided = true
		_spawn_implosion()
		queue_free()


func _on_implode() -> void:
	if not collided:
		_spawn_implosion()
		queue_free()


func _spawn_implosion() -> void:
	if bullet_scene == null:
		bullet_scene = load("res://Gres/Scenes/weapons/bullet/void_shard.tscn")
	
	var center := global_position
	for i in bullets:
		var angle = (TAU / bullets) * i
		var b = bullet_scene.instantiate()
		get_parent().call_deferred("add_child", b)
		b.global_position = center
		# direzione verso centro (implosione)
		b.direction = (center - (center + Vector2.RIGHT.rotated(angle) * 32)).normalized()
