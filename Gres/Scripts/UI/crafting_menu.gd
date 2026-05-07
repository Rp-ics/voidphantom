extends Control

@onready var weapon_list = $WeaponList
@onready var preview_panel = $PreviewPanel
@onready var weapon_icon = $PreviewPanel/WeaponIcon
@onready var weapon_name_label = $PreviewPanel/WeaponName
@onready var material_list = $PreviewPanel/MaterialList
@onready var craft_button = $PreviewPanel/CraftButton
@onready var info_label = $InfoLabel

@onready var val_void = $Values/VoidShard
@onready var val_magma = $Values/MagmaShard
@onready var val_ice = $Values/IceShard
@onready var val_light = $Values/LightShard
@onready var val_gold = $Values/gold

var current_rarity := ""
var selected_weapon := ""

var owned_weapon_texts_en := [
	"This weapon already shines in your arsenal.",
	"Forged once — no need for another.",
	"You already hold its power.",
	"Your forge remembers this weapon well.",
	"Already crafted, already deadly."
]

var craft_w_en = [
	"Infusing weapon with power…",
	"Hammering steel into shape…",
	"Binding energy to the blade…",
	"Sharpening edges, almost ready…",
	"Enchantments taking hold…"
]

func _ready():
	$CloseButton.connect("pressed", _on_exit_craft)
	craft_button.disabled = false
	
	# Connessione al segnale globale per aggiornamento in tempo reale
	if not GlobalWeapons.gun_found.is_connected(_on_gun_found):
		GlobalWeapons.gun_found.connect(_on_gun_found)
	
	# Refresh automatico all'apertura del pannello (se nascosto/mostrato)
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)
	
	_load_categories()

func _process(_delta: float) -> void:
	val_void.text = str(GlobalStats.void_shard)
	val_magma.text = str(GlobalStats.magma_shard)
	val_ice.text = str(GlobalStats.ice_shard)
	val_light.text = str(GlobalStats.light_shard)
	val_gold.text = str(GlobalStats.gold)
	$CraftMan/progressbar/Counter.text = str($CraftMan/progressbar.value, "%")

# =====================================
# Aggiornamento dinamico
# =====================================

func _on_gun_found(_weapon_name: String, _rarity: String) -> void:
	# Se il pannello è visibile, ricarica subito
	if visible:
		_load_categories()
		if current_rarity != "":
			_on_category_pressed(current_rarity)

func _on_visibility_changed():
	# Ogni volta che il pannello diventa visibile, ricarica tutto
	if visible:
		refresh_on_open()

func refresh_on_open() -> void:
	_load_categories()
	current_rarity = ""
	selected_weapon = ""
	craft_button.disabled = false
	clear_children(material_list)
	weapon_icon.texture = null
	weapon_name_label.text = ""
	info_label.text = "Select a rarity to view weapons"

# =====================================
# === UTILS === #
# =====================================
func clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()

func create_fancy_button(text: String, size: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = size

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15)
	style.border_color = Color(0.7, 0.7, 0.7)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.25, 0.25, 0.25)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.1, 0.1, 0.1)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	return btn

# =====================================
# === CATEGORIE DI RARITÀ === #
# =====================================
func _load_categories():
	weapon_list.columns = 2
	clear_children(weapon_list)

	if Global.weapons_found.is_empty():
		info_label.text = "No weapons found yet. Open chests to discover them!"
		return

	for rarity in Global.weapons_found.keys():
		var btn = create_fancy_button(rarity.capitalize(), Vector2(165,48))
		btn.connect("pressed", Callable(self, "_on_category_pressed").bind(rarity))
		weapon_list.add_child(btn)
	info_label.text = "Select a rarity to view weapons"
	craft_button.disabled = false
	clear_children(material_list)
	weapon_icon.texture = null
	weapon_name_label.text = ""

