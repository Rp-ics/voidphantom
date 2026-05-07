extends Node2D

@export var float_range: float = 50.0  # Distanza massima dal punto iniziale
@export var float_speed: float = 4.0  # Velocità del movimento


@export_enum("asteroid", "rock", "sat") var object_type = "asteroid"
@export var __ : String = "Random Texture"
@export var is_random : bool = true
@export var f_h : bool = false
@export var f_v : bool = false
@export var ___ : String = "a=3 - r=3 - s=5"
@export_range(0, 10) var sprite_index : int = 0

var scale_tx = [0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0]
var xy = 1.0
var start_position: Vector2
var tween: Tween
var asteroid = [
	preload("res://Gres/Assets/obj/asteroid_1.png"),
	preload("res://Gres/Assets/obj/asteroid_2.png"),
	preload("res://Gres/Assets/obj/asteroid_3.png"),
	preload("res://Gres/Assets/obj/asteroid_4.png"),
	]
var rock = [
	preload("res://Gres/Assets/obj/rock_1.png"),
	preload("res://Gres/Assets/obj/rock_2.png"),
	preload("res://Gres/Assets/obj/rock_3.png"),
	preload("res://Gres/Assets/obj/rock_4.png"),
	]
var sat = [
	preload("res://Gres/Assets/obj/s_1.png"),
	preload("res://Gres/Assets/obj/s_2.png"),
	preload("res://Gres/Assets/obj/s_3.png"),
	preload("res://Gres/Assets/obj/s_4.png"),
	preload("res://Gres/Assets/obj/s_5.png"),
	preload("res://Gres/Assets/obj/s_6.png"),
	]
func _ready():
	randomize()
	
	if is_random:
		object_type = ["asteroid", "rock", "sat"].pick_random()
		if randi() % 100 < 50: $Sprite.flip_h = true
		if randi() % 100 < 50: $Sprite.flip_v = true
		xy = scale_tx.pick_random()
		
	$Sprite.scale = Vector2(xy, xy)
	$Sprite.flip_h = f_h
	$Sprite.flip_v = f_v
	
	match  object_type:
		"asteroid":
			if is_random:
				$Sprite.texture = asteroid.pick_random()
			else:
				$Sprite.texture = asteroid[sprite_index]
		"rock":
			if is_random:
				$Sprite.texture = rock.pick_random()
			else:
				$Sprite.texture = rock[sprite_index]
		"sat":
			if is_random:
				$Sprite.texture = sat.pick_random()
			else:
				$Sprite.texture = sat[sprite_index]
			
	start_position = position
	_start_floating()

func _start_floating():
	if tween:
		tween.kill()
	
	tween = get_tree().create_tween()
	_move_randomly()
	tween.tween_callback(_start_floating)  # Ripeti il movimento in loop

func _move_randomly():
	var target_offset = Vector2(randf_range(-float_range, float_range), randf_range(-float_range, float_range))
	var target_position = start_position + target_offset
	tween.tween_property(self, "position", target_position, float_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start_position, float_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
