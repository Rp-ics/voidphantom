extends StaticBody2D




func _process(delta: float) -> void:
	$up.position.x = $"../Player".position.x
	$down.position.x = $"../Player".position.x
	$right.position.y = $"../Player".position.y
	$left.position.y = $"../Player".position.y
	
	
	
