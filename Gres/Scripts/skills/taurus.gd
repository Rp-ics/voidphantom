extends Node2D

var current_skill := ""

func _ready() -> void:
	update_skill_buttons("taurus_", 10)
	for i in range(1, 11):
		_update_skill_ui("taurus_%d" % i)

	# connessioni pulsanti
	$A1.pressed.connect(_on_skill_pressed.bind("taurus_1"))
	$A2.pressed.connect(_on_skill_pressed.bind("taurus_2"))
	$A3.pressed.connect(_on_skill_pressed.bind("taurus_3"))
	$A4.pressed.connect(_on_skill_pressed.bind("taurus_4"))
	$A5.pressed.connect(_on_skill_pressed.bind("taurus_5"))
	$A6.pressed.connect(_on_skill_pressed.bind("taurus_6"))
	$A7.pressed.connect(_on_skill_pressed.bind("taurus_7"))
	$A8.pressed.connect(_on_skill_pressed.bind("taurus_8"))
	$A9.pressed.connect(_on_skill_pressed.bind("taurus_9"))
	$A10.pressed.connect(_on_skill_pressed.bind("taurus_10"))

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
		if k.begins_with("taurus_"):
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
			3: $star_min_3.modulate = Color(1,1,1,1)
			4: $star_min_4.modulate = Color(1,1,1,1); $star_min_6.modulate = Color(1,1,1,1); $PB7.value = 100
			5: $star_min_5.modulate = Color(1,1,1,1)
			6: $star_max_2.modulate = Color(1,1,1,1)
			8: $star_min_7.modulate = Color(1,1,1,1)
			9: $star_max_3.modulate = Color(1,1,1,1)
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
		"\n\nMax HP: [color=#ffdb3d]" + str(Global.player_max_hp) + \
		"[/color]\nMax Stamina: [color=#ffdb3d]x" + str(Global.player_max_stamina) + "[/color]" + \
		"\nChance to not consume Stamina: [color=#ffdb3d]" + str(Global.chance_not_consum_stamina) + "%"

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
	
	match current_skill:
		"taurus_1": GlobalSkills.zodiac_skill_data['taurus_1']['unlocked'] = true
		"taurus_2": GlobalSkills.zodiac_skill_data['taurus_2']['unlocked'] = true
		"taurus_3": GlobalSkills.zodiac_skill_data['taurus_3']['unlocked'] = true
		"taurus_1": GlobalSkills.zodiac_skill_data['taurus_1']['unlocked'] = true
		"taurus_5": GlobalSkills.zodiac_skill_data['taurus_5']['unlocked'] = true
		"taurus_6": GlobalSkills.zodiac_skill_data['taurus_6']['unlocked'] = true
		"taurus_7": GlobalSkills.zodiac_skill_data['taurus_7']['unlocked'] = true
		"taurus_8": GlobalSkills.zodiac_skill_data['taurus_8']['unlocked'] = true
		"taurus_9": GlobalSkills.zodiac_skill_data['taurus_9']['unlocked'] = true
		"taurus_10": GlobalSkills.zodiac_skill_data['taurus_10']['unlocked'] = true
	
	# paga
	GlobalStats.tablet -= conf.tablet
	GlobalStats.gold -= conf.gold
	GlobalStats.stars += 1
	
	$"../../Buttons/Next".disabled = false
	$"../../Buttons/Back".disabled = false
	$"../../Buttons/close".disabled = false
	# effetti
	Global.player_max_hp += conf.player_max_hp
	Global.player_max_stamina += conf.player_max_stamina
	if current_skill in ["taurus_3","taurus_7","taurus_10"]:
		Global.chance_not_consum_stamina += 2.0
		
	if GlobalSkills.zodiac_skill_data['taurus_7']['unlocked'] and GlobalSkills.zodiac_skill_data['taurus_10']['unlocked']:
		$"../../Buttons/Next".disabled = true
		$"../../Buttons/Back".disabled = true
		$"../../Buttons/close".disabled = true
		GlobalSkills.zodiac['taurus'] = true
		var effect_scene = load("res://Gres/Scenes/SkillTree/Constellations/taurus.tscn")
		var effect = effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = $"../../Taurus_Pos".global_position
		
	# set stato
	sdata["unlocked"] = true
	sdata["progress"] = 100

	GlobalSkills.save_all()

	
	_update_skill_ui(current_skill)
	_hide_info_panel()
	update_skill_buttons("taurus_", 10)
