extends Control

var bonus_name = ""
var prices = [500, 1500, 2600, 3500, "0000"]

var shield_inf_en = """
[color=#00c8ff]PHOTON SHIELD[/color]

[color=#aaaaaa]Generates an energy barrier that blocks all incoming damage for a short duration.[/color]

[color=#ffd700]Level 0:[/color] Duration [color=#00ffcc]0.5s[/color]

[color=#df03fc]UPDATES[/color]
[color=#ffd700]Level 1:[/color] Duration +[color=#00ffcc]0.5s[/color]
[color=#ffd700]Level 2:[/color] Duration +[color=#00ffcc]2s[/color]
[color=#ffd700]Level 3:[/color] Duration +[color=#00ffcc]1s[/color]
[color=#ffd700]Level 4:[/color] Duration +[color=#00ffcc]2s[/color]
"""

var stamina_inf_en = """
[color=#00ff88]STAMINA IMPULSE[/color]

[color=#aaaaaa]Injects synthetic energy into the pilot’s system, rapidly restoring stamina reserves.[/color]

[color=#ffd700]Level 0:[/color] Restores +[color=#00ffcc]10[/color] stamina

[color=#df03fc]UPDATES[/color]
[color=#ffd700]Level 1:[/color] Restores +[color=#00ffcc]15[/color] stamina
[color=#ffd700]Level 2:[/color] Restores +[color=#00ffcc]25[/color] stamina
[color=#ffd700]Level 3:[/color] Restores +[color=#00ffcc]30[/color] stamina
[color=#ffd700]Level 4:[/color] Restores +[color=#00ffcc]50[/color] stamina + [color=#ffaa00]grants [color=#fcdb03]+5[/color] regen for 3s[/color]
"""

var heart_inf_en = """
[color=#ff5577]REGENERATIVE CORE[/color]

[color=#aaaaaa]Activates nanite systems that heal and repair the pilot’s main hull.[/color]

[color=#ffd700]Level 0:[/color] Restores [color=#00ffcc]+15 HP[/color]

[color=#df03fc]UPDATES[/color]
[color=#ffd700]Level 1:[/color] Restores [color=#00ffcc]+15 HP[/color]
[color=#ffd700]Level 2:[/color] Restores [color=#00ffcc]+30 HP[/color]  
[color=#ffd700]Level 3:[/color] Restores [color=#00ffcc]+45 HP[/color]  
[color=#ffd700]Level 4:[/color] Restores [color=#00ffcc]+60 HP[/color] + [color=#ffaa00]passive regen for 5s[/color]
"""

var time_inf_en = """
[color=#cc99ff]TEMPORAL DISTORTION[/color]

[color=#aaaaaa]Bends local spacetime, slowing all enemies and projectiles while the pilot remains unaffected.[/color]

[color=#ffd700]Level 0:[/color] Slows time for [color=#00ffcc]0.2s[/color]

[color=#df03fc]UPGRADES[/color]
[color=#ffd700]Level 1:[/color] Duration +[color=#00ffcc]0.2s[/color]  
[color=#ffd700]Level 2:[/color] Duration +[color=#00ffcc]0.4s[/color] • [color=#ffaa00]+5%[/color] enemies nearly [color=#ff4444]frozen[/color]  
[color=#ffd700]Level 3:[/color] Duration +[color=#00ffcc]0.2s[/color]  
[color=#ffd700]Level 4:[/color] Duration +[color=#00ffcc]0.4s[/color] • [color=#ffaa00]+25%[/color] enemies nearly [color=#ff4444]frozen[/color]
"""

