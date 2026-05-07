extends Node2D


func _ready() -> void:
	Global.player_hp = 1
	Global.player_stamina = 1
	var tween = create_tween()
	tween.tween_method(
		func(v): Global.player_hp = v,
		Global.player_hp,
		Global.player_max_hp,
		1.0 # durata
	)
	tween.tween_method(
		func(v): Global.player_stamina = v,
		Global.player_stamina,
		Global.player_max_stamina,
		1.0
	)
