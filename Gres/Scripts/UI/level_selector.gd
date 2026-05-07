extends Control

@export var markers: Array[Marker2D] = []   # lista di Marker2D nell'editor
var current_index: int = 0

var loop_tween: Tween
var move_tween: Tween

var text_rewards = {
	'level_1': {
		'easy':
			"""
			[center]
			[table=4]

			[cell]2%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/pfp/icons/wrath_1.png[/img][/cell]

			[cell]10%[/cell]
			[cell][img=25]res://Gres/Assets/Icons/parts/crystal_pack_2.png[/img][/cell]

			[cell]50%[/cell]
			[cell][img=20]res://Gres/Assets/obj/tablet_2.png[/img][/cell]

			[cell]100%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/parts/gold_icon_1.png[/img][/cell]
			[/table]
			[/center]
			""",
		"normal":
			"""
			[center]
			[table=4]

			[cell]2%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/pfp/icons/wrath_1.png[/img][/cell]

			[cell]5%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/pfp/icons/wrath_2.png[/img][/cell]

			[cell]15%[/cell]
			[cell][img=25]res://Gres/Assets/Icons/parts/crystal_pack_2.png[/img][/cell]

			[cell]70%[/cell]
			[cell][img=20]res://Gres/Assets/obj/tablet_2.png[/img][/cell]

			[cell]100%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/parts/gold_icon_1.png[/img][/cell]

			[cell]0.1%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/exotic_icon.png[/img][/cell]
			[/table]
			[/center]
			""",
		"hard":
			"""
			[center]
			[table=4]

			[cell]2%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/pfp/icons/wrath_1.png[/img][/cell]

			[cell]5%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/pfp/icons/wrath_2.png[/img][/cell]

			[cell]10%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/pfp/icons/wrath_3.png[/img][/cell]

			[cell]20%[/cell]
			[cell][img=25]res://Gres/Assets/Icons/parts/crystal_pack_2.png[/img][/cell]

			[cell]90%[/cell]
			[cell][img=20]res://Gres/Assets/obj/tablet_2.png[/img][/cell]

			[cell]100%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/parts/gold_icon_1.png[/img][/cell]

			[cell]0.15%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/exotic_icon.png[/img][/cell]
			[/table]
			[/center]
			"""
	},
	'level_2': {
		'easy':
			"""
			[center]
			[table=4]

			[cell]20%[/cell]
			[cell][img=25]res://Gres/Assets/Icons/parts/crystal_pack_2.png[/img][/cell]

			[cell]2%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/pfp/icons/wrath_1.png[/img][/cell]

			[cell]50%[/cell]
			[cell][img=20]res://Gres/Assets/obj/tablet_2.png[/img][/cell]

			[cell]100%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/parts/gold_icon_1.png[/img][/cell]
			[/table]
			[/center]
			""",
		"normal":
			"""
			[center]
			[table=4]

			[cell]20%[/cell]
			[cell][img=25]res://Gres/Assets/Icons/parts/crystal_pack_2.png[/img][/cell]

			[cell]2%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/pfp/icons/wrath_1.png[/img][/cell]

			[cell]50%[/cell]
			[cell][img=20]res://Gres/Assets/obj/tablet_2.png[/img][/cell]

			[cell]100%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/parts/gold_icon_1.png[/img][/cell]
			[/table]
			[/center]
			""",
		"hard":
			"""
			[center]
			[table=4]

			[cell]20%[/cell]
			[cell][img=25]res://Gres/Assets/Icons/parts/crystal_pack_2.png[/img][/cell]

			[cell]2%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/pfp/icons/wrath_1.png[/img][/cell]

			[cell]50%[/cell]
			[cell][img=20]res://Gres/Assets/obj/tablet_2.png[/img][/cell]

			[cell]100%[/cell]
			[cell][img=20]res://Gres/Assets/Icons/parts/gold_icon_1.png[/img][/cell]
			[/table]
			[/center]
			"""
	},
}

var level = "level_1"

var input_locked: bool = false

