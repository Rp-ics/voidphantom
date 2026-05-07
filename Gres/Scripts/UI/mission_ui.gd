extends Control

var is_show := true

func _ready():
	$ShowHide.disabled = false
	$ShowHide.connect("mouse_entered", on_mouse_showhide_entered)
	$ShowHide.connect("mouse_exited", on_mouse_showhide_exited)
	$ShowHide.connect("pressed", on_showhide_pressed)
	MissionManager.connect("mission_updated", Callable(self, "_update_ui"))
	MissionManager.connect("mission_completed", Callable(self, "_on_completed"))
	_update_ui()

func _update_ui():
	var m = MissionManager.current_mission
	$man/MissionTitle.text = m.title
	$man/MissionDesc.text = m.desc
	$man/Objective.text = "Objective: " + m.objective

func _on_completed():
	$man/Objective.text = "[color=green]✔ COMPLETED[/color]"

func show_tw():
	var s_tween = create_tween()
	s_tween.tween_property($ShowHide, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_IN)
	await s_tween.finished

func hide_tw():
	var s_tween = create_tween()
	s_tween.tween_property($ShowHide, "modulate:a", 0.1, 0.3).set_ease(Tween.EASE_IN)
	await s_tween.finished


func on_mouse_showhide_entered() -> void:
	show_tw()
	
func on_mouse_showhide_exited() -> void:
	hide_tw()
	
func on_showhide_pressed() -> void:
	$ShowHide.disabled = true
	if is_show: # hide ui
		is_show = false
		$man/show_hide.play("hide")
	else: # show ui
		is_show = true
		$man/show_hide.play("show")


func _on_show_hide_animation_finished(anim_name: StringName) -> void:
	$ShowHide.disabled = false
