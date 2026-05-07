extends EnemySkill

@export var dash_speed: float = 800.0
@export var dash_duration: float = 2.0

func activate():
	if enemy == null:
		return
	
	enemy.is_using_skill = true
	enemy.can_move = false
	
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		enemy.is_using_skill = false
		enemy.can_move = true
		return
	
	var target: Node2D = players[0]
	var min_dist = enemy.global_position.distance_to(target.global_position)
	for p in players:
		var d = enemy.global_position.distance_to(p.global_position)
		if d < min_dist:
			target = p
			min_dist = d
	
	var dir = (target.global_position - enemy.global_position).normalized()
	enemy.velocity = dir * dash_speed
	
	await get_tree().create_timer(dash_duration).timeout
	
	enemy.velocity = Vector2.ZERO
	enemy.can_move = true
	enemy.is_using_skill = false
	deactivate()
