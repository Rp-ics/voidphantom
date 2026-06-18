extends Control

# ==============================================================
# PVP SETTINGS UI — con OptionButton per la selezione modalità
#
# Nodi richiesti:
#   DurationSlider  — HSlider
#   DurationLabel   — Label
#   PreviewText     — RichTextLabel (bbcode_enabled = true)
#   ModeToggle      — OptionButton
#   CloseButton     — Button (opzionale)
# ==============================================================

@onready var duration_slider = $DurationSlider
@onready var duration_label  = $DurationLabel
@onready var preview_text    = $PreviewText
@onready var mode_toggle     = $ModeToggle    if has_node("ModeToggle")   else null
@onready var close_button    = $CloseButton   if has_node("CloseButton")  else null

func _ready() -> void:
	GameModes.load_settings()

	if mode_toggle:
		_populate_mode_toggle()

	_update_ui()

	if duration_slider:
		duration_slider.value_changed.connect(_on_duration_changed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if mode_toggle:
		mode_toggle.item_selected.connect(_on_mode_selected)

	visible = false

# ------------------------------------------------------------------
# UI UPDATE
# ------------------------------------------------------------------

func _update_ui() -> void:
	if not duration_slider or not duration_label:
		return

	duration_slider.min_value = GameModes.MIN_DURATION / 60.0
	duration_slider.max_value = GameModes.MAX_DURATION / 60.0
	duration_slider.value     = GameModes.match_duration / 60.0
	duration_label.text       = "Duration: %d min" % (GameModes.match_duration / 60)

	# Sincronizza OptionButton con la modalità salvata
	if mode_toggle:
		# select() accetta l'indice dell'item, che coincide con il valore enum
		mode_toggle.select(GameModes.current_mode)

	_update_preview()

func _populate_mode_toggle() -> void:
	mode_toggle.clear()
	mode_toggle.add_item("CLASSIC", GameModes.GameMode.CLASSIC)
	mode_toggle.add_item("POINT", GameModes.GameMode.POINT)
	mode_toggle.add_item("KING", GameModes.GameMode.KING)
	mode_toggle.add_item("PROGRESSION", GameModes.GameMode.PROGRESSION)

func _update_preview() -> void:
	if not preview_text:
		return

	var mode_name    := GameModes.get_mode_name()
	var desc         := GameModes.get_mode_description()
	var duration_min := GameModes.match_duration / 60

	var win_condition: String
	var extra_rules: String

	if GameModes.is_point_mode():
		win_condition = "Most points when time expires"
		extra_rules   = "[color=#55ff55]+%d[/color] per hit   [color=#ffaa00]+%d[/color] per kill   [color=#ff5555]%d[/color] on death" % [
			GameModes.POINT_HIT_SCORE,
			GameModes.POINT_KILL_SCORE,
			GameModes.POINT_DEATH_SCORE,
		]
	elif GameModes.is_progression_mode():
		win_condition = "Final kill with PVP_SHOTGUN or most points on timeout"
		extra_rules   = "[color=#ffaa00]+%d[/color] per kill   [color=#ff5555]%d[/color] on death\n[color=#55ff55]Kill:[/color] next weapon   [color=#ff5555]Death:[/color] previous weapon" % [
			GameModes.PROGRESSION_KILL_SCORE,
			GameModes.PROGRESSION_DEATH_SCORE,
		]
	else:
		win_condition = "Last player standing"
		extra_rules   = "[color=#aaaaaa]Time limit is a fallback:\nhighest HP wins on timeout[/color]"

	preview_text.text = """
[center][color=#d4af37]══════════════════════════[/color]
[color=#ffaa00]%s MODE[/color]
[color=#888888]%s[/color]

[color=#55ff55]Duration:[/color] %d minutes
[color=#55ff55]Win Condition:[/color] %s

%s
[color=#d4af37]══════════════════════════[/color][/center]
""" % [mode_name, desc, duration_min, win_condition, extra_rules]

# ------------------------------------------------------------------
# CALLBACKS
# ------------------------------------------------------------------

func _on_mode_selected(index: int) -> void:
	# OptionButton.item_selected emette l'indice (0=CLASSIC, 1=POINT)
	# che corrisponde esattamente ai valori dell'enum GameMode
	GameModes.set_mode(index as GameModes.GameMode)
	GameModes.save_settings()
	_update_preview()

func _on_duration_changed(value: float) -> void:
	var minutes := int(value)
	GameModes.set_duration(minutes * 60)
	if duration_label:
		duration_label.text = "Duration: %d min" % minutes
	_update_preview()
	GameModes.save_settings()

func _on_close_pressed() -> void:
	visible = false

# ------------------------------------------------------------------
# PUBLIC
# ------------------------------------------------------------------

func show_panel() -> void:
	_update_ui()
	visible = true
