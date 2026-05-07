extends Node

const SAVE_PATH := "user://time_manager.save"

var last_login: int = 0
var max_timestamp: int = 0
const MIN_ALLOWED_TIMESTAMP := 1735689600  # 1 Gennaio 2025
const DAILY_RESET_HOUR := 6   # reset alle 6 del mattino

func _ready() -> void:
	load_data()
	check_time_cheat()
	save_data()
	# ✅ Ritarda il check giornaliero per sicurezza
	call_deferred("_check_daily_reset_deferred")

func _check_daily_reset_deferred() -> void:
	# Ora Global è sicuramente inizializzato
	if has_new_day():
		trigger_daily_reset()

func get_current_date_utc() -> String:
	var time = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [time["year"], time["month"], time["day"]]

func has_new_day() -> bool:
	var today = get_current_date_utc()
	# Legge da GlobalStats dove la variabile risiede effettivamente
	var last_reset: String = GlobalStats.daily_last_reset_date
	if last_reset == "" or last_reset != today:
		return true
	return false

func trigger_daily_reset():
	var today = get_current_date_utc()
	# ✅ Verifica che il metodo esista prima di chiamarlo
	if Global.has_method("generate_daily_missions"):
		Global.generate_daily_missions(today)
		print("Nuove missioni giornaliere generate per", today)
	else:
		print("⚠ generate_daily_missions non trovato in Global")

func get_current_timestamp() -> int:
	return Time.get_unix_time_from_system()

func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"last_login": last_login,
			"max_timestamp": max_timestamp
		}
		file.store_var(data)
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		var now = get_current_timestamp()
		last_login = now
		max_timestamp = now
		save_data()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		reset_data("File mancante o corrotto")
		return

	var data = file.get_var()
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		reset_data("File corrotto o alterato")
		return

	last_login = data.get("last_login", 0)
	max_timestamp = data.get("max_timestamp", 0)

func check_time_cheat() -> void:
	var now = get_current_timestamp()

	if now < MIN_ALLOWED_TIMESTAMP:
		trigger_cheat("La data del sistema è troppo indietro (<2025).")
		return

	if now < last_login:
		trigger_cheat("Hai riportato indietro l'orologio rispetto all'ultimo login.")
		return

	if now < max_timestamp:
		trigger_cheat("Hai riportato l'orologio indietro rispetto al massimo storico.")
		return

	last_login = now
	max_timestamp = max(max_timestamp, now)

func check_time_validity() -> bool:
	var now = get_current_timestamp()
	return now >= last_login and now >= max_timestamp and now >= MIN_ALLOWED_TIMESTAMP

func trigger_cheat(reason: String) -> void:
	print("⚠️ TIME CHEAT DETECTED: ", reason)
	reset_player_rewards()
	show_warning_scene(reason)
	reset_data(reason)

func reset_data(reason: String) -> void:
	var now = get_current_timestamp()
	last_login = now
	max_timestamp = now
	save_data()

func reset_player_rewards() -> void:
	# TODO: reset daily rewards, crafting cooldown, bonus ecc.
	# Ora puoi resettare anche le missioni giornaliere:
	Global.daily_missions = []
	Global.daily_last_reset_date = ""
	Global.special_coin_progress = 0
	GlobalStats.max_wave = 0
func show_warning_scene(reason: String) -> void:
	# TODO: carica la scena warning
	# Es: get_tree().change_scene_to_file("res://UI/time_cheat_warning.tscn")
	print("CHEAT WARNING SCENE:", reason)