func _ready() -> void:
	Global.mode = "dungeon"
	$Buttons/Next.connect("pressed", _on_next_button_pressed)
	$Buttons/Back.connect("pressed", _on_back_button_pressed)
	$Buttons/Select.connect("pressed", _on_select_button_pressed)
	
	$Buttons/dificulty/Easy.connect("pressed", on_easy_pressed)
	$Buttons/dificulty/Normal.connect("pressed", on_normal_pressed)
	$Buttons/dificulty/Hard.connect("pressed", on_hard_pressed)
	
	if markers.is_empty():
		push_error("⚠ Nessun marker assegnato in 'markers'")
		return

	# parti da lv1 (indice 0)
	$Camera.global_position = markers[current_index].global_position
	$Buttons.global_position = markers[current_index].global_position
	start_loop()


func start_loop():
	if loop_tween and loop_tween.is_valid():
		loop_tween.kill()

	loop_tween = create_tween()
	loop_tween.set_loops()
	loop_tween.set_trans(Tween.TRANS_SINE)
	loop_tween.set_ease(Tween.EASE_IN_OUT)

	# oscillazione attorno al pianeta
	loop_tween.tween_property($Camera, "position:x", 20, 2.0).as_relative()
	loop_tween.tween_property($Camera, "position:x", -40, 4.0).as_relative()
	loop_tween.tween_property($Camera, "position:x", 20, 2.0).as_relative()


func blink_and_hide(node: CanvasItem, times: int = 2, speed: float = 0.1):
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_LINEAR)
	tw.set_ease(Tween.EASE_IN_OUT)
	
	for i in range(times):
		tw.tween_callback(Callable(node, "hide"))
		tw.tween_interval(speed)
		tw.tween_callback(Callable(node, "show"))
		tw.tween_interval(speed)
	
	# Alla fine nascondi definitivamente
	tw.tween_callback(Callable(node, "hide"))
	
	return tw


func blink_and_show(node: CanvasItem, times: int = 2, speed: float = 0.1):
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_LINEAR)
	tw.set_ease(Tween.EASE_IN_OUT)
	
	# Prima mostra il nodo
	tw.tween_callback(Callable(node, "show"))
	
	for i in range(times):
		tw.tween_callback(Callable(node, "hide"))
		tw.tween_interval(speed)
		tw.tween_callback(Callable(node, "show"))
		tw.tween_interval(speed)
	
	return tw


func move_to_marker_with_blink(target_index: int):
	if target_index < 0 or target_index >= markers.size():
		return

	current_index = target_index

	# ferma eventuali tween attivi
	if loop_tween and loop_tween.is_valid():
		loop_tween.kill()
	if move_tween and move_tween.is_valid():
		move_tween.kill()

	# sequenza: muovi camera -> quando arrivi, fai ricomparire i bottoni
	move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_SINE)
	move_tween.set_ease(Tween.EASE_IN_OUT)

	# muovo camera (bottoni sono già nascosti dal blink iniziale)
	move_tween.tween_property($Camera, "global_position", markers[current_index].global_position, 1.5)
	move_tween.tween_property($Buttons, "global_position", markers[current_index].global_position, 0.2)

	# quando arrivi, fai ricomparire i bottoni con blink
	move_tween.tween_callback(blink_and_show.bind($Buttons, 2, 0.1))

	# restart loop camera
	move_tween.tween_callback(Callable(self, "start_loop"))


func _on_next_button_pressed() -> void:
	if input_locked or current_index >= markers.size() - 1:
		return

	
	if $Buttons/dificulty.modulate == Color(1,1,1,1):
		GlobalTweens.fade($Buttons/dificulty, 1, 0, 0.4)
		
	input_locked = true
	await blink_and_hide($Buttons, 3, 0.08).finished
	move_to_marker_with_blink(current_index + 1)
	level = "level_" + str(current_index + 1)
	input_locked = false


func _on_back_button_pressed() -> void:
	if input_locked or current_index <= 0:
		return
	if $Buttons/dificulty.modulate == Color(1,1,1,1):
		GlobalTweens.fade($Buttons/dificulty, 1, 0, 0.4)
		
	input_locked = true
	await blink_and_hide($Buttons, 3, 0.08).finished
	move_to_marker_with_blink(current_index - 1)
	level = "level_" + str(current_index + 1)
	input_locked = false


