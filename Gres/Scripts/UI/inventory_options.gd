extends Control

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		get_tree().paused = true
		$".".show()
		GlobalTweens.fade($".", 0, 1, 0.5)

func _on_close_inventory_pressed() -> void:
	get_tree().paused = false
	GlobalTweens.fade($".", 1, 0, 0.5)
	await get_tree().create_timer(0.6).timeout
	self.hide()
