extends Node2D

var part = ""
var price = [
	500,    # 1
	800,    # 2
	1200,   # 3
	1700,   # 4
	2300,   # 5
	3000,   # 6
	3800,   # 7
	4700,   # 8
	5600,   # 9
	6500,   # 10
	7500,   # 11
	8600,   # 12
	9800,   # 13
	11200,  # 14
	12800,  # 15
	14600,  # 16
	16500   # 17
]


func _ready() -> void:
	$CanonUP/CanonSelect.connect("pressed", _on_canon_select_pressed)
	$WingsUP/WingSelect.connect("pressed", _on_wing_select_pressed)
	$PropUP/PropSelect.connect("pressed", _on_prop_select_pressed)
	$BodyUP/BodySelect.connect("pressed", _on_body_select_pressed)
	# connessioni dei bottoni
	$Update.connect("pressed", _on_update_pressed)
	$Update.connect("mouse_entered", _on_Update_mouse_entered)
	$Update.connect("mouse_exited", _on_Update_mouse_exited)
	$CloseUpgrade.connect("pressed", _on_close_pressed)
	
func _process(delta: float) -> void:
	# Aggiorna oro
	$gold.text = str(GlobalStats.gold)

	# Mappa i livelli per ogni parte
	var level_map = {
		"canon": GlobalStats.canon_lvl,
		"wings": GlobalStats.wings_lvl,
		"prop": GlobalStats.prop_lvl,
		"body": GlobalStats.body_lvl
	}

	# Recupera il livello corrente della parte
	var lvl = level_map.get(part, 0)

	# Determina il frame in base al livello
	var frame := 3  # default
	if lvl < 4:
		frame = 0
	elif lvl < 8:
		frame = 1
	elif lvl < 12:
		frame = 2
	else:
		frame = 3

	$IconCont/icon.frame = frame

	
	
func manager():
	match part:
		"canon":
			$IconCont/icon.texture = load("res://Gres/Assets/Icons/parts/canon.png")
			$SkillsProgress.frame = GlobalStats.canon_lvl
			$price.text = str(price[GlobalStats.canon_lvl])
			$InfoTitle.text = "Cannon Lv." + str(GlobalStats.canon_lvl)
			$InfoDesc.text = "Damage +0.2%, Bullet Speed +20, Bullet Saving +2.5%"

			if GlobalStats.canon_lvl >= 8:
				GlobalStats.canon_lvl = 8
				$price.text = "-"
				$Update.disabled = true
			else:
				$Update.disabled= false

		"wings":
			$IconCont/icon.texture = load("res://Gres/Assets/Icons/parts/wings.png")
			$SkillsProgress.frame = GlobalStats.wings_lvl
			$price.text = str(price[GlobalStats.wings_lvl])
			$InfoTitle.text = "Wings Lv." + str(GlobalStats.wings_lvl + 1)
			$InfoDesc.text = "Dash +0.5, Moving Speed +5"

			if GlobalStats.wings_lvl >= 8:
				GlobalStats.wings_lvl = 8
				$price.text = "-"
				$Update.disabled = true
			else:
				$Update.disabled= false

		"prop":
			$IconCont/icon.texture = load("res://Gres/Assets/Icons/parts/propulsor.png")
			$SkillsProgress.frame = GlobalStats.prop_lvl
			$price.text = str(price[GlobalStats.prop_lvl])
			$InfoTitle.text = "Propulsors Lv." + str(GlobalStats.prop_lvl + 1)
			$InfoDesc.text = "Cooldown dash -0.1s, Dash Duration +0.2s"

			if GlobalStats.prop_lvl >= 8:
				GlobalStats.prop_lvl = 8
				$price.text = "-"
				$Update.disabled = true
			else:
				$Update.disabled= false

		"body":
			$IconCont/icon.texture = load("res://Gres/Assets/Icons/parts/body.png")
			$SkillsProgress.frame = GlobalStats.body_lvl
			$price.text = str(price[GlobalStats.body_lvl])
			$InfoTitle.text = "Body Ship Lv." + str(GlobalStats.body_lvl + 1)
			$InfoDesc.text = "HP max +5, Stamina max +5, Restore HP and Stamina"

			if GlobalStats.body_lvl >= 8:
				GlobalStats.body_lvl = 8
				$price.text = "-"
				$Update.disabled = true
			else:
				$Update.disabled= false