func _on_select_button_pressed() -> void:
	if input_locked:
		return
	print(level)
		

func _on_select_pressed() -> void:
	match  level:
		"level_1":
			GlobalTweens.fade($Buttons/dificulty, 0, 1)
			if Global.dungeons['lvl_1']['easy']:
				$Buttons/dificulty/Normal.disabled = false
			if Global.dungeons['lvl_1']['normal']:
				$Buttons/dificulty/Hard.disabled = false
		"level_2": 
			GlobalTweens.fade($Buttons/dificulty, 0, 1)
			if Global.dungeons['lvl_1']['easy']:
				$Buttons/dificulty/Normal.disabled = false
			if Global.dungeons['lvl_1']['normal']:
				$Buttons/dificulty/Hard.disabled = false
		"level_3": pass
		"level_4": pass
		"level_5": pass
		"level_6": pass

func on_easy_pressed() -> void:
	Global.dificulty = "easy"
	
	match  level:
		"level_1":
			var tw = create_tween().parallel()
			tw.tween_property($Camera, 'zoom', Vector2(4.0, 4.0), 2.0)
			tw.tween_property($Camera/Body, 'scale', Vector2(0.5, 0.5), 2.0)
			$Fade/fade.play("fade")
			await get_tree().create_timer(1.8).timeout
			get_tree().change_scene_to_file("res://Gres/Scenes/arena/earth_1_1.tscn")
		"level_2": 
			var tw = create_tween().parallel()
			tw.tween_property($Camera, 'zoom', Vector2(4.0, 4.0), 2.0)
			tw.tween_property($Camera/Body, 'scale', Vector2(0.5, 0.5), 2.0)
			$Fade/fade.play("fade")
			await get_tree().create_timer(1.8).timeout
			get_tree().change_scene_to_file("res://Gres/Scenes/arena/bood_earth_1_1.tscn")
		"level_3": pass
		"level_4": pass
		"level_5": pass
		"level_6": pass
func on_normal_pressed() -> void:
	Global.dificulty = "normal"
	
	match  level:
		"level_1":
			var tw = create_tween().parallel()
			tw.tween_property($Camera, 'zoom', Vector2(4.0, 4.0), 2.0)
			tw.tween_property($Camera/Body, 'scale', Vector2(0.5, 0.5), 2.0)
			$Fade/fade.play("fade")
			await get_tree().create_timer(1.8).timeout
			get_tree().change_scene_to_file("res://Gres/Scenes/arena/earth_1_1_normal.tscn")
		"level_2": 
			var tw = create_tween().parallel()
			tw.tween_property($Camera, 'zoom', Vector2(4.0, 4.0), 2.0)
			tw.tween_property($Camera/Body, 'scale', Vector2(0.5, 0.5), 2.0)
			$Fade/fade.play("fade")
			await get_tree().create_timer(1.8).timeout
			get_tree().change_scene_to_file("res://Gres/Scenes/arena/bood_earth_1_1.tscn")
		"level_3": pass
		"level_4": pass
		"level_5": pass
		"level_6": pass
		
func on_hard_pressed() -> void:
	Global.dificulty = "hard"
	
	match  level:
		"level_1":
			var tw = create_tween().parallel()
			tw.tween_property($Camera, 'zoom', Vector2(4.0, 4.0), 2.0)
			tw.tween_property($Camera/Body, 'scale', Vector2(0.5, 0.5), 2.0)
			$Fade/fade.play("fade")
			await get_tree().create_timer(1.8).timeout
			get_tree().change_scene_to_file("res://Gres/Scenes/arena/earth_1_1_hard.tscn")
		"level_2": 
			var tw = create_tween().parallel()
			tw.tween_property($Camera, 'zoom', Vector2(4.0, 4.0), 2.0)
			tw.tween_property($Camera/Body, 'scale', Vector2(0.5, 0.5), 2.0)
			$Fade/fade.play("fade")
			await get_tree().create_timer(1.8).timeout
			get_tree().change_scene_to_file("res://Gres/Scenes/arena/bood_earth_1_1.tscn")
		"level_3": pass
		"level_4": pass
		"level_5": pass
		"level_6": pass


func _on_close_dg_pressed() -> void:
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")
