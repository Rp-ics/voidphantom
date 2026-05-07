extends Node2D

@onready var title_label = $Title
@onready var desc_label = $Description
@onready var replay_button = $Replay
@onready var menu_button = $Menu
@onready var anim_player = $game_over

var is_showing := false
var can_gover := true

var phrases = {
	2: [
		"Damn, that's all? Only wave %d?",
		"Bruh... wave %d? Seriously?",
		"Wave %d and already toast? Ouch.",
		"That was pathetic... wave %d."
	],
	5: [
		"Wave %d? Not bad, but still meh.",
		"You're warming up... wave %d.",
		"Could be worse, wave %d."
	],
	10: [
		"Okay, wave %d—getting spicy!",
		"Wave %d, almost respectable!",
		"You're starting to look pro at wave %d."
	],
	9999: [
		"Wave %d?! You're a beast!",
		"Insane run! Wave %d!",
		"Legendary performance at wave %d!",
		"OKAY OKAY TOTAL RESPECT AT WAVE %d!"
	]
}

func _ready() -> void:
	replay_button.connect("pressed", _on_replay_pressed)
	menu_button.connect("pressed", _on_menu_pressed)

func _process(delta: float) -> void:
	if Global.player_dead and can_gover and not is_showing:
		can_gover = false
		show_game_over(Global.wave)

func show_game_over(wave: int) -> void:
	if is_showing:
		return
	
	is_showing = true
	title_label.text = "GAME OVER"
	
	var key := 9999
	for k in phrases.keys():
		if wave <= k:
			key = k
			break
	
	var chosen_phrase = phrases[key].pick_random()
	desc_label.text = chosen_phrase % wave
	
	if anim_player.has_animation("blur"):
		anim_player.play("blur")

func reset_game() -> void:
	# Usa una funzione dedicata in Global se possibile
	Global.player_dead = false
	Global.player_hp = Global.player_max_hp
	Global.player_stamina = Global.player_max_stamina
	Global.bullets = Global.max_bullets
	Global.wave = 1
	is_showing = false
	GlobalStats.player_damage_lvl = 0
	GlobalStats.player_hit_lvl = 0
	GlobalStats.player_min_hp_lvl = 0
	GlobalStats.total_hp_bossfight_lvl = 0
	GlobalStats.kill_mobs_lvl = 0
	GlobalStats.kill_mini_boss_lvl = 0
	GlobalStats.damage_inf_mob_lvl = 0
	GlobalStats.damage_inf_miniboss_lvl = 0
	GlobalStats.damage_inf_boss_lvl = 0
	GlobalStats.damage_inf_total_lvl = 0
	GlobalStats.damage_rec_lvl = 0
	GlobalStats.damage_rec_boss_lvl = 0
	GlobalStats.damage_rec_miniboss_lvl = 0
	GlobalStats.nuclear_kill_lvl = 0
	GlobalStats.nuclear_boss_dmg_lvl = 0
	GlobalStats.nuclear_destroyed_lvl = 0
	GlobalStats.bullets_shoot_lvl = 0
	GlobalStats.bonus_get_lvl = 0
	GlobalStats.powerups_lvl = 0
	GlobalStats.weapon_collected_lvl = 0
	
func _on_replay_pressed() -> void:
	reset_game()
	GlobalInventory.clear()
	if anim_player.has_animation("replay"):
		anim_player.play("replay")
	else:
		get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	reset_game()
	GlobalInventory.clear()
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")

func _on_game_over_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"replay":
			get_tree().reload_current_scene()
