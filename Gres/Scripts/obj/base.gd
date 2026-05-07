extends CharacterBody2D

@export var damage_per_hit: int = 1
@export var max_shield: int = 100
var current_damaged: int = 0

@onready var hp_bar = $HPB
@onready var sprite = $Sprite
@onready var effect_scene = preload("res://Gres/Scenes/Effects/expl_p.tscn")


func _process(_delta: float) -> void:
	hp_bar.max_value = max_shield
	hp_bar.value = current_damaged
	if Global.base_hurt:
		Global.base_hurt = false
		damage()
	_update_sprite_frame()

func _update_sprite_frame() -> void:
	var percent = float(current_damaged) / max_shield

	if percent <= 0.0:
		sprite.frame = 0
	elif percent <= 0.125:
		sprite.frame = 1
	elif percent <= 0.25:
		sprite.frame = 2
	elif percent <= 0.375:
		sprite.frame = 3
	elif percent <= 0.5:
		sprite.frame = 4
		GlobalTweens.deactivate($coll)
	elif percent <= 0.625:
		sprite.frame = 5
	elif percent <= 0.75:
		sprite.frame = 6
	elif percent <= 0.875:
		sprite.frame = 7
	else:
		sprite.frame = 8

	
func damage():
	current_damaged += damage_per_hit
	current_damaged = clamp(current_damaged, 0, max_shield)

	# Effetto visivo impatto
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)

	# Random offset tra 20 e 50 px in una direzione casuale
	var dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var dist = randf_range(20.0, 50.0)
	var offset = dir * dist

	# Posizionamento e scala
	effect.global_position = global_position + offset
	effect.scale = Vector2.ONE * randf_range(0.8, 1.5)


	if current_damaged >= max_shield:
		_on_base_destroyed()


func _on_base_destroyed() -> void:
	GlobalTweens.deactivate($coll)
	GlobalTweens.deactivate($coll1)
	GlobalTweens.blink($".")
	Global.player_hp -= Global.player_hp
	Global.player_dead = true
	