func _on_canon_select_pressed() -> void:
	part = "canon"
	manager()

func _on_wing_select_pressed() -> void:
	part = "wings"
	manager()

func _on_prop_select_pressed() -> void:
	part = "prop"
	manager()

func _on_body_select_pressed() -> void:
	part = "body"
	manager()

func _on_update_pressed() -> void:
	var current_lvl := 0
	var current_price := 0
	
	match part:
		"":
			$indicator/show.play("show")
			return
		"canon":
			current_lvl = GlobalStats.canon_lvl
		"wings":
			current_lvl = GlobalStats.wings_lvl
		"prop":
			current_lvl = GlobalStats.prop_lvl
		"body":
			current_lvl = GlobalStats.body_lvl
	
	# check se dentro il range
	if current_lvl >= price.size():
		return
	
	current_price = price[current_lvl]
	
	# oro sufficiente?
	if GlobalStats.gold < current_price:
		return
	
	# pagamento
	GlobalStats.gold -= current_price
	
	# upgrade
	match part:
		"":
			return
		"canon":
			GlobalStats.canon_lvl += 1
			Global.player_damage = Global.player_damage + 0.02
			Global.player_max_bullet_speed += 20
			Global.bullets_cons_percent = min(Global.bullets_cons_percent + 2.5, 80.0)

		"wings":
			GlobalStats.wings_lvl += 1
			Global.dash_speed += 0.5
			Global.move_speed += 5

		"prop":
			GlobalStats.prop_lvl += 1
			Global.dash_cooldown = max(0.1, Global.dash_cooldown - 0.1) # evita valori negativi
			Global.dash_duration += 0.2

		"body":
			GlobalStats.body_lvl += 1
			Global.player_max_hp += 5
			Global.player_max_stamina += 5
			Global.player_hp = Global.player_max_hp
			Global.player_stamina = Global.player_max_stamina
	
	$IconCont/update_anim.play("update")
	#===MONEY FX===#
	var money_fx = load("res://Gres/Scenes/Effects/money_fx.tscn")
	var mfx = money_fx.instantiate()
	get_parent().add_child(mfx)

	# Imposta la posizione iniziale in globale
	mfx.global_position = $gold/GoldIcon.global_position

	# Crea il tween
	var money_tw = create_tween()
	money_tw.tween_property(mfx, "global_position", $MoneyPos.global_position, 0.4)
	money_tw.tween_property(mfx, "modulate:a", 0.0, 1.0)

	# Alla fine libera il nodo
	money_tw.finished.connect(func():
		mfx.queue_free()
	)

	var effect_scene = load("res://Gres/Scenes/Effects/update.tscn")
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = $UpFX.position
	
	_button_update_tween()
	_price_update_tween()
	_update_level_indicator()
	manager()

func _button_update_tween():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Button "bounce" con piccolo ritardo
	tween.tween_property($Update, "scale", Vector2(1.4,1.4), 0.15).set_delay(0.05)
	tween.tween_property($Update, "scale", Vector2(1.0,1.0), 0.4)

	# Aggiungi un piccolo shake orizzontale (facoltativo)
	tween.parallel().tween_property($Update, "position:x", $Update.position.x + 6, 0.05)
	tween.tween_property($Update, "position:x", $Update.position.x - 6, 0.05)
	tween.tween_property($Update, "position:x", $Update.position.x, 0.05)

