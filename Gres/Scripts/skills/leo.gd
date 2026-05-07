extends Node2D

var current_skill := ""

func _ready() -> void:
	update_skill_buttons("leo_", 4)

	for i in range(1, 5):
		_update_skill_ui("leo_%d" % i)

	# connessioni pulsanti
	$A1.pressed.connect(_on_skill_pressed.bind("leo_1"))
	$A2.pressed.connect(_on_skill_pressed.bind("leo_2"))
	$A3.pressed.connect(_on_skill_pressed.bind("leo_3"))
	$A4.pressed.connect(_on_skill_pressed.bind("leo_4"))
	$A5.pressed.connect(_on_skill_pressed.bind("leo_5"))

	# Panel info
	$"../../Buttons/InfoSkills/Upgrade".pressed.connect(_on_buy_pressed)

	# Auto-refresh info
	$"../../Updater".timeout.connect(func():
		if current_skill != "":
			_update_info()
	)
	$"../../Updater".start()

func _process(delta: float) -> void:
	if Global.can_activate:
		Global.can_activate = false
		$"../../Buttons/Next".disabled = false
		$"../../Buttons/Back".disabled = false
		$"../../Buttons/close".disabled = false
# ---------------------------------------------------------
#   GRAFO → TROVA I PADRI
# ---------------------------------------------------------
func _get_parents(skill: String) -> Array:
	var result: Array = []
	for key in GlobalSkills.zodiac_skill_graph.keys():
		if skill in GlobalSkills.zodiac_skill_graph[key]:
			result.append(key)
	return result

func get_local_skills():
	var out := []
	for k in GlobalSkills.zodiac_skill_data.keys():
		if k.begins_with("leo_"):
			out.append(k)
	return out

# ---------------------------------------------------------
#   ABILITA/DISABILITA BOTTONI
# ---------------------------------------------------------
func update_skill_buttons(sign_prefix: String, max_skills: int):
	var data = GlobalSkills.zodiac_skill_data

	# blocca tutto
	for i in range(1, max_skills + 1):
		var btn = get_node_or_null("A%d" % i)
		if btn:
			btn.disabled = true

	# prima skill
	var first = "%s1" % sign_prefix
	if not data[first]["unlocked"]:
		var b = get_node_or_null("A1")
		if b:
			b.disabled = false

	# tutte le altre seguono i padri
	for skill_name in GlobalSkills.zodiac_skill_graph.keys():
		if not skill_name.begins_with(sign_prefix):
			continue

		if skill_name == first:
			continue

		var parents = _get_parents(skill_name)
		for p in parents:
			if data[p]["unlocked"]:
				var idx = int(skill_name.split("_")[1])
				var btn = get_node_or_null("A%d" % idx)
				if btn:
					btn.disabled = data[skill_name]["unlocked"]
				break

# ---------------------------------------------------------
#   AGGIORNA UI DELLA SINGOLA SKILL
# ---------------------------------------------------------
func _update_skill_ui(skill_name: String):
	var sdata = GlobalSkills.zodiac_skill_data[skill_name]
	var id = int(skill_name.split("_")[1])

	var pb = get_node_or_null("PB%d" % id)
	if pb:
		pb.value = sdata.progress

	if sdata["unlocked"]:
		match id:
			1: $star_min_2.modulate = Color(1,1,1,1)
			2: $star_max_1.modulate = Color(1,1,1,1)
			3: $star_min_4.modulate = Color(1,1,1,1); $star_min_3.modulate = Color(1,1,1,1); $PB4.value = 100; $PB3.value = 100

# ---------------------------------------------------------
#   CLICK SU SKILL
# ---------------------------------------------------------
func _on_skill_pressed(skill_name: String) -> void:
	$"../../Buttons/Next".disabled = true
	$"../../Buttons/Back".disabled = true
	$"../../Buttons/close".disabled = true
	current_skill = skill_name
	_show_info_panel()
	_update_info()

# ---------------------------------------------------------
#   MOSTRA/HIDE INFO PANEL
# ---------------------------------------------------------
func _show_info_panel():
	var panel = $"../../Buttons/InfoSkills"
	panel.modulate = Color(1,1,1,0)
	panel.show()
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.4)

func _hide_info_panel():
	var panel = $"../../Buttons/InfoSkills"
	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, 0.4)
	await get_tree().create_timer(0.4).timeout
	panel.hide()

# ---------------------------------------------------------
#   AGGIORNA TESTO INFO PANEL
# ---------------------------------------------------------
func _update_info():
	if current_skill == "":
		return

	var data = GlobalSkills.zodiac_skills[current_skill]

	var full_text = data.text + \
		"\n\nRespawn Chance: [color=#ffdb3d]" + str(GlobalStats.respawn) + "%" + \
		"[/color]\nHuge Damage: [color=#ffdb3d]" + str(GlobalStats.huge_dmg) + "%[/color]"

	$"../../Buttons/InfoSkills".text = full_text

	var price_str = "[img=60]res://Gres/Assets/obj/tablet_2.png[/img]" + \
	str(GlobalStats.tablet) + "/" + str(data.tablet) + \
	" - [img=80]res://Gres/Assets/Icons/parts/gold_icon.png[/img]" + \
	str(GlobalStats.gold) + "/" + str(data.gold)

	$"../../Buttons/InfoSkills/price".text = price_str

# ---------------------------------------------------------
#   ACQUISTA/UNLOCK SKILL
# ---------------------------------------------------------
func _on_buy_pressed():
	if current_skill == "":
		return

	var conf = GlobalSkills.zodiac_skills[current_skill]
	var sdata = GlobalSkills.zodiac_skill_data[current_skill]

	if sdata["unlocked"]:
		return

	if GlobalStats.tablet < conf.tablet or GlobalStats.gold < conf.gold:
		return

	# paga
	GlobalStats.tablet -= conf.tablet
	GlobalStats.gold -= conf.gold
	GlobalStats.stars += 1
	
	match  current_skill:
		"leo_1": GlobalSkills.zodiac_skill_data["leo_1"]['unlocked'] = true
		"leo_2": GlobalSkills.zodiac_skill_data["leo_2"]['unlocked'] = true
		"leo_3": GlobalSkills.zodiac_skill_data["leo_3"]['unlocked'] = true
		"leo_4": GlobalSkills.zodiac_skill_data["leo_4"]['unlocked'] = true
		"leo_5": GlobalSkills.zodiac_skill_data["leo_5"]['unlocked'] = true
	$"../../Buttons/Next".disabled = false
	$"../../Buttons/Back".disabled = false
	$"../../Buttons/close".disabled = false
	
	# effetti
	GlobalStats.respawn += conf.respawn
	GlobalStats.huge_dmg += conf.huge_dmg
	if current_skill == "leo_3": GlobalStats.double_gold_drop = true
	if GlobalSkills.zodiac_skill_data["leo_4"]['unlocked'] and GlobalSkills.zodiac_skill_data["leo_5"]['unlocked']:
		$"../../Buttons/Next".disabled = true
		$"../../Buttons/Back".disabled = true
		$"../../Buttons/close".disabled = true
		GlobalSkills.zodiac['cancer'] = true
		var effect_scene = load("res://Gres/Scenes/SkillTree/Constellations/leo.tscn")
		var effect = effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = $"../../Leo_Pos".global_position
		
	# set stato
	sdata["unlocked"] = true
	sdata["progress"] = 100

	GlobalSkills.save_all()
	
	_update_skill_ui(current_skill)
	_hide_info_panel()
	update_skill_buttons("leo_", 4)
