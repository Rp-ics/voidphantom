extends Node2D

var can_move := false

const DEFAULT_RADIUS := 80
const DEFAULT_RANGE := 500.0
const DEFAULT_MAP_POS := Vector2(96, 554)

func _ready() -> void:
	$RadarRadius.value = Global.radar_radius
	$RadarRange.value = Global.radar_range
	$RadiusL.text = str("RADIUS ", Global.radar_radius, " PX")
	$RangeL.text = str("range ", Global.radar_range, " PX")
	$BackMap.connect("pressed", _on_back_pressed)
	$Move.connect("pressed", _on_move_pressed)
	$Reset.connect("pressed", _on_reset_pressed)
	$MiniMap.global_position = Vector2(Global.mapX, Global.mapY)

func _process(delta: float) -> void:
	if can_move:
		$MiniMap.z_index = 2
		$MiniMap.global_position = get_global_mouse_position()
		if Input.is_action_just_pressed("ui_accept"):
			can_move = false
			$MiniMap.z_index = 0
			Global.mapX = $MiniMap.global_position.x
			Global.mapY = $MiniMap.global_position.y
			
func _on_radar_radius_value_changed(value: float) -> void:
	Global.radar_radius = value
	$RadiusL.text = str("RADIUS ", Global.radar_radius, " PX")


func _on_radar_range_value_changed(value: float) -> void:
	Global.radar_range = value
	$RangeL.text = str("range ", Global.radar_range, " PX")

func _on_back_pressed() -> void:
	Global.can_show_map = false
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))

func _on_reset_pressed() -> void:
	var s_tween = create_tween()
	s_tween.parallel().tween_property($RadarRadius, "value", 80, 0.4).set_ease(Tween.EASE_IN)
	s_tween.parallel().tween_property($RadarRange, "value", 500, 0.3).set_ease(Tween.EASE_OUT)
	s_tween.parallel().tween_property($MiniMap, "global_position", Vector2(96, 554), 0.4).set_ease(Tween.EASE_IN)

	Global.radar_radius = 80
	Global.radar_range = 500.0
	Global.mapX = 96.0
	Global.mapY = 554.0
	
func _on_move_pressed() -> void:
	can_move = true
	