func _price_update_tween():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Price label "pop"
	tween.tween_property($price, "scale", Vector2(1.4, 1.4), 0.15) # veloce ingrandimento
	tween.tween_property($price, "scale", Vector2(1.0, 1.0), 0.4)  # rimbalzo morbido
	
	# Aggiungi anche un leggero flash di colore
	var orig_color = $price.modulate
	tween.tween_property($price, "modulate", Color(1.5,1.5,1.5), 0.1)
	tween.tween_property($price, "modulate", orig_color, 0.3)

func _update_level_indicator():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# scala temporaneamente per un pop leggero
	tween.tween_property($SkillsProgress, "scale", Vector2(3.2,3.2), 0.15)
	tween.tween_property($SkillsProgress, "scale", Vector2(3.0,3.0), 0.25)
	# flash colore per feedback
	var orig_color = $SkillsProgress.modulate
	tween.tween_property($SkillsProgress, "modulate", Color(1.5,1.5,1.5), 0.1)
	tween.tween_property($SkillsProgress, "modulate", orig_color, 0.3)

func _unlock_skill(part: String, level: int) -> void:
	# esempio: ogni 4 livelli sblocca una nuova abilità
	print("Skill sbloccata per", part, "al livello", level)

	# qui ci puoi mettere:
	# - popup di notifica
	# - aggiunta a lista skill sbloccate
	# - attivazione icona nell’albero skill

func _update_info_desc():
	if part == "":
		$InfoDesc.bbcode_text = "[center]Nessuna parte selezionata[/center]"
		return
	
	var text = "[center]"
	text += part.capitalize()
	text += "[/center]\n"

	match part:
		"canon":
			text += "• Damage: %s\n" % Global.player_damage
			text += "• Bullet Speed: %s\n" % Global.player_max_bullet_speed
			text += "• Bullet Savings: %s%%" % Global.bullets_cons_percent

		"wings":
			text += "• Dash Speed: %s\n" % Global.dash_speed
			text += "• Move Speed: %s" % Global.move_speed

		"prop":
			text += "• Dash Cooldown: %ss\n" % Global.dash_cooldown
			text += "• Dash Duration: %ss" % Global.dash_duration

		"body":
			text += "• HP Max: %s\n" % Global.player_max_hp
			text += "• Stamina Max: %s" % Global.player_max_stamina
	
	$InfoDesc.bbcode_text = text


func _on_Update_mouse_entered():
	if part == "":
		return
	
	var text = "[center]"
	text += part.capitalize()
	text += "[/center]\n"

	match part:
		"canon":
			var next_damage = Global.player_damage + 0.02
			var next_speed = Global.player_max_bullet_speed + 20
			var next_cons = min(Global.bullets_cons_percent + 2.5, 80.0)

			text += "• Damage: [color=green]%s[/color]\n" % next_damage
			text += "• Bullet Speed: [color=green]%s[/color]\n" % next_speed
			text += "• Bullet Savings: [color=green]%s%%[/color]" % next_cons

		"wings":
			var next_dash = Global.dash_speed + 0.5
			var next_move = Global.move_speed + 5

			text += "• Dash Speed: [color=green]%s[/color]\n" % next_dash
			text += "• Move Speed: [color=green]%s[/color]" % next_move

		"prop":
			var next_cd = max(0.1, Global.dash_cooldown - 0.1)
			var next_dur = Global.dash_duration + 0.2

			text += "• Dash Cooldown: [color=green]%ss[/color]\n" % next_cd
			text += "• Dash Duration: [color=green]%ss[/color]" % next_dur

		"body":
			var next_hp = Global.player_max_hp + 5
			var next_stm = Global.player_max_stamina + 5

			text += "• HP Max: [color=green]%s[/color]\n" % next_hp
			text += "• Stamina Max: [color=green]%s[/color]" % next_stm
	
	$InfoDesc.bbcode_text = text

func _on_Update_mouse_exited():
	if part == "":
		return
		
	_update_info_desc()

func _on_close_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))

func _on_close_upgrade_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))
