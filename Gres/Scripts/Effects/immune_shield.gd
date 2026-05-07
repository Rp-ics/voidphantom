extends Node2D


func _ready() -> void:
	if GlobalStats.shield_bonus == 1:
		$shield.texture = load("res://Gres/Assets/Icons/shield_1.png")
	elif GlobalStats.shield_bonus == 2:
		$shield.texture = load("res://Gres/Assets/Icons/shield_2.png")
	elif GlobalStats.shield_bonus == 3:
		$shield.texture = load("res://Gres/Assets/Icons/shield_3.png")
	$queue.wait_time = Global.player_immunity_time
	$queue.start()

func _process(delta: float) -> void:
	self.position = Vector2(Global.PlayerX, Global.PlayerY)


func _on_queue_timeout() -> void:
	var tween = create_tween()
	tween.tween_property($shield, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_callback(queue_free)