# =====================================
# MOSTRA LE ARMI DI UNA RARITÀ (solo icone)
# =====================================
func _on_category_pressed(rarity: String):
	current_rarity = rarity
	clear_children(weapon_list)

	for weapon_name in Global.weapons_found[rarity]:
		var weapon_data = Global.get_weapon_data(weapon_name, rarity)
		if weapon_data.is_empty():
			continue

		weapon_list.columns = 5
		var btn = TextureButton.new()
		if GlobalStats.has_weapon(weapon_name, rarity):
			btn.modulate = Color(0.4, 1.0, 0.4)   # verde se posseduta
		else:
			btn.modulate = Color(1, 1, 1)

		btn.texture_normal = load(weapon_data.icon)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(64,64)
		btn.connect("pressed", Callable(self, "_on_weapon_selected").bind(weapon_name, rarity))
		weapon_list.add_child(btn)

	# back button
	var back_btn = create_fancy_button("◀️ ", Vector2(64, 64))
	back_btn.connect("pressed", Callable(self, "_load_categories"))
	weapon_list.add_child(back_btn)

# =====================================
# === MOSTRA DETTAGLI DELL'ARMA === #
# =====================================
func _on_weapon_selected(weapon_name: String, rarity: String):
	selected_weapon = weapon_name
	info_label.text = "[%s] %s" % [rarity.capitalize(), weapon_name.capitalize()]
	weapon_name_label.text = weapon_name.capitalize()
	clear_children(material_list)

	var weapon_data = Global.get_weapon_data(weapon_name, rarity)
	if weapon_data.is_empty():
		info_label.text = "Weapon data missing!"
		return

	if weapon_data.has("icon"):
		weapon_icon.texture = load(weapon_data.icon)
	else:
		weapon_icon.texture = null

	# Se già posseduta
	if GlobalStats.has_weapon(weapon_name, rarity):
		craft_button.disabled = true
		craft_button.text = "Owned"
		info_label.text = owned_weapon_texts_en.pick_random()
		var owned_icon = TextureRect.new()
		owned_icon.texture = load("res://Gres/Assets/UI/Buttons/check_1.png")
		owned_icon.custom_minimum_size = Vector2(250, 250)
		owned_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		material_list.add_child(owned_icon)
		return
	else:
		craft_button.disabled = false
		craft_button.text = "Craft"

	# Costi oro
	var gold_costs := {
		"common": 2000,
		"rare": 5000,
		"epic": 10000,
		"legendary": 25000
	}
	var gold_cost = gold_costs.get(rarity, 0)

	# Materiali richiesti
	for mat_name in weapon_data.craft_materials.keys():
		var required = weapon_data.craft_materials[mat_name]
		var have = 0
		match mat_name:
			"VoidShard": have = GlobalStats.void_shard
			"MagmaShard": have = GlobalStats.magma_shard
			"IceShard": have = GlobalStats.ice_shard
			"LightShard": have = GlobalStats.light_shard
			_: have = 0

		var mat_box = VBoxContainer.new()
		mat_box.alignment = BoxContainer.ALIGNMENT_CENTER
		mat_box.custom_minimum_size = Vector2(72, 90)

		var icon = TextureRect.new()
		icon.texture = load(Global.get_material_icon(mat_name))
		icon.custom_minimum_size = Vector2(64, 64)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mat_box.add_child(icon)

		var qty_label = Label.new()
		qty_label.text = "%d / %d" % [have, required]
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if have < required:
			qty_label.modulate = Color(1, 0.4, 0.4)
		else:
			qty_label.modulate = Color(0.7, 1, 0.7)
		mat_box.add_child(qty_label)
		material_list.add_child(mat_box)

	# Oro
	var gold_box = VBoxContainer.new()
	gold_box.custom_minimum_size = Vector2(72, 90)

	var gold_icon = TextureRect.new()
	gold_icon.texture = load("res://Gres/Assets/Icons/parts/gold_icon.png")
	gold_icon.custom_minimum_size = Vector2(48, 48)
	gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_box.add_child(gold_icon)

	var gold_label = Label.new()
	gold_label.text = "%d / %d" % [GlobalStats.gold, gold_cost]
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if GlobalStats.gold < gold_cost:
		gold_label.modulate = Color(1, 0.6, 0.4)
	else:
		gold_label.modulate = Color(1, 1, 0.6)
	gold_box.add_child(gold_label)
	material_list.add_child(gold_box)

	# Riconnetti pulsante craft (sicuro)
	if craft_button.pressed.is_connected(_on_craft_pressed):
		craft_button.pressed.disconnect(_on_craft_pressed)
	craft_button.pressed.connect(_on_craft_pressed.bind(weapon_name, rarity))

