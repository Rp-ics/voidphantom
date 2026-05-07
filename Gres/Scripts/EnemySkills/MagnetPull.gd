extends EnemySkill

@export var pull_strength: float = 200.0  # forza dell’attrazione
@export var pull_duration: float = 5.6    # durata della skill
@export var pull_range: float = 400.0     # raggio massimo dell’attrazione

func activate():
	if enemy == null:
		return
	
	enemy.is_using_skill = true  # blocca altri movimenti
	
	# Trova tutti i player
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		enemy.is_using_skill = false
		return
	
	var start_time = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_time < pull_duration * 1000:
		for player_node in players:
			var distance = enemy.global_position.distance_to(player_node.global_position)
			if distance <= pull_range:
				var dir = (enemy.global_position - player_node.global_position).normalized()
				player_node.global_position += dir * pull_strength * get_process_delta_time()
		await get_tree().process_frame
	
	enemy.is_using_skill = false
	deactivate()