func _ready() -> void:
	GlobalStats.gold = 150000
	$gold.text = str(GlobalStats.gold)
	$SkillGrid/Skill1/ShieldB.connect("mouse_entered", on_mouse_shield_entered)
	$SkillGrid/Skill2/StaminaB.connect("mouse_entered", on_mouse_stamina_entered)
	$SkillGrid/Skill3/HeartB.connect("mouse_entered", on_mouse_heart_entered)
	$SkillGrid/Skill4/TimeB.connect("mouse_entered", on_mouse_time_entered)

	$SkillGrid/Skill1/ShieldB.connect("pressed", on_shield_pressed)
	$SkillGrid/Skill2/StaminaB.connect("pressed", on_stamina_pressed)
	$SkillGrid/Skill3/HeartB.connect("pressed", on_heart_pressed)
	$SkillGrid/Skill4/TimeB.connect("pressed", on_time_pressed)
	
	$UpdateMan/man/Update.connect("pressed", on_update_pressed)
	$UpdateMan/man/Close.connect("pressed", on_close_pressed)

func on_mouse_shield_entered() -> void:
	$InfoSkills.text = shield_inf_en
	
func on_mouse_stamina_entered() -> void:
	$InfoSkills.text = stamina_inf_en
	
func on_mouse_heart_entered() -> void:
	$InfoSkills.text = heart_inf_en
	
func on_mouse_time_entered() -> void:
	$InfoSkills.text = time_inf_en


func show_tw():
	$UpdateMan.show()
	$UpdateMan.modulate.a = 0.0
	$UpdateMan/man.position = $CenterP.position
	var s_tween = create_tween()
	s_tween.tween_property($UpdateMan, "modulate:a", 1, 0.5).set_ease(Tween.EASE_IN)
	s_tween.tween_property($UpdateMan/man, "position:x", $LeftP.position.x -10, 0.5).set_ease(Tween.EASE_IN)
	s_tween.tween_property($UpdateMan/man, "position:x", $LeftP.position.x +10, 0.2).set_ease(Tween.EASE_IN)
	s_tween.tween_property($UpdateMan/man, "position:x", $LeftP.position.x, 0.2).set_ease(Tween.EASE_IN)
	await s_tween.finished
	
func hide_tw():
	var s_tween = create_tween()
	s_tween.tween_property($UpdateMan, "modulate:a", 0, 0.5).set_ease(Tween.EASE_IN)
	s_tween.tween_callback(Callable($UpdateMan, "hide"))
	await s_tween.finished

func update_tween():
	var s_tween = create_tween()
	s_tween.tween_property($UpdateMan/man/icon, "modulate", Color.DARK_KHAKI, 0.2).set_ease(Tween.EASE_IN)
	s_tween.tween_property($UpdateMan/man/icon, "modulate", Color.DARK_ORANGE, 0.2).set_ease(Tween.EASE_IN)
	s_tween.tween_property($UpdateMan/man/icon, "modulate", Color.WHITE, 0.2).set_ease(Tween.EASE_IN)
	await s_tween.finished

