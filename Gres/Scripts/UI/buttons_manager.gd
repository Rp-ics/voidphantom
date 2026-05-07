extends Button

@export var DEFAULT_SCALE := Vector2(0.5, 0.5)
@export var SHAKE_INTENSITY := 1.0
@export var tween := "epic"
@export var tweens_avaible := [
	"epic","blink","bounce","c_flash","c_pulse",
	"e_pulse","fade_in","fade_out"
	]
@onready var original_position := position
@onready var current_tween = null

func animate_button_epic() -> void:
	# Reset al valore di partenza
	self.scale = DEFAULT_SCALE
	self.modulate = Color.WHITE
	self.position = original_position
	
	var tw = create_tween()
	tw.set_parallel(true)
	
	# 1. Bagliore esplosivo iniziale con effetto di sovraesposizione
	tw.tween_property(self, "scale", DEFAULT_SCALE * 1.0, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate", Color(2.0, 1.5, 2.5, 1.0), 0.1)
	
	# 2. Effetto di scossa sismica
	var shake_tween = create_tween()
	shake_tween.set_loops(4)
	shake_tween.tween_property(self, "position", 
		original_position + Vector2(randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY), 
		randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)), 0.05)
	shake_tween.tween_property(self, "position", original_position, 0.05)
	
	# 3. Rimbalzo potente con effetto elasticizzato
	tw.chain().tween_property(self, "scale", DEFAULT_SCALE * 0.9, 0.2)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate", Color(0.8, 0.9, 1.2, 1.0), 0.2)
	
	# 4. Ritorno alla normalità con overshoot finale
	tw.chain().tween_property(self, "scale", DEFAULT_SCALE * 1.1, 0.15)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate", Color.WHITE, 0.15)
	
	# 5. Effetto di pulsazione finale
	tw.chain().tween_property(self, "scale", DEFAULT_SCALE * 1.05, 0.1)
	tw.tween_property(self, "scale", DEFAULT_SCALE, 0.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 6. Bagliore residuo
	tw.chain().tween_property(self, "modulate", Color(1.2, 1.1, 1.3, 1.0), 0.3)
	tw.tween_property(self, "modulate", Color.WHITE, 0.5)

func bounce():
	var tw = create_tween()
	tw.tween_property($".", "scale", DEFAULT_SCALE * 1.2, 0.2)
	tw.tween_property($".", "scale", DEFAULT_SCALE, 0.2)
	
func _on_mouse_entered() -> void:
	var sfx := AudioStreamPlayer.new()
	sfx.stream = load("res://Gres/Music/SE/fx/mouse_3.ogg")
	get_tree().root.add_child(sfx)
	#sfx.pitch_scale = 1.0 if randi() % 100 < 50 else 0.9
	sfx.volume_db = Global.effects_volume
	sfx.play()
	sfx.connect("finished", Callable(sfx, "queue_free"))

	match tween:
		"epic": animate_button_epic()
		"bounce": bounce()
	
