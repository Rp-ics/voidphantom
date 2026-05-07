extends Control

@onready var resolution_option = $ResolutionOption
@onready var fullscreen_check  = $FullscreenCheck
@onready var vsync_check       = $VSyncCheck
@onready var bloom_slider      = $BloomSlider
@onready var particle_slider   = $ParticleSlider
@onready var bloom_label       = $BloomLabel
@onready var particle_label    = $ParticleLabel
@onready var apply_button      = $ApplyButton

const CONFIG_PATH = "user://settings.cfg"

var resolutions = []

func _ready() -> void:
	$BackGraph.pressed.connect(_on_back_pressed)
	$Title.text = "Graphics Settings"

	_generate_resolutions()
	_populate_resolutions()
	_load_settings()

	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	bloom_slider.value_changed.connect(_on_bloom_changed)
	particle_slider.value_changed.connect(_on_particle_changed)
	apply_button.pressed.connect(_on_apply_pressed)

# ------------------------
# RISOLUZIONI DINAMICHE
# ------------------------
func _generate_resolutions() -> void:
	var screen_size = DisplayServer.screen_get_size()
	resolutions = [
		screen_size,
		Vector2i(1920,1080),
		Vector2i(1600,900),
		Vector2i(1366,768),
		Vector2i(1280,720)
	]

# ------------------------
# UI
# ------------------------
func _populate_resolutions() -> void:
	resolution_option.clear()
	for res in resolutions:
		resolution_option.add_item("%dx%d" % [res.x, res.y])

# ------------------------
# EVENTI
# ------------------------
func _on_resolution_selected(index: int) -> void:
	Global.resolution = resolutions[index]

func _on_fullscreen_toggled(pressed: bool) -> void:
	Global.fullscreen = pressed

func _on_vsync_toggled(pressed: bool) -> void:
	Global.vsync = pressed

func _on_bloom_changed(value: float) -> void:
	bloom_label.text = "Bloom Quality: %d%%" % int(value)
	Global.bloom_quality = value

func _on_particle_changed(value: float) -> void:
	particle_label.text = "Particle Quality: %d%%" % int(value)
	Global.particle_quality = value

# ------------------------
# APPLY SETTINGS (FIXED)
# ------------------------
func _on_apply_pressed() -> void:

	# FULLSCREEN
	if Global.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Global.resolution)

	# VSYNC
	if Global.vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	_save_settings()

# ------------------------
# SAVE / LOAD
# ------------------------
func _save_settings() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("graphics", "resolution", Global.resolution)
	cfg.set_value("graphics", "fullscreen", Global.fullscreen)
	cfg.set_value("graphics", "vsync", Global.vsync)
	cfg.set_value("graphics", "bloom", Global.bloom_quality)
	cfg.set_value("graphics", "particle", Global.particle_quality)
	cfg.save(CONFIG_PATH)

func _load_settings() -> void:
	var cfg = ConfigFile.new()

	if cfg.load(CONFIG_PATH) == OK:
		Global.resolution = cfg.get_value("graphics", "resolution", DisplayServer.screen_get_size())
		Global.fullscreen = cfg.get_value("graphics", "fullscreen", true)
		Global.vsync = cfg.get_value("graphics", "vsync", true)
		Global.bloom_quality = cfg.get_value("graphics", "bloom", 80)
		Global.particle_quality = cfg.get_value("graphics", "particle", 80)
	else:
		Global.resolution = DisplayServer.screen_get_size()
		Global.fullscreen = true
		Global.vsync = true
		Global.bloom_quality = 80
		Global.particle_quality = 80

	# UI sync
	fullscreen_check.button_pressed = Global.fullscreen
	vsync_check.button_pressed = Global.vsync
	bloom_slider.value = Global.bloom_quality
	particle_slider.value = Global.particle_quality

	var idx = resolutions.find(Global.resolution)
	resolution_option.select(idx if idx != -1 else 0)

	bloom_label.text = "Bloom Quality: %d%%" % int(bloom_slider.value)
	particle_label.text = "Particle Quality: %d%%" % int(particle_slider.value)

# ------------------------
func _on_back_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))
