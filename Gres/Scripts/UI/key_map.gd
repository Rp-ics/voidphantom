extends Control

const SLOTS = ["primary", "secondary", "tertiary", "quaternary"]

@onready var grid         = $BindingsGrid # GridContainer
@onready var reset_button = $ResetButton # Button

const CONFIG_PATH = "user://bindings.cfg"

# ===== STYLE EXPORTS ===== #
@export var label_font_size:    int   = 18
@export var label_font_color:   Color = Color.WHITE
@export var button_font_size:   int   = 16
@export var button_font_color:  Color = Color(0.9, 0.9, 0.9)
@export var button_normal_color:  Color = Color(0.2, 0.2, 0.2)
@export var button_hover_color:   Color = Color(0.35, 0.35, 0.35)
@export var button_pressed_color: Color = Color(0.5, 0.5, 0.5)


# ===== DEFAULT BINDINGS ===== #
# Ogni valore è un dict { "type": "key"|"mouse"|"joy", "code": int } oppure nll #
# Questo evita l'ambiguità numerica: JOY_BUTTON_B=1 == MOUSE_BUTTON_LEFT=1 #
var default_bindings := {
	"move_up": {
		"primary": { "type": "key", "code": KEY_W },
		"secondary": { "type": "joy", "code": JOY_BUTTON_DPAD_UP },
		"tertiary": null, "quaternary": null },
	"move_down": {
		"primary": { "type": "key", "code": KEY_S },
		"secondary": { "type": "joy", "code": JOY_BUTTON_DPAD_DOWN },
		"tertiary": null, "quaternary": null },
	"move_left":  {
		"primary": { "type": "key", "code": KEY_A },
		"secondary": { "type": "joy", "code": JOY_BUTTON_DPAD_LEFT },
		"tertiary":   null, "quaternary": null },
	"move_right": {
		"primary": { "type": "key", "code": KEY_D },
		"secondary": { "type": "joy", "code": JOY_BUTTON_DPAD_RIGHT },
		"tertiary":   null, "quaternary": null },
	"dash": {
		"primary": { "type": "key", "code": KEY_SHIFT },
		"secondary": { "type": "joy", "code": JOY_BUTTON_A },
		"tertiary":   null, "quaternary": null },
	"shoot": {
		"primary": { "type": "mouse", "code": MOUSE_BUTTON_LEFT },
		"secondary": { "type": "joy", "code": JOY_BUTTON_RIGHT_SHOULDER },
		"tertiary":   null, "quaternary": null },
	"reload": {
		"primary": { "type": "key", "code": KEY_R },
		"secondary": { "type": "joy", "code": JOY_BUTTON_X },
		"tertiary":   null, "quaternary": null },
	"skill_1": {
		"primary": { "type": "key", "code": KEY_1 },
		"secondary": { "type": "joy", "code": JOY_BUTTON_B },
		"tertiary": null, "quaternary": null },
}

var bindings := {}
var listening_for := {"action": "", "slot": "", "button": null}


func _ready() -> void:
	if not grid:
		push_error("Nodo 'BindingsGrid' non trovato.")
		return
	if not reset_button:
		push_error("Nodo 'ResetButton' non trovato.")
		return

	grid.columns = 5

	if has_node("BackButton"):
		$BackButton.pressed.connect(_on_back_pressed)
	else:
		push_error("Nodo 'BackButton' non trovato.")

	reset_button.pressed.connect(_on_reset_pressed)
	_load_bindings()
	_generate_ui()


# === UI === #
func _apply_style_to_label(label: Label) -> void:
	label.add_theme_font_size_override("font_size", label_font_size)
	label.add_theme_color_override("font_color", label_font_color)


