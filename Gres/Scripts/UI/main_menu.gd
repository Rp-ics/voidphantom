extends Control

var bgs = [
	"res://Gres/Assets/BGame/galaxy1.png",
	"res://Gres/Assets/BGame/galaxy2.png",
	"res://Gres/Assets/BGame/galaxy3.png",
	"res://Gres/Assets/BGame/galaxy4.png",
	"res://Gres/Assets/BGame/galaxy5.png",
]
var paralax = [
	"res://Gres/Assets/BGame/galaxy6.png",
	"res://Gres/Assets/BGame/galaxy7.png",
	"res://Gres/Assets/BGame/galaxy8.png",
	"res://Gres/Assets/BGame/galaxy9.png",
	"res://Gres/Assets/BGame/galaxy10.png",
	"res://Gres/Assets/BGame/galaxy11.png",
	"res://Gres/Assets/BGame/galaxy12.png",
	"res://Gres/Assets/BGame/galaxy13.png",
	"res://Gres/Assets/BGame/galaxy14.png",
	"res://Gres/Assets/BGame/galaxy15.png",
]

var mode := ""
var press := 0

var setshow := false

@onready var camera = $Camera
@onready var code_line_edit = $MultiplayerUI/CodeLine
@onready var host_button = $MultiplayerUI/HostButton
@onready var join_button = $MultiplayerUI/JoinButton
@onready var enter_lobby_button = $MultiplayerUI/EnterLobby
@onready var back_join_button = $MultiplayerUI/BackJoin
@onready var find_match_button = $MultiplayerUI/FindMatchButton if has_node("MultiplayerUI/FindMatchButton") else null
@onready var matchmaking_status_label = $MultiplayerUI/MatchmakingStatus if has_node("MultiplayerUI/MatchmakingStatus") else null
@onready var coop_button = $Buttons/Coop if has_node("Buttons/Coop") else null

func _ready():
	# === SUBTITLE === #
	GlobalTweens.label_gradient_pulse($MultiplayerUI/Title/Subt, "warm", 4.0, true, 1)
	# ================ #
	$MultiplayerUI/FindMatchButton.pivot_offset = Vector2($MultiplayerUI/FindMatchButton.size/2)
	$MultiplayerUI/HostButton.pivot_offset = Vector2($MultiplayerUI/HostButton.size/2)
	$MultiplayerUI/JoinButton.pivot_offset = Vector2($MultiplayerUI/JoinButton.size/2)
	$MultiplayerUI/EnterLobby.pivot_offset = Vector2($MultiplayerUI/EnterLobby.size/2)
	$MultiplayerUI/BackJoin.pivot_offset = Vector2($MultiplayerUI/BackJoin.size/2)
	
	Global.player_hp = Global.player_max_hp
	Global.player_stamina = Global.player_max_stamina
	$Buttons/Play.pivot_offset = Vector2($Buttons/Play.size/2)
	$Buttons/Multiplayer.pivot_offset = Vector2($Buttons/Multiplayer.size/2)
	$Buttons/Tutorial.pivot_offset = Vector2($Buttons/Tutorial.size/2)
	$Buttons/Exit.pivot_offset = Vector2($Buttons/Exit.size/2)
	if coop_button:
		coop_button.pivot_offset = Vector2(coop_button.size/2)
	
	GlobalStats.achievements["Was Easy"] = true
	$MaxOffset.value = Global.menu_max_offset
	$SmoothSpeed.value = Global.menu_smooth_speed
	$MaxOffset/Label.text = str("Max Offset: ", Global.menu_max_offset)
	$SmoothSpeed/Label.text = str("Smooth Speed: ", Global.menu_smooth_speed)
	
	var bg = bgs.pick_random()
	var prl = paralax.pick_random()
	$ColorRect3/TextureRect.texture = load(bg)
	$Camera/paralax.texture = load(prl)
	$SettingsMUI/scroll/grid/Editor/Edit.connect("pressed", on_editor_mouse_pressed)
	
	$SettingsMUI/scroll/grid/Const/Constelations.connect("pressed", on_const_mouse_pressed)
	
	if coop_button:
		coop_button.pressed.connect(_on_coop_pressed)
	$Buttons/Play.connect("pressed", _on_fight_pressed)
	$SettingsMUI/scroll/grid/Settings/Settings.connect("pressed", _on_settings_pressed)
	$SettingsMUI/SettingsMenu.connect("pressed", _on_settings_menu_pressed)
	
	# ---- MULTIPLAYER: Collega segnali Steam ----
	GlobalSteamScript.lobby_created.connect(_on_lobby_created)
	GlobalSteamScript.lobby_joined.connect(_on_lobby_joined)
	
	# ---- MULTIPLAYER: Pulsanti Host e Join ----
	_ensure_matchmaking_controls()
	if host_button:
		host_button.pressed.connect(_on_host_pressed)
	if join_button:
		join_button.pressed.connect(_on_join_pressed)
	if find_match_button:
		find_match_button.pressed.connect(_on_find_match_pressed)
	
	# Collega segnali per cambio arma multiplayer/singleplayer
	GlobalSteamScript.multiplayer_entered.connect(_on_multiplayer_entered)
	GlobalSteamScript.multiplayer_exited.connect(_on_multiplayer_exited)
	MatchmakingManager.status_changed.connect(_on_matchmaking_status_changed)
	MatchmakingManager.match_found.connect(_on_match_found)
	MatchmakingManager.matchmaking_failed.connect(_on_matchmaking_failed)
	MatchmakingManager.matchmaking_cancelled.connect(_on_matchmaking_cancelled)
	
	# Carica l'ultima arma single player all'avvio
	_restore_single_player_weapon()

