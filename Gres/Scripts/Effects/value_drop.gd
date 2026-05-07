extends Node2D

func _ready() -> void:
	
	$explossionG.emitting = true
	$explossionS1.emitting = true
	$explossionS2.emitting = true
	$explossionS3.emitting = true
	$explossionS4.emitting = true
	$explossionS5.emitting = true
	$Timer.start()


func _on_timer_timeout() -> void:
	queue_free()
