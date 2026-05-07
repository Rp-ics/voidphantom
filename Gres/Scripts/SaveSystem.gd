extends Node

var save_path := "user://skill_ddata.json"

func save_skills() -> void:
	var data := {
		"unlocked_skills": GlobalSkills.unlocked_skills,
		"completed_constellations": GlobalSkills.completed_constellations
	}

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_skills() -> void:
	if not FileAccess.file_exists(save_path):
		return

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return

	var text := file.get_as_text()
	file.close()

	# Se file vuoto o solo whitespace
	if text.strip_edges().length() == 0:
		return

	var parsed = JSON.parse_string(text)

	# Controllo errore parsing
	if parsed.error != OK:
		push_error("SaveSystem: JSON corrotto in player_data.json")
		return

	var data = parsed.result

	if typeof(data) == TYPE_DICTIONARY:
		GlobalSkills.unlocked_skills = data.get("unlocked_skills", [])
		GlobalSkills.completed_constellations = data.get("completed_constellations", [])

	# Applica subito i bonus passivi se esistono
	if GlobalStats.has_method("apply_passives_to_player"):
		GlobalStats.apply_passives_to_player()
