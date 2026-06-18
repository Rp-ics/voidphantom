extends StaticBody2D


func _process(delta: float) -> void:
	$up.position.x = Global.shootX
	$down.position.x = Global.shootX
	$right.position.y = Global.shootY
	$left.position.y = Global.shootY
	