func _ensure_matchmaking_controls() -> void:
	if not has_node("MultiplayerUI"):
		return
	var ui := $MultiplayerUI
	if not find_match_button:
		if host_button:
			find_match_button = host_button.duplicate()
		else:
			find_match_button = Button.new()
		find_match_button.name = "FindMatchButton"
		find_match_button.text = "FIND MATCH"
		find_match_button.visible = false
		find_match_button.offset_left = 341.0
		find_match_button.offset_top = 335.0
		find_match_button.offset_right = 771.0
		find_match_button.offset_bottom = 455.0
		ui.add_child(find_match_button)
		
	if not matchmaking_status_label:
		matchmaking_status_label = Label.new()
		matchmaking_status_label.name = "MatchmakingStatus"
		matchmaking_status_label.visible = false
		matchmaking_status_label.offset_left = 228.0
		matchmaking_status_label.offset_top = 285.0
		matchmaking_status_label.offset_right = 924.0
		matchmaking_status_label.offset_bottom = 330.0
		matchmaking_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		matchmaking_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		matchmaking_status_label.add_theme_font_size_override("font_size", 26)
		matchmaking_status_label.add_theme_color_override("font_color", Color.WHITE)
		ui.add_child(matchmaking_status_label)

# Nuove funzioni
func _on_multiplayer_entered():
	print("[MainMenu] Multiplayer iniziato, equipaggio PVP_RAZOR")
	# Salva l'arma SP corrente prima di cambiarla
	Global.last_sp_weapon.name = Global.equipped_weapon.name
	Global.last_sp_weapon.rarity = Global.equipped_weapon.rarity
	# Forza l'arma multiplayer
	if Global.canon:
		Global.canon.equip_weapon("PVP_RAZOR", "common")
	else:
		print("[MainMenu] Canon non trovato, l'arma verrà equipaggiata in arena")

func _on_multiplayer_exited():
	print("[MainMenu] Multiplayer terminato, ripristino arma single player")
	_restore_single_player_weapon()

func _restore_single_player_weapon():
	# Ripristina l'ultima arma usata in single player
	var last_name = Global.last_sp_weapon.name
	var last_rarity = Global.last_sp_weapon.rarity
	if last_name == "":
		last_name = "SOLBREAKER"
		last_rarity = "common"
	
	print("[MainMenu] Ripristino arma: ", last_name, " (", last_rarity, ")")
	if Global.canon:
		Global.canon.equip_weapon(last_name, last_rarity)
	else:
		# Se il canon non è ancora pronto, aspetta
		await get_tree().create_timer(0.5).timeout
		if Global.canon:
			Global.canon.equip_weapon(last_name, last_rarity)

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

func on_const_mouse_pressed() -> void:
	await GlobalTweens.scene_pixel_dissolve(get_tree(), "res://Gres/Scenes/SkillTree/skill_tree.tscn", 100, 0.1)
	
func on_editor_mouse_pressed() -> void:
	await GlobalTweens.scene_pixel_dissolve(get_tree(), "res://Gres/Scenes/UI/craft_edit_ui.tscn", 100, 0.1)
	
func _on_fight_pressed() -> void:
	await GlobalTweens.scene_pixel_dissolve(get_tree(), "res://Gres/Scenes/UI/map_choice.tscn", 100, 0.1)

func _on_wheel_pressed() -> void:
	await GlobalTweens.scene_pixel_dissolve(get_tree(), "res://Gres/Scenes/UI/daily_wheel.tscn", 100, 0.1)
	
func _on_craft_pressed() -> void:
	await GlobalTweens.scene_pixel_dissolve(get_tree(),"res://Gres/Scenes/UI/crafting_menu.tscn", 100, 0.1)


func _on_tutorial_pressed() -> void:
	await GlobalTweens.scene_pixel_dissolve(get_tree(),"res://Gres/Scenes/UI/tutorial.tscn", 100, 0.1)

