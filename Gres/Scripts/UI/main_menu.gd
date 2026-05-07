extends Control

var bgs = [
	"res://Gres/Assets/BGame/galaxy1.png",
	"res://Gres/Assets/BGame/galaxy2.png",
	"res://Gres/Assets/BGame/galaxy6.png",
	"res://Gres/Assets/BGame/galaxy7.png",
	"res://Gres/Assets/BGame/galaxy9.png",
	"res://Gres/Assets/BGame/galaxy10.png",
	"res://Gres/Assets/Background/bgstar_9.png",
	"res://Gres/Assets/Background/bgstar_10.png",
	"res://Gres/Assets/Background/bgstar_1.png",
]

var paralax = [
	"res://Gres/Assets/BGame/galaxy11.png",
	"res://Gres/Assets/BGame/galaxy12.png",
	"res://Gres/Assets/BGame/galaxy13.png",
	"res://Gres/Assets/BGame/galaxy14.png",
	"res://Gres/Assets/BGame/galaxy15.png",
]

var mode := ""
var press := 0

@onready var camera = $Camera

func _ready():
	Global.player_hp = Global.player_max_hp
	Global.player_stamina = Global.player_max_stamina
	
	GlobalStats.achievements["Was Easy"] = true
	check_daily_spin()
	$MaxOffset.value = Global.menu_max_offset
	$SmoothSpeed.value = Global.menu_smooth_speed
	$MaxOffset/Label.text = str("Max Offset: ", Global.menu_max_offset)
	$SmoothSpeed/Label.text = str("Smooth Speed: ", Global.menu_smooth_speed)
	
	var bg = bgs.pick_random()
	var prl = paralax.pick_random()
	$ColorRect3/TextureRect.texture = load(bg)
	$Camera/paralax.texture = load(prl)
	$Buttons/Editor/SellerBot/Edit.connect("mouse_entered", on_editor_mouse_enter)
	$Buttons/Editor/SellerBot/Edit.connect("mouse_exited", on_editor_mouse_exit)
	$Buttons/Editor/SellerBot/Edit.connect("pressed", on_editor_mouse_pressed)
	
	$Buttons/Constel/st3/st2/st1/Constelations.connect("mouse_entered", on_const_mouse_enter)
	$Buttons/Constel/st3/st2/st1/Constelations.connect("mouse_exited", on_const_mouse_exit)
	$Buttons/Constel/st3/st2/st1/Constelations.connect("pressed", on_const_mouse_pressed)
	
	$Buttons/Play.connect("pressed", _on_fight_pressed)
	$Buttons/Settings.connect("pressed", _on_settings_pressed)
	

func _process(delta: float) -> void:
	# Posizione del mouse relativa al centro dello schermo
	var screen_center = get_viewport_rect().size / 2
	var mouse_pos = get_global_mouse_position()
	var offset = (mouse_pos - screen_center)
	
	# Limitiamo l'offset
	if offset.length() > Global.menu_max_offset:
		offset = offset.normalized() * Global.menu_max_offset
	
	# Movimento fluido verso la posizione target
	camera.position = camera.position.move_toward(screen_center + offset, Global.menu_smooth_speed * delta)
	
	# Particelle seguono il mouse normalmente
	$Particles.position = mouse_pos

func on_editor_mouse_enter() -> void:
	$Buttons/Editor/SellerBot.frame = 1
func on_editor_mouse_exit() -> void:
	$Buttons/Editor/SellerBot.frame = 0
func on_editor_mouse_pressed() -> void:
	mode = "editor"
	$trs.play("close")

func on_const_mouse_enter() -> void:
	$Buttons/Constel/st3/st2.modulate = Color(1,1,1,1)
	$Buttons/Constel/st3/PB1.value = 100
	$Buttons/Constel/st3/PB2.value = 100
	$Buttons/Constel/st3/PB3.value = 100
	$Buttons/Constel/st3/PB4.value = 100
func on_const_mouse_exit() -> void:
	$Buttons/Constel/st3/st2.modulate = Color(1,1,1,0.4)
	$Buttons/Constel/st3/PB1.value = 0
	$Buttons/Constel/st3/PB2.value = 0
	$Buttons/Constel/st3/PB3.value = 0
	$Buttons/Constel/st3/PB4.value = 0
	
func on_const_mouse_pressed() -> void:
	mode = "const"
	$trs.play("close")

func _on_trs_animation_finished(anim_name: StringName) -> void:
	if anim_name == "close":
		if mode == 'editor':
			get_tree().change_scene_to_file("res://Gres/Scenes/UI/craft_edit_ui.tscn")
		elif mode == "const":
			get_tree().change_scene_to_file("res://Gres/Scenes/SkillTree/skill_tree.tscn")
		elif mode == "fight":
			get_tree().change_scene_to_file("res://Gres/Scenes/UI/map_choice.tscn")
		elif mode == "wheel":
			get_tree().change_scene_to_file("res://Gres/Scenes/UI/daily_wheel.tscn")
func _on_fight_pressed() -> void:
	mode = "fight"
	$trs.play("close")
	
func _on_close_popup_pressed() -> void:
	GlobalTweens.fade($DailyPopup, 1, 0, 1)
	await get_tree().create_timer(1.2)
	$DailyPopup.hide()

func _on_wheel_pressed() -> void:
	mode = "wheel"
	$trs.play("close")

func check_daily_spin():
	if !GlobalStats.free_spin_used_today or Global.spin_gem > 0:
		$Buttons/arrow.show()
	else: $Buttons/arrow.hide()

func _on_settings_pressed() -> void:
	$SettingsMan.show()
	GlobalTweens.fade($SettingsMan, 0, 1, 0.6)


func _on_play_pressed() -> void:
	if !Global.bonus_taken:
		Global.bonus_taken = true
		GlobalStats.gold += 2600
		GlobalStats.ice_shard += 10
		GlobalStats.void_shard += 10
		GlobalStats.light_shard += 10
		GlobalStats.magma_shard += 10
		Global.LOCKED_BODIES.erase(15)
		Global.LOCKED_PROPS.erase(15)
		Global.LOCKED_WINGS.erase(15)
		Global.spin_gem += 5
		get_tree().change_scene_to_file("res://Gres/Scenes/obj/void_chest.tscn")

func _on_score_board_pressed() -> void:
	$ScoreBoard.show()
	GlobalTweens.fade($ScoreBoard/container,0, 1, 0.5)
	

func _on_exit_pressed() -> void:
	$leave.play("leave")


func _on_leave_animation_finished(anim_name: StringName) -> void:
	var what = NOTIFICATION_WM_CLOSE_REQUEST
	Global.notification(what)


func _on_smooth_speed_value_changed(value: float) -> void:
	Global.menu_smooth_speed = value
	$SmoothSpeed/Label.text = str("Smooth Speed: ", Global.menu_smooth_speed)

func _on_max_offset_value_changed(value: float) -> void:
	Global.menu_max_offset = value
	$MaxOffset/Label.text = str("Max Offset: ", Global.menu_max_offset)


func _on_code_b_pressed() -> void:
	press += 1
	$CodeB/Timer.start()
	if press >= 2:
		$CodeB/LineEdit.show()
func _on_timer_timeout() -> void:
	press = 0


func _on_multiplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://Multiplayer/UI/PvPLobbyUI.tscn")


func _on_craft_pressed() -> void:
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/crafting_menu.tscn")