# =====================================
# === CREA L'ARMA === #
# =====================================
func _on_craft_pressed(weapon_name: String, rarity: String):
	# 1. Controlla se già posseduta
	if GlobalStats.has_weapon(weapon_name, rarity):
		info_label.text = "You already own this weapon!"
		craft_button.disabled = true
		return

	# 2. CONTROLLA MATERIALI E ORO PRIMA DI INIZIARE L'ANIMAZIONE
	var weapon_data = Global.get_weapon_data(weapon_name, rarity)
	if weapon_data.is_empty():
		info_label.text = "Weapon data missing!"
		return

	# Controllo oro
	var gold_costs = {
		"common": 2000, "rare": 5000, "epic": 10000, "legendary": 25000
	}
	var gold_cost = gold_costs.get(rarity, 0)
	if GlobalStats.gold < gold_cost:
		info_label.text = "💰 Not enough gold! Need %d" % gold_cost
		return

	# Controllo materiali
	for mat_name in weapon_data.craft_materials.keys():
		var required = weapon_data.craft_materials[mat_name]
		if required <= 0:
			continue
		var have = 0
		match mat_name:
			"VoidShard": have = GlobalStats.void_shard
			"MagmaShard": have = GlobalStats.magma_shard
			"IceShard": have = GlobalStats.ice_shard
			"LightShard": have = GlobalStats.light_shard
		if have < required:
			info_label.text = "⚠️ Not enough %s! (%d/%d)" % [mat_name, have, required]
			return

	# Se arriviamo qui, procedi con l'animazione
	var time := 10
	match rarity:
		"common": time = randi_range(5, 10)
		"rare": time = randi_range(10, 15)
		"epic": time = randi_range(15, 20)
		_: time = randi_range(20, 30)

	$CraftMan.modulate = Color(1,1,1,0)
	$CraftMan.show()
	$CraftMan/Title.text = craft_w_en.pick_random()
	$CraftMan/progressbar.value = 0

	var tw := create_tween()
	tw.tween_property($CraftMan, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property($CraftMan/progressbar, "value", 100.0, time).set_trans(Tween.TRANS_LINEAR)
	tw.tween_callback(Callable(self, "_on_craft_complete").bind(weapon_name, rarity))
	$CraftMan/WeaponL.text = "[pulse freq=2.0]" + rarity.capitalize() + " " + weapon_name.capitalize() + "[/pulse]"
	craft_button.disabled = true
	$CraftMan/Cryst1.emitting = true
	$CraftMan/craft1.playing = true
	await get_tree().create_timer(0.3)
	$CraftMan/craft2.playing = true
	await get_tree().create_timer(0.3)
	$CraftMan/craft3.playing = true
	await get_tree().create_timer(0.1)
	$CraftMan/craft4.playing = true
# =====================================
# === COMPLETAMENTO CRAFT === #
# =====================================
func _on_craft_complete(weapon_name: String, rarity: String):
	$CraftMan/Done.playing = true
	var result := Global.craft_weapon(weapon_name, rarity)
	info_label.text = result

	GlobalStats.add_owned_weapon(weapon_name, rarity)
	Global.unlock_weapon(weapon_name, rarity)

	# Ricarica la vista (l'arma ora è posseduta)
	_on_weapon_selected(weapon_name, rarity)

	var tw := create_tween()
	tw.tween_property($CraftMan, "modulate:a", 0.0, 0.5)
	tw.tween_callback(Callable($CraftMan, "hide"))

	craft_button.disabled = false
	GlobalStats.total_craft += 1


func _on_trs_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close":
		get_tree().change_scene_to_file("res://Gres/Scenes/UI/craft_edit_ui.tscn")

func _on_exit_craft() -> void:
	$trs.play("close")