func _on_close_popup_pressed() -> void:
	GlobalTweens.fade($DailyPopup, 1, 0, 1)
	await get_tree().create_timer(1.2)
	$DailyPopup.hide()

func _on_settings_pressed() -> void:
	$SettingsMan.show()
	GlobalTweens.fade($SettingsMan, 0, 1, 0.6)
	
func _on_settings_menu_pressed() -> void:
	if setshow: # you have to hide
		$SettingsMUI/anim.play("2hide")
		setshow = false
	else:
		$SettingsMUI/anim.play("1show")
		setshow = true

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
		code_line_edit.show()
		code_line_edit.grab_focus()
func _on_timer_timeout() -> void:
	press = 0


func _on_multiplayer_pressed() -> void:
	host_button.show()
	code_line_edit.hide()
	join_button.show()
	if find_match_button:
		find_match_button.show()
	if matchmaking_status_label:
		matchmaking_status_label.hide()
	enter_lobby_button.hide()
	back_join_button.hide()
	$MultiplayerUI.show()



# ============================================================
# MULTIPLAYER FUNZIONI - Versione Steam (globale con SDR)
# ============================================================

func _on_coop_pressed():
	print("[MainMenu] CO-OP button pressed")
	host_button.show()
	code_line_edit.hide()
	join_button.show()
	if find_match_button:
		find_match_button.hide()
	if matchmaking_status_label:
		matchmaking_status_label.hide()
	enter_lobby_button.hide()
	back_join_button.hide()
	$MultiplayerUI.show()
	host_button.text = "HOST CO-OP"
	join_button.text = "JOIN CO-OP"

func _on_host_pressed():
	print("[MainMenu] Host button pressed")
	if $MultiplayerUI/HostButton.text == "HOST CO-OP":
		GlobalSteamScript.create_pve_lobby(4, false)
	else:
		GlobalSteamScript.create_lobby(4, false)

func _on_find_match_pressed() -> void:
	if find_match_button:
		find_match_button.disabled = true
		find_match_button.text = "SEARCHING..."
	if host_button:
		host_button.hide()
	if join_button:
		join_button.hide()
	if matchmaking_status_label:
		matchmaking_status_label.text = "Finding match..."
		matchmaking_status_label.show()
	MatchmakingManager.find_match()

func _on_join_pressed():
	code_line_edit.show()
	host_button.hide()
	join_button.hide()
	if find_match_button:
		find_match_button.hide()
	back_join_button.show()
	enter_lobby_button.show()

func _on_back_join_pressed() -> void:
	_on_multiplayer_pressed()

func _on_enter_lobby_pressed():
	if code_line_edit == null:
		print("[MainMenu] Campo codice non trovato")
		return
	var code = code_line_edit.text.strip_edges().to_upper()
	print("[MainMenu] Join with code: ", code)
	if code.length() != 6:
		print("[MainMenu] Codice non valido, servono 6 caratteri")
		return
	GlobalSteamScript.join_lobby_by_code(code)

func _on_lobby_created(success: bool, lobby_id: int, room_code: String):
	if success:
		print("[MainMenu] Lobby creata con successo. Codice stanza: ", room_code)
	else:
		print("[MainMenu] Errore durante la creazione della lobby")

func _on_lobby_joined(success: bool, lobby_id: int):
	if success:
		print("[MainMenu] Entrato nella lobby. ID: ", lobby_id)
	else:
		print("[MainMenu] Impossibile entrare nella lobby. Codice non valido.")
		_reset_find_match_button()

func _on_matchmaking_status_changed(message: String) -> void:
	if matchmaking_status_label:
		matchmaking_status_label.text = message

func _on_match_found(lobby_id: int) -> void:
	if matchmaking_status_label:
		matchmaking_status_label.text = "Match found! Lobby %s" % str(lobby_id)

func _on_matchmaking_failed(reason: String) -> void:
	if matchmaking_status_label:
		matchmaking_status_label.text = reason
		matchmaking_status_label.show()
	_reset_find_match_button()

func _on_matchmaking_cancelled() -> void:
	_reset_find_match_button()

func _reset_find_match_button() -> void:
	if find_match_button:
		find_match_button.disabled = false
		find_match_button.text = "FIND MATCH"

func _on_close_mu_pressed() -> void:
	if MatchmakingManager.is_searching:
		MatchmakingManager.cancel_matchmaking()
	host_button.show()
	code_line_edit.hide()
	join_button.show()
	if find_match_button:
		find_match_button.show()
	if matchmaking_status_label:
		matchmaking_status_label.hide()
	enter_lobby_button.hide()
	back_join_button.hide()
	$MultiplayerUI.hide()
