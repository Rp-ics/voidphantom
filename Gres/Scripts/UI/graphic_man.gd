extends Control

# Riferimenti con find_child per cercare ovunque nella scena
@onready var title_label: Label = find_child("Title", true, false)
@onready var back_graph: Button = find_child("BackGraph", true, false)
@onready var resolution_option: OptionButton = find_child("ResolutionOption", true, false)
@onready var fullscreen_check: CheckButton = find_child("FullscreenCheck", true, false)
@onready var vsync_check: CheckButton = find_child("VSyncCheck", true, false)
@onready var bloom_slider: HSlider = find_child("BloomSlider", true, false)
@onready var particle_slider: HSlider = find_child("ParticleSlider", true, false)
@onready var bloom_label: Label = find_child("BloomLabel", true, false)
@onready var particle_label: Label = find_child("ParticleLabel", true, false)
@onready var apply_button: Button = find_child("ApplyButton", true, false)
@onready var max_fps_edit: LineEdit = find_child("MaxFPS", true, false)

# 5 CheckButton per Stretch Mode
@onready var stretch_keep: CheckButton = find_child("StretchKeep", true, false)
@onready var stretch_ignore: CheckButton = find_child("StretchIgnore", true, false)
@onready var stretch_keep_w: CheckButton = find_child("StretchKeepW", true, false)
@onready var stretch_keep_h: CheckButton = find_child("StretchKeepH", true, false)
@onready var stretch_expand: CheckButton = find_child("StretchExpand", true, false)

const CONFIG_PATH = "user://settings_graph.cfg"

var resolutions = []

# Lista ordinata degli stretch button per gestirli in gruppo
var stretch_buttons: Array[CheckButton] = []

func _ready() -> void:
	# Debug: scopri quali nodi mancano
	_check_nodes()
	
	# Raggruppa gli stretch button
	stretch_buttons = [
		stretch_keep,
		stretch_ignore,
		stretch_keep_w,
		stretch_keep_h,
		stretch_expand
	]
	
	# Connessioni sicure
	if back_graph:
		back_graph.pressed.connect(_on_back_pressed)
	
	if title_label:
		title_label.text = "Graphics Settings"
	
	_generate_resolutions()
	_populate_resolutions()
	_load_settings()
	
	# Connessioni solo se i nodi esistono
	if resolution_option:
		resolution_option.item_selected.connect(_on_resolution_selected)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if vsync_check:
		vsync_check.toggled.connect(_on_vsync_toggled)
	if bloom_slider:
		bloom_slider.value_changed.connect(_on_bloom_changed)
	if particle_slider:
		particle_slider.value_changed.connect(_on_particle_changed)
	if apply_button:
		apply_button.pressed.connect(_on_apply_pressed)
	if max_fps_edit:
		max_fps_edit.text_changed.connect(_on_max_fps_text_changed)
	
	# Connessioni Stretch Mode (mutualmente esclusivi)
	for btn in stretch_buttons:
		if btn:
			btn.toggled.connect(_on_stretch_toggled.bind(btn))

# ------------------------
# DEBUG: CONTROLLA NODI MANCANTI
# ------------------------
func _check_nodes() -> void:
	var nodes_to_check = {
		"Title": title_label,
		"BackGraph": back_graph,
		"ResolutionOption": resolution_option,
		"FullscreenCheck": fullscreen_check,
		"VSyncCheck": vsync_check,
		"BloomSlider": bloom_slider,
		"ParticleSlider": particle_slider,
		"BloomLabel": bloom_label,
		"ParticleLabel": particle_label,
		"ApplyButton": apply_button,
		"MaxFPS": max_fps_edit,
		"StretchKeep": stretch_keep,
		"StretchIgnore": stretch_ignore,
		"StretchKeepW": stretch_keep_w,
		"StretchKeepH": stretch_keep_h,
		"StretchExpand": stretch_expand
	}
	
	for node_name in nodes_to_check:
		if nodes_to_check[node_name] == null:
			print("ERRORE: Nodo '%s' non trovato nella scena!" % node_name)
		else:
			print("OK: Nodo '%s' trovato." % node_name)

# ------------------------
# RISOLUZIONI DINAMICHE
# ------------------------
func _generate_resolutions() -> void:
	var screen_size = DisplayServer.screen_get_size()
	resolutions = [
		screen_size,
		Vector2i(1920, 1080),
		Vector2i(1600, 900),
		Vector2i(1366, 768),
		Vector2i(1280, 720)
	]

# ------------------------
# UI
# ------------------------
func _populate_resolutions() -> void:
	if not resolution_option:
		return
	
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
	if bloom_label:
		bloom_label.text = "Bloom Quality: %d%%" % int(value)
	Global.bloom_quality = value

func _on_particle_changed(value: float) -> void:
	if particle_label:
		particle_label.text = "Particle Quality: %d%%" % int(value)
	Global.particle_quality = value

