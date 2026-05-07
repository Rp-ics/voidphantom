extends Control

# References to child nodes
@onready var grid_container: GridContainer = $Grid

# Specific nodes for each quest
@onready var quest1_label: RichTextLabel = $Grid/Quest1
@onready var quest1_button: Button = $Grid/Quest1/Button

@onready var quest2_label: RichTextLabel = $Grid/Quest2
@onready var quest2_button: Button = $Grid/Quest2/Button

@onready var quest3_label: RichTextLabel = $Grid/Quest3
@onready var quest3_button: Button = $Grid/Quest3/Button

# Label to show progress toward the special coin
@onready var special_coin_label: RichTextLabel = $SpecialCoinLabel

func _ready() -> void:
	if not _validate_nodes():
		print("ERROR: Missing nodes in Quests scene!")
		return
	
	quest1_button.pressed.connect(_on_claim_pressed.bind(0))
	quest2_button.pressed.connect(_on_claim_pressed.bind(1))
	quest3_button.pressed.connect(_on_claim_pressed.bind(2))
	
	refresh_all_quests()
	visibility_changed.connect(_on_visibility_changed)

func _validate_nodes() -> bool:
	var all_valid = true
	
	if not grid_container:
		print("ERROR: GridContainer not found")
		all_valid = false
	if not quest1_label or not quest1_button:
		print("ERROR: Quest1 nodes missing")
		all_valid = false
	if not quest2_label or not quest2_button:
		print("ERROR: Quest2 nodes missing")
		all_valid = false
	if not quest3_label or not quest3_button:
		print("ERROR: Quest3 nodes missing")
		all_valid = false
	
	if not special_coin_label:
		print("WARNING: SpecialCoinLabel not found (optional)")
	
	return all_valid

func _on_visibility_changed() -> void:
	if visible:
		refresh_all_quests()

func refresh_all_quests() -> void:
	if not Global.has_method("get_daily_missions"):
		print("ERROR: Global.daily_missions not accessible")
		return
	
	var missions: Array = GlobalStats.daily_missions
	var labels: Array = [quest1_label, quest2_label, quest3_label]
	var buttons: Array = [quest1_button, quest2_button, quest3_button]
	
	for i in range(3):
		if i < missions.size():
			var mission: Dictionary = missions[i]
			_show_mission(labels[i], buttons[i], mission, i)
		else:
			labels[i].text = "[center]No mission available[/center]"
			buttons[i].visible = false
	
	_update_special_coin_progress()

func _show_mission(label: RichTextLabel, button: Button, mission: Dictionary, index: int) -> void:
	if not label or not button:
		print("ERROR: label or button is null for index", index)
		return
	
	var target: int = mission.get("target", 0)
	var progress: int = mission.get("progress", 0)
	var claimed: bool = mission.get("claimed", false)
	var title: String = mission.get("display_name", "???")
	var description: String = mission.get("description", "")
	var reward_gold: int = mission.get("reward_gold", 0)
	
	# Build formatted text: Title, Objective, Reward, Progress
	var text: String = "[center][color=orange]%s[/color][/center]\n" % title
	text += "Objective: [color=7b86ff]%s[/color]\n" % description
	text += "Reward: [color=yellow]+%d Gold[/color]\n" % reward_gold
	
	if progress >= target:
		text += "[color=green]✓ Progress: %d/%d[/color]" % [progress, target]
	else:
		text += "Progress: %d/%d" % [progress, target]
	
	label.text = text
	
	button.visible = true
	
	if claimed:
		button.text = "✓ COMPLETED"
		button.disabled = true
		button.modulate = Color(0.3, 0.8, 0.3)
	elif progress >= target:
		button.text = "CLAIM (+%d G)" % reward_gold
		button.disabled = false
		button.modulate = Color(1, 0.9, 0.3)
	else:
		button.text = "In progress..."
		button.disabled = true
		button.modulate = Color(0.5, 0.5, 0.5)

func _update_special_coin_progress() -> void:
	if not special_coin_label:
		return
	
	var progress: int = GlobalStats.special_coin_progress
	var total_needed: int = 3
	
	var bar: String = "["
	for i in range(total_needed):
		bar += "★" if i < progress else "☆"
	bar += "]"
	
	special_coin_label.text = "[center][img=20]res://Gres/Assets/Icons/black_hole_bonus.png[/img] %s %d/%d[/center]" % [bar, progress, total_needed]
	
	special_coin_label.modulate = Color(1, 0.8, 0) if progress >= total_needed - 1 else Color.WHITE

func _on_claim_pressed(index: int) -> void:
	print("Attempting to claim mission:", index)
	
	if index < 0 or index >= GlobalStats.daily_missions.size():
		print("ERROR: Invalid mission index:", index)
		return
	
	var mission: Dictionary = GlobalStats.daily_missions[index]
	
	if mission.get("claimed", false):
		print("Mission already claimed")
		return
	
	if mission.get("progress", 0) < mission.get("target", 0):
		print("Mission not yet completed")
		return
	
	if not Global.has_method("claim_mission"):
		print("ERROR: Global.claim_mission does not exist!")
		return
	
	var result: String = Global.claim_mission(index)
	print("Claim result:", result)
	_show_result_popup(result)
	refresh_all_quests()

func _show_result_popup(message: String) -> void:
	var popup = AcceptDialog.new()
	popup.title = "MISSION REWARD"
	popup.dialog_text = message
	popup.size = Vector2(400, 150)
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(popup.queue_free)
	popup.canceled.connect(popup.queue_free)
	
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func():
		if is_instance_valid(popup):
			popup.queue_free()
		)
	add_child(timer)
	timer.start()

func _on_close_button_pressed() -> void:
	GlobalTweens.fade($".", 1.0, 0.0, 0.5)
	$Timer.start()

func _on_timer_timeout() -> void:
	$".".hide()
