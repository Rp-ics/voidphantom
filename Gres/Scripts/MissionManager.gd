extends Node

var current_mission: Dictionary = {
	"title": "",
	"desc": "",
	"objective": "",
	"completed": false
}

signal mission_updated
signal mission_completed

func set_mission(title: String, desc: String, objective: String) -> void:
	current_mission = {
		"title": title,
		"desc": desc,
		"objective": objective,
		"completed": false
	}
	emit_signal("mission_updated")

func complete_mission() -> void:
	current_mission["completed"] = true
	emit_signal("mission_completed")
