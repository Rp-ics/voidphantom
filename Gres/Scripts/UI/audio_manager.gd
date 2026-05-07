extends Control

@onready var master_slider  = $MasterSlider
@onready var music_slider   = $MusicSlider
@onready var effects_slider = $EffectsSlider
@onready var mute_check     = $MuteCheck

@onready var master_label   = $MasterLabel
@onready var music_label    = $MusicLabel
@onready var effects_label  = $EffectsLabel

const CONFIG_PATH = "user://settings.cfg"

func _ready():
	$BackAudio.connect("pressed", on_back_pressed)
	$Title.text = "Audio Settings"
	mute_check.text = "Mute All"

	for slider in [music_slider, effects_slider]:
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 1

	#master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	effects_slider.value_changed.connect(_on_effects_changed)
	mute_check.toggled.connect(_on_mute_toggled)

	_load_settings()
	sync_sliders_from_globals()

# --- Sincronizza sliders e labels dai valori globali ---
func sync_sliders_from_globals() -> void:
	#master_slider.value = Global.master_volume
	music_slider.value  = Global.music_volume
	effects_slider.value = Global.effects_volume
	#_on_master_changed(master_slider.value)
	_on_music_changed(music_slider.value)
	_on_effects_changed(effects_slider.value)

# --- Gestione sliders ---
func _on_master_changed(value: float) -> void:
	return
	#master_label.text = "Master Volume: %d%%" % int(value)
	#Global.master_volume = value
	#if not mute_check.button_pressed:
		#_set_bus_volume("Master", value)
	#_save_settings()

func _on_music_changed(value: float) -> void:
	music_label.text = "Music Volume: %d%%" % int(value)
	Global.music_volume = value
	if not mute_check.button_pressed:
		_set_bus_volume("Music", value)
	_save_settings()

func _on_effects_changed(value: float) -> void:
	effects_label.text = "Effects Volume: %d%%" % int(value)
	Global.effects_volume = value
	if not mute_check.button_pressed:
		_set_bus_volume("Effects", value)
	_save_settings()

# --- Mute All ---
func _on_mute_toggled(pressed: bool) -> void:
	if pressed:
		#Global.master_volume = 0
		Global.music_volume = 0
		Global.effects_volume = 0
		#_set_bus_volume("Master", 0)
		_set_bus_volume("Music", 0)
		_set_bus_volume("Effects", 0)
	else:
		#_set_bus_volume("Master", master_slider.value)
		_set_bus_volume("Music", music_slider.value)
		_set_bus_volume("Effects", effects_slider.value)
		
	sync_sliders_from_globals()
	_save_settings()

# --- Utility: set bus volume con controllo ---
func _set_bus_volume(bus_name: String, value: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("Audio bus '%s' non trovato." % bus_name)
		return
	var db_val = -80 if value == 0 else linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(idx, db_val)

# --- Salvataggio e caricamento ---
func _save_settings() -> void:
	var cfg = ConfigFile.new()
	#cfg.set_value("audio", "master", Global.master_volume)
	cfg.set_value("audio", "music", Global.music_volume)
	cfg.set_value("audio", "effects", Global.effects_volume)
	cfg.set_value("audio", "mute", mute_check.button_pressed)
	cfg.save(CONFIG_PATH)

func _load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		#Global.master_volume = cfg.get_value("audio", "master", 80)
		Global.music_volume  = cfg.get_value("audio", "music", 50)
		Global.effects_volume = cfg.get_value("audio", "effects", 10)
		mute_check.button_pressed = cfg.get_value("audio", "mute", false)
	else:
		#Global.master_volume = 80
		Global.music_volume  = 50
		Global.effects_volume = 10
		mute_check.button_pressed = false

func on_back_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))
