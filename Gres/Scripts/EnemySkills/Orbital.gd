extends EnemySkill

@export var orbital_bullet: PackedScene = preload("res://Gres/Scenes/enemies/bullets/enemy_bullet_1.tscn")
@export var orbit_count: int = 8        # numero di proiettili orbitanti
@export var orbit_radius: float = 80.0  # distanza dal nemico
@export var orbit_speed: float = 2.0    # velocità di rotazione (rad/s)
@export var orbit_duration: float = 10.0 # tempo attivo della skill

var orbiters: Array = []
var active_time: float = 0.0

func activate():
	if enemy == null:
		return
	
	enemy.is_using_skill = true
	
	# crea orbiter attorno al nemico
	for i in range(orbit_count):
		var b = orbital_bullet.instantiate()
		b.global_position = enemy.global_position
		enemy.get_parent().add_child(b) # così non muoiono col nemico subito
		
		orbiters.append({
			"node": b,
			"angle": (TAU / orbit_count) * i
		})
	
	active_time = 0.0
	set_process(true)

func _process(delta: float) -> void:
	if orbiters.is_empty():
		return
	
	active_time += delta
	if active_time >= orbit_duration:
		# skill finita
		for o in orbiters:
			if is_instance_valid(o["node"]):
				o["node"].queue_free()
		orbiters.clear()
		enemy.is_using_skill = false
		deactivate()
		return
	
	# aggiorna posizione orbiter
	for o in orbiters:
		o["angle"] += orbit_speed * delta
		var offset = Vector2(cos(o["angle"]), sin(o["angle"])) * orbit_radius
		if is_instance_valid(o["node"]):
			o["node"].global_position = enemy.global_position + offset
