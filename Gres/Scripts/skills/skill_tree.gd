extends Node2D

@export var markers: Array[Marker2D] = []   # lista di Marker2D nell'editor
var current_index: int = 0

var loop_tween: Tween
var move_tween: Tween

var level = "level_1"

var input_locked: bool = false

func _ready() -> void:
	#GlobalStats.tablet = 999
	#GlobalStats.gold = 9999999
	$Buttons/Next.pressed.connect(_on_next_button_pressed)
	$Buttons/Back.pressed.connect(_on_back_button_pressed)
	$Buttons/close.pressed.connect(_on_close_button_pressed)

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

func zoom_in(val=1.0, time=2.0):
	var tw = create_tween().parallel()
	tw.tween_property($Camera, 'zoom', Vector2(val, val), time)

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

	input_locked = true
	await blink_and_hide($Buttons, 3, 0.08).finished
	move_to_marker_with_blink(current_index + 1)
	level = "level_" + str(current_index + 1)
	input_locked = false
	zoom_in(0.7) if level in ['level_2'] else zoom_in(1.0)
	

func _on_back_button_pressed() -> void:
	if input_locked or current_index <= 0:
		return

	input_locked = true
	await blink_and_hide($Buttons, 3, 0.08).finished
	move_to_marker_with_blink(current_index - 1)
	level = "level_" + str(current_index + 1)
	input_locked = false
	zoom_in(0.7) if level in ['level_2'] else zoom_in(1.0)
	
func _on_select_button_pressed() -> void:
	if input_locked:
		return
	
func _on_close_info_pressed() -> void:
	$Buttons/Next.disabled = false
	$Buttons/Back.disabled = false
	$Buttons/close.disabled = false
	var tw = create_tween()
	tw.tween_property($Buttons/InfoSkills, 'modulate:a', 0.0, 0.5)
	await  get_tree().create_timer(0.6).timeout
	$Buttons/InfoSkills.hide()

func _on_close_button_pressed() -> void:
	$trs.play("close")

func _on_trs_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close":
		get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")