func update_info():
	$gold.text = str(GlobalStats.gold)
	match bonus_name:
		"shield":
			if GlobalStats.shield_bonus >= 4:
				$UpdateMan/man/icon/Texture.texture = load("res://Gres/Assets/Icons/shield_1.png")
				$UpdateMan/man/Cost.text = "0000"
				$UpdateMan/man/SkillsProgress.frame = GlobalStats.shield_bonus
				$UpdateMan/man/Update.disabled = true
			else:
				$UpdateMan/man/Update.disabled = false
				
			if GlobalStats.shield_bonus < 5:
				$UpdateMan/man/icon/Texture.texture = load("res://Gres/Assets/Icons/shield_1.png")
				$UpdateMan/man/Cost.text = str(prices[GlobalStats.shield_bonus])
				$UpdateMan/man/SkillsProgress.frame = GlobalStats.shield_bonus
		
		"stamina":
			if GlobalStats.stamina_bonus >= 4:
				$UpdateMan/man/icon/Texture.texture = load("res://Gres/Assets/Icons/stamina_1.png")
				$UpdateMan/man/Cost.text = "0000"
				$UpdateMan/man/SkillsProgress.frame = GlobalStats.shield_bonus
				$UpdateMan/man/Update.disabled = true
			else:
				$UpdateMan/man/Update.disabled = false
				
			if GlobalStats.stamina_bonus < 5:
				$UpdateMan/man/icon/Texture.texture = load("res://Gres/Assets/Icons/stamina_1.png")
				$UpdateMan/man/Cost.text = str(prices[GlobalStats.stamina_bonus])
				$UpdateMan/man/SkillsProgress.frame = GlobalStats.stamina_bonus
				
		"heart":
			if GlobalStats.heal_bonus >= 4:
				$UpdateMan/man/icon/Texture.texture = load("res://Gres/Assets/Icons/heart_1.png")
				$UpdateMan/man/Cost.text = "0000"
				$UpdateMan/man/SkillsProgress.frame = GlobalStats.shield_bonus
				$UpdateMan/man/Update.disabled = true
			else:
				$UpdateMan/man/Update.disabled = false
				
			if GlobalStats.heal_bonus < 5:
				$UpdateMan/man/icon/Texture.texture = load("res://Gres/Assets/Icons/heart_1.png")
				$UpdateMan/man/Cost.text = str(prices[GlobalStats.heal_bonus])
				$UpdateMan/man/SkillsProgress.frame = GlobalStats.heal_bonus
		"time":
			if GlobalStats.time_slow_bonus >= 4:
				$UpdateMan/man/icon/Texture.texture = load("res://Gres/Assets/Icons/time_slow_1.png")
				$UpdateMan/man/Cost.text = "0000"
				$UpdateMan/man/SkillsProgress.frame = GlobalStats.heal_bonus
				$UpdateMan/man/Update.disabled = true
			else:
				$UpdateMan/man/Update.disabled = false
				
			if GlobalStats.time_slow_bonus < 5:
				$UpdateMan/man/icon/Texture.texture = load("res://Gres/Assets/Icons/time_slow_1.png")
				$UpdateMan/man/Cost.text = str(prices[GlobalStats.time_slow_bonus])
				$UpdateMan/man/SkillsProgress.frame = GlobalStats.time_slow_bonus

func on_shield_pressed() -> void:
	bonus_name = "shield"
	update_info()
	show_tw()
	
func on_stamina_pressed() -> void:
	bonus_name = "stamina"
	update_info()
	show_tw()
	
func on_heart_pressed() -> void:
	bonus_name = "heart"
	update_info()
	show_tw()
	
func on_time_pressed() -> void:
	bonus_name = "time"
	update_info()
	show_tw()
	

func on_update_pressed() -> void:
	match bonus_name:
		"shield":
			if GlobalStats.gold >= prices[GlobalStats.shield_bonus] and GlobalStats.shield_bonus < 5:
				GlobalStats.gold -= prices[GlobalStats.shield_bonus]
				GlobalStats.shield_bonus += 1
				update_info()
				update_tween()
		"stamina":
			if GlobalStats.gold >= prices[GlobalStats.stamina_bonus] and GlobalStats.stamina_bonus < 5:
				GlobalStats.gold -= prices[GlobalStats.stamina_bonus]
				GlobalStats.stamina_bonus += 1
				update_info()
				update_tween()
		"heart":
			if GlobalStats.gold >= prices[GlobalStats.heal_bonus] and GlobalStats.heal_bonus < 5:
				GlobalStats.gold -= prices[GlobalStats.heal_bonus]
				GlobalStats.heal_bonus += 1
				update_info()
				update_tween()
		"time":
			if GlobalStats.gold >= prices[GlobalStats.time_slow_bonus] and GlobalStats.time_slow_bonus < 5:
				GlobalStats.gold -= prices[GlobalStats.time_slow_bonus]
				GlobalStats.time_slow_bonus += 1
				update_info()
				update_tween()
	
func on_close_pressed() -> void:
	hide_tw()