# ------------------------
# STRETCH MODE (mutualmente esclusivo)
# ------------------------
# ------------------------
# STRETCH MODE (mutualmente esclusivo)
# ------------------------
# ------------------------
# STRETCH MODE (mutualmente esclusivo)
# ------------------------
func _on_stretch_toggled(pressed: bool, clicked_button: CheckButton) -> void:
	if not pressed:
		# Blocca il segnale per evitare ricorsione
		clicked_button.set_block_signals(true)
		clicked_button.button_pressed = true
		clicked_button.set_block_signals(false)
		return
	
	# Disattiva tutti gli altri (bloccando i segnali)
	for btn in stretch_buttons:
		if btn and btn != clicked_button:
			btn.set_block_signals(true)
			btn.button_pressed = false
			btn.set_block_signals(false)
	
	# Salva il valore in base al bottone premuto
	if clicked_button == stretch_keep:
		Global.stretch_mode = "keep"
	elif clicked_button == stretch_ignore:
		Global.stretch_mode = "ignore"
	elif clicked_button == stretch_keep_w:
		Global.stretch_mode = "keep_width"
	elif clicked_button == stretch_keep_h:
		Global.stretch_mode = "keep_height"
	elif clicked_button == stretch_expand:
		Global.stretch_mode = "expand"
	
# ------------------------
# MAX FPS
# ------------------------
func _on_max_fps_text_changed(new_text: String) -> void:
	if new_text.is_empty():
		return
	
	var fps = int(new_text)
	
	# 0 = illimitati
	if fps == 0:
		Global.max_fps = 0
		Engine.max_fps = 0
		return
	
	# Minimo 30, massimo 500
	fps = clampi(fps, 30, 500)
	
	if max_fps_edit and fps != int(new_text):
		max_fps_edit.text = str(fps)
		max_fps_edit.caret_column = max_fps_edit.text.length()
	
	Global.max_fps = fps
	Engine.max_fps = fps

# ------------------------
# APPLY SETTINGS
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
	
	# MAX FPS
	Engine.max_fps = Global.max_fps
	
	# STRETCH MODE
	_apply_stretch_mode()

	_save_settings()

# ------------------------
# APPLICA STRETCH MODE
# ------------------------
func _apply_stretch_mode() -> void:
	match Global.stretch_mode:
		"keep":
			get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		"ignore":
			get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
		"keep_width":
			get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH
		"keep_height":
			get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
		"expand":
			get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

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
	cfg.set_value("graphics", "max_fps", Global.max_fps)
	cfg.set_value("graphics", "stretch_mode", Global.stretch_mode)
	cfg.save(CONFIG_PATH)

func _load_settings() -> void:
	var cfg = ConfigFile.new()

	if cfg.load(CONFIG_PATH) == OK:
		Global.resolution = cfg.get_value("graphics", "resolution", DisplayServer.screen_get_size())
		Global.fullscreen = cfg.get_value("graphics", "fullscreen", true)
		Global.vsync = cfg.get_value("graphics", "vsync", true)
		Global.bloom_quality = cfg.get_value("graphics", "bloom", 80)
		Global.particle_quality = cfg.get_value("graphics", "particle", 80)
		Global.max_fps = cfg.get_value("graphics", "max_fps", 0)
		Global.stretch_mode = cfg.get_value("graphics", "stretch_mode", "keep")
	else:
		Global.resolution = DisplayServer.screen_get_size()
		Global.fullscreen = true
		Global.vsync = true
		Global.bloom_quality = 80
		Global.particle_quality = 80
		Global.max_fps = 0
		Global.stretch_mode = "keep"

	# UI sync con controlli null
	if fullscreen_check:
		fullscreen_check.button_pressed = Global.fullscreen
	if vsync_check:
		vsync_check.button_pressed = Global.vsync
	if bloom_slider:
		bloom_slider.value = Global.bloom_quality
	if particle_slider:
		particle_slider.value = Global.particle_quality
	if max_fps_edit:
		if Global.max_fps == 0:
			max_fps_edit.text = "Illimitati"
		else:
			max_fps_edit.text = str(Global.max_fps)
	
	# Stretch Mode sync
	_set_stretch_button(Global.stretch_mode)
	
	if resolution_option:
		var idx = resolutions.find(Global.resolution)
		resolution_option.select(idx if idx != -1 else 0)

	if bloom_label:
		bloom_label.text = "Bloom Quality: %d%%" % int(Global.bloom_quality)
	if particle_label:
		particle_label.text = "Particle Quality: %d%%" % int(Global.particle_quality)

	# Applica subito
	Engine.max_fps = Global.max_fps
	_apply_stretch_mode()

# ------------------------
# HELPER STRETCH
# ------------------------
func _set_stretch_button(mode: String) -> void:
	# Deseleziona tutto (bloccando i segnali)
	for btn in stretch_buttons:
		if btn:
			btn.set_block_signals(true)
			btn.button_pressed = false
			btn.set_block_signals(false)
	
	# Attiva il bottone giusto (bloccando i segnali)
	match mode:
		"keep":
			if stretch_keep:
				stretch_keep.set_block_signals(true)
				stretch_keep.button_pressed = true
				stretch_keep.set_block_signals(false)
		"ignore":
			if stretch_ignore:
				stretch_ignore.set_block_signals(true)
				stretch_ignore.button_pressed = true
				stretch_ignore.set_block_signals(false)
		"keep_width":
			if stretch_keep_w:
				stretch_keep_w.set_block_signals(true)
				stretch_keep_w.button_pressed = true
				stretch_keep_w.set_block_signals(false)
		"keep_height":
			if stretch_keep_h:
				stretch_keep_h.set_block_signals(true)
				stretch_keep_h.button_pressed = true
				stretch_keep_h.set_block_signals(false)
		"expand":
			if stretch_expand:
				stretch_expand.set_block_signals(true)
				stretch_expand.button_pressed = true
				stretch_expand.set_block_signals(false)
# ------------------------
func _on_back_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))