func _apply_style_to_button(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", button_font_size)
	btn.add_theme_color_override("font_color", button_font_color)
	btn.add_theme_color_override("font_color_hover", button_font_color)
	btn.add_theme_color_override("font_color_pressed", button_font_color)
	btn.add_theme_color_override("bg_color", button_normal_color)
	btn.add_theme_color_override("bg_color_hover", button_hover_color)
	btn.add_theme_color_override("bg_color_pressed", button_pressed_color)


func _generate_ui() -> void:
	if not grid:
		return
	for child in grid.get_children():
		if child != reset_button:
			child.queue_free()

	for action in bindings.keys():
		var label = Label.new()
		label.text = action.capitalize().replace("_", " ")
		_apply_style_to_label(label)
		grid.add_child(label)

		for slot in SLOTS:
			var btn = Button.new()
			btn.text = _event_to_string(bindings[action][slot])
			_apply_style_to_button(btn)
			btn.pressed.connect(_on_binding_button_pressed.bind(action, slot, btn))
			grid.add_child(btn)


func _on_binding_button_pressed(action: String, slot: String, button: Button) -> void:
	listening_for = {"action": action, "slot": slot, "button": button}
	button.text = "Set Input..."


func _input(event: InputEvent) -> void:
	if listening_for.action == "":
		return

	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.is_pressed():
			_remove_conflicts(event)
			bindings[listening_for.action][listening_for.slot] = event
			_update_inputmap()
			_save_bindings()
			listening_for.button.text = _event_to_string(event)
			listening_for = {"action": "", "slot": "", "button": null}
			get_viewport().set_input_as_handled()


func _remove_conflicts(event: InputEvent) -> void:
	for action in bindings:
		for slot in SLOTS:
			var existing = bindings[action][slot]
			if existing and _events_equal(existing, event):
				bindings[action][slot] = null


func _events_equal(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey: return a.keycode == b.keycode
	if a is InputEventMouseButton and b is InputEventMouseButton: return a.button_index == b.button_index
	if a is InputEventJoypadButton and b is InputEventJoypadButton: return a.button_index == b.button_index
	return false

# UPDATE INPUTMAP #
func _update_inputmap() -> void:
	for action in bindings:
		# Assicurati che l'action esista nell'InputMap
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		else:
			InputMap.action_erase_events(action)

		for slot in SLOTS:
			var event: InputEvent = bindings[action][slot]
			if event:
				InputMap.action_add_event(action, event)



# EVENT in STRING #
func _event_to_string(event) -> String:
	if event == null:
		return "---"
	if event is InputEventKey:
		return OS.get_keycode_string(event.keycode)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "Mouse Left"
			MOUSE_BUTTON_RIGHT: return "Mouse Right"
			MOUSE_BUTTON_MIDDLE: return "Mouse Middle"
			_: return "Mouse Button %d" % event.button_index
	elif event is InputEventJoypadButton:
		match event.button_index:
			JOY_BUTTON_A: return "A"
			JOY_BUTTON_B: return "B"
			JOY_BUTTON_X: return "X"
			JOY_BUTTON_Y: return "Y"
			JOY_BUTTON_LEFT_SHOULDER: return "L Shoulder"
			JOY_BUTTON_RIGHT_SHOULDER: return "R Shoulder"
			JOY_BUTTON_DPAD_UP: return "DPAD Up"
			JOY_BUTTON_DPAD_DOWN: return "DPAD Down"
			JOY_BUTTON_DPAD_LEFT: return "DPAD Left"
			JOY_BUTTON_DPAD_RIGHT: return "DPAD Right"
			_: return "Button %d" % event.button_index
	return "---"

# RESET #
func _on_reset_pressed() -> void:
	bindings = {}
	for action in default_bindings:
		bindings[action] = {}
		for slot in SLOTS:
			var code = default_bindings[action][slot]
			bindings[action][slot] = _create_event(code) if code != null else null
	_update_inputmap()
	_generate_ui()
	_save_bindings()


# ============================================================== #
# CREATE EVENT
# Accetta un dict { "type": "key"|"mouse"|"joy", "code": int }
# oppure null. Il tipo esplicito risolve l'ambiguità numerica
# (JOY_BUTTON_B=1 == MOUSE_BUTTON_LEFT=1)
# ============================================================== #
func _create_event(def) -> InputEvent:
	if def == null: return null
	var t: String = def.get("type", "")
	var c: int = def.get("code", -1)
	if c == -1: return null
	match t:
		"key":
			var ev := InputEventKey.new()
			ev.keycode = c
			return ev
		"mouse":
			var ev := InputEventMouseButton.new()
			ev.button_index = c
			return ev
		"joy":
			var ev := InputEventJoypadButton.new()
			ev.button_index = c
			return ev
	push_warning("_create_event: tipo '%s' non riconosciuto." % t)
	return null

# SAVE
func _save_bindings() -> void:
	var cfg := ConfigFile.new()
	for action in bindings:
		for slot in SLOTS:
			var e: InputEvent = bindings[action][slot]
			if e == null:
				cfg.set_value(action, slot + "_type", "none")
				cfg.set_value(action, slot + "_code", -1)
			elif e is InputEventKey:
				cfg.set_value(action, slot + "_type", "key")
				cfg.set_value(action, slot + "_code", e.keycode)
			elif e is InputEventMouseButton:
				cfg.set_value(action, slot + "_type", "mouse")
				cfg.set_value(action, slot + "_code", e.button_index)
			elif e is InputEventJoypadButton:
				cfg.set_value(action, slot + "_type", "joy")
				cfg.set_value(action, slot + "_code", e.button_index)
	cfg.save(CONFIG_PATH)


# LOAD
func _load_bindings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)
	bindings.clear()

	for action in default_bindings:
		bindings[action] = {}
		for slot in SLOTS:
			var e: InputEvent = null

			if err == OK:
				var t: String = cfg.get_value(action, slot + "_type", "none")
				var c: int = cfg.get_value(action, slot + "_code", -1)

				if t == "none" or c == -1:
					e = null   # slot vuoto salvato intenzionalmente
				elif t == "key":
					var ev := InputEventKey.new()
					ev.keycode = c
					e = ev
				elif t == "mouse":
					var ev := InputEventMouseButton.new()
					ev.button_index = c
					e = ev
				elif t == "joy":
					var ev := InputEventJoypadButton.new()
					ev.button_index = c
					e = ev
				# tipo sconosciuto → usa default
				else:
					e = _create_event(default_bindings[action][slot])
			else:
				# Nessun file cfg → carica defaults
				var def_code = default_bindings[action][slot]
				e = _create_event(def_code) if def_code != null else null

			bindings[action][slot] = e

	_update_inputmap()

	if Global:
		Global.bindings = bindings

# BACK
func _on_back_pressed() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(Callable(self, "hide"))
