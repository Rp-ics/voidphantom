extends Node2D


func _process(delta: float) -> void:
	$"../light".global_position = $"../Player".global_position
