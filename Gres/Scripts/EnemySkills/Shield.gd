extends EnemySkill

#@export var shield_min_duration: float = 4.0
#@export var shield_max_duration: float = 8.0
#
#var shield_fx: Node2D = null
#
func activate():
	if enemy == null:
		return
	
	if enemy.is_shielded:
		return # già attivo
	#
	## attiva scudo
	#enemy.is_shielded = true
	## durata random
	#var duration = randf_range(shield_min_duration, shield_max_duration)
	#
	#var t = get_tree().create_timer(duration)
	#await t.timeout
	#
	## disattiva
	#enemy.is_shielded = false
	#if shield_fx and shield_fx.is_inside_tree():
		#shield_fx.queue_free()
