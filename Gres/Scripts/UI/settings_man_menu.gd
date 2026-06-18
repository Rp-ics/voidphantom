extends Node2D

# Percorso del file di configurazione
const SETTINGS_PATH = "user://graphic_settings.cfg"

func _ready() -> void:
	get_tree().paused = false
	
	# Connessione bottoni
	$ButtonsManager/Upgrade.connect("pressed", _on_update_pressed)
	$ButtonsManager/Settings.connect("pressed", _on_setting_pressed)
	$ButtonsManager/Stats.connect("pressed", _on_stats_pressed)
	$ButtonsManager/Menu.connect("pressed", _on_menu_pressed)
	$ButtonsManager/BackSett.connect("pressed", _on_back_pressed)
	$ButtonsManager/Menu.connect("pressed", _on_main_menu_pressed)
	
	# Connessione LineEdit Max FPS
	var max_fps_line_edit = $SettingsMan/MaxFPS
	if max_fps_line_edit:
		max_fps_line_edit.text_changed.connect(_on_max_fps_text_changed)
		var saved_fps = load_max_fps()
		max_fps_line_edit.text = str(saved_fps)
		Engine.max_fps = saved_fps
	
	# Aggiorna testo shard
	$VoidShard.text = str(GlobalStats.void_shard)
	$MagmaShard.text = str(GlobalStats.magma_shard)
	$IceShard.text = str(GlobalStats.ice_shard)
	$LightShard.text = str(GlobalStats.light_shard)
	$Tablet.text = str(GlobalStats.tablet)


# =============================================
# BOTTONI NAVIGAZIONE
# =============================================

func _on_update_pressed() -> void:
	$UpgradeMan.modulate = Color(1, 1, 1, 0)
	$UpgradeMan.show()
	var tw = create_tween()
	tw.tween_property($UpgradeMan, "modulate:a", 1, 0.3)

func _on_setting_pressed() -> void:
	$SettingsMan.modulate = Color(1, 1, 1, 0)
	$SettingsMan.show()
	var tw = create_tween()
	tw.tween_property($SettingsMan, "modulate:a", 1, 0.3)

func _on_stats_pressed() -> void:
	$StatsMan.modulate = Color(1, 1, 1, 0)
	$StatsMan.show()
	var tw = create_tween()
	tw.tween_property($StatsMan, "modulate:a", 1, 0.3)

func _on_menu_pressed() -> void:
	pass

func _on_back_pressed() -> void:
	get_tree().paused = false
	Global.can_show_map = true
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")


# =============================================
# GESTIONE MAX FPS
# =============================================

func _on_max_fps_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		return
	
	var fps = int(new_text)
	fps = clampi(fps, 30, 500)
	
	# Correggi il testo nel LineEdit se fuori range
	var line_edit = $SettingsMan/MaxFPS
	if line_edit and fps != int(new_text):
		line_edit.text = str(fps)
		line_edit.caret_column = line_edit.text.length()
	
	# Applica e salva
	Engine.max_fps = fps
	save_max_fps(fps)


# =============================================
# SALVATAGGIO E CARICAMENTO IMPOSTAZIONI
# =============================================

func save_max_fps(fps: int) -> void:
	var config = ConfigFile.new()
	config.set_value("video", "max_fps", fps)
	config.save(SETTINGS_PATH)

func load_max_fps() -> int:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err == OK:
		return config.get_value("video", "max_fps", 144)
	else:
		return 144
