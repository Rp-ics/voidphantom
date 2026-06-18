extends Node2D

func _ready() -> void:
	# Sincronizza l'UI con il valore salvato nei GlobalStats
	match GlobalStats.graphic:
		"normale":
			$GraphicMan/AnimationLow.set_pressed_no_signal(true)
			$GraphicMan/AnimationHight.set_pressed_no_signal(false)
		"alta":
			$GraphicMan/AnimationLow.set_pressed_no_signal(false)
			$GraphicMan/AnimationHight.set_pressed_no_signal(true)
		_:
			# Opzionale: impostazione di default se il valore è vuoto o errato
			$GraphicMan/AnimationLow.set_pressed_no_signal(true)
	
	$GamepMan/ButtonsManager/KeyMap.connect("pressed", _on_keymap_pressed)
	$GamepMan/ButtonsManager/GUI.connect("pressed", _on_gui_pressed)
	$GamepMan/ButtonsManager/Map.connect("pressed", _on_map_pressed)
	$GamepMan/ButtonsManager/BackGM.connect("pressed", _on_back_pressed)
	$ButtonsManager/BackSett.connect("pressed", _on_back_pressed)
	
	$ButtonsManager/GameP.connect("pressed", _on_gamep_pressed)
	$ButtonsManager/Audio.connect("pressed", _on_audio_pressed)
	$ButtonsManager/Graphic.connect("pressed", _on_graphic_pressed)
	$ButtonsManager/UI.connect("pressed", _on_ui_pressed)
	

func _on_gamep_pressed() -> void:
	$GamepMan.modulate = Color(1,1,1,0)
	$GamepMan.show()
	var tw = create_tween()
	tw.tween_property($GamepMan, "modulate:a", 1, 0.3)
	
func _on_audio_pressed() -> void:
	$AudioMan.modulate = Color(1,1,1,0)
	$AudioMan.show()
	var tw = create_tween()
	tw.tween_property($AudioMan, "modulate:a", 1, 0.3)
	
func _on_graphic_pressed() -> void:
	$GraphicMan.modulate = Color(1,1,1,0)
	$GraphicMan.show()
	var tw = create_tween()
	tw.tween_property($GraphicMan, "modulate:a", 1, 0.3)
	
func _on_ui_pressed() -> void:
	pass

func _on_keymap_pressed() -> void:
	$GamepMan/KeyMap.modulate = Color(1,1,1,0)
	$GamepMan/KeyMap.show()
	var tw = create_tween()
	tw.tween_property($GamepMan/KeyMap, "modulate:a", 1, 0.3)
	
func _on_gui_pressed() -> void:
	$GamepMan/GUIMan.modulate = Color(1,1,1,0)
	$GamepMan/GUIMan.show()
	var tw = create_tween()
	tw.tween_property($GamepMan/GUIMan, "modulate:a", 1, 0.3)
	
func _on_map_pressed() -> void:
	Global.can_show_map = true
	$GamepMan/MapMan.modulate = Color(1,1,1,0)
	$GamepMan/MapMan.show()
	var tw = create_tween()
	tw.tween_property($GamepMan/MapMan, "modulate:a", 1, 0.3)
	
func _on_back_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))


# Soluzione corretta usando button_pressed
func _on_animation_low_toggled(toggled_on: bool) -> void:
	if toggled_on:
		# Disabilita l'altro senza riattivare segnali infiniti
		$GraphicMan/AnimationHight.set_pressed_no_signal(false)
		GlobalStats.graphic = "normale"

func _on_animation_hight_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$GraphicMan/AnimationLow.set_pressed_no_signal(false)
		GlobalStats.graphic = "alta"
	
