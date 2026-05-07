extends CharacterBody2D

@export var damage_per_hit: float = 1
@export var max_shield: int = 100
var current_damaged: int = 0
var can_dis = true
var dead = false
@onready var hp_bar1 = $HPB1
@onready var hp_bar2 = $HPB2
@onready var hp_bar3 = $HPB3
@onready var hp_bar4 = $HPB4
@onready var sprite = $Sprite
@onready var effect_scene = preload("res://Gres/Scenes/Effects/expl_p.tscn")


func _process(_delta: float) -> void:
	hp_bar1.max_value = max_shield
	hp_bar1.value = current_damaged
	hp_bar2.max_value = max_shield
	hp_bar2.value = current_damaged
	hp_bar3.max_value = max_shield
	hp_bar3.value = current_damaged
	hp_bar4.max_value = max_shield
	hp_bar4.value = current_damaged
	if Global.base_hurt:
		Global.base_hurt = false
		damage()
	_update_sprite_frame()

func _update_sprite_frame() -> void:
	var percent = float(current_damaged) / max_shield
	if percent <= 0.0:
		sprite.frame = 0
	elif percent <= 0.2:
		sprite.frame = 1
	elif percent <= 0.4:
		sprite.frame = 2
	elif percent <= 0.8:
		sprite.frame = 3
	else:
		sprite.frame = 4
	
func damage():
	current_damaged += damage_per_hit
	current_damaged = clamp(current_damaged, 0, max_shield)

	# Effetto visivo impatto
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)

	# Random offset tra 20 e 50 px in una direzione casuale
	var dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var dist = randf_range(100.0, 200.0)
	var offset = dir * dist

	# Posizionamento e scala
	effect.global_position = global_position + offset
	effect.scale = Vector2.ONE * randf_range(0.8, 1.5)

	if current_damaged >= max_shield and not dead:
		dead = true
		_on_base_destroyed()

func _on_base_destroyed() -> void:
	if can_dis:
		can_dis = false
		Global.base_wall_destroyed = true
		GlobalTweens.deactivate($coll)
		GlobalTweens.blink($".", 5, 0.1)
		queue_free()
	
