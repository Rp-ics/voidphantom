extends Control

@onready var stats_label: RichTextLabel = $StatsInfo

func _ready() -> void:
	$StatsBack.connect('pressed', _on_statsback_pressed)
	update_stats()

func _process(delta: float) -> void:
	update_stats()

## Formats an integer with dots as thousands separator: 12345 -> "12.345"
func epic_format(value: int) -> String:
	var s := str(value)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "." + result
	return result

func update_stats() -> void:
	var GS = GlobalStats
	var text := ""

	# EPIC HEADER
	text += "[center][color=#FFD700][wave amp=30 freq=2]⚔️  LEGENDARY CHRONICLE  ⚔️[/wave][/color][/center]\n"
	text += "[center][color=#B0B0B0]The saga of a true warrior, written in blood and glory[/color][/center]\n\n"

	# ========================
	# THE HERO
	# ========================
	text += "[color=#FFA500]─── ❖ THE HERO ❖ ───[/color]\n"
	text += "[color=white]Total Gold Amassed:[/color] [color=#FFD700]%s[/color]\n" % epic_format(GS.total_gold_collected)
	text += "[color=white]Skills Unleashed:[/color] [color=lime]%d[/color]\n" % GlobalStats.stars
	text += "[color=white]Skins Forged:[/color] [color=lime]%d[/color]\n" % GS.skins_unlocked
	text += "[color=white]Times Fallen:[/color] [color=red]%d[/color]\n" % GS.died_times
	text += "[color=white]Highest Wave Reached:[/color] [color=red]%d[/color]\n\n" % GS.max_game_wave

	# ========================
	# CARNAGE DEALT
	# ========================
	text += "[color=#FFA500]─── ⚡ CARNAGE DEALT ⚡ ───[/color]\n"
	text += "[color=white]Total Damage Received:[/color] [color=red]%s[/color]\n" % epic_format(GS.player_damage_total)
	text += "[color=white]Total Damage Inflicted:[/color] [color=lime]%s[/color]\n\n" % epic_format(GS.damage_inf_total)

	# ========================
	# SLAYER'S TALLY
	# ========================
	text += "[color=#FFA500]─── 💀 SLAYER'S TALLY 💀 ───[/color]\n"
	text += "[color=white]Mobs Annihilated:[/color] [color=lime]%s[/color]\n" % epic_format(GS.kill_mobs_total)
	text += "[color=white]Bosses Vanquished:[/color] [color=lime]%s[/color]\n\n" % epic_format(GS.kill_boss_total)

	# ========================
	# DESTRUCTION BREAKDOWN
	# ========================
	text += "[color=#FFA500]─── 🔥 DESTRUCTION BREAKDOWN 🔥 ───[/color]\n"
	text += "[color=white]Damage to Minions:[/color] [color=lime]%s[/color]\n" % epic_format(GS.damage_inf_mob_total)
	text += "[color=white]Damage to MiniBosses:[/color] [color=lime]%s[/color]\n" % epic_format(GS.damage_inf_miniboss_total)
	text += "[color=white]Damage to Bosses:[/color] [color=lime]%s[/color]\n" % epic_format(GS.damage_inf_boss_total)
	text += "[color=white]Total Mayhem:[/color] [color=lime]%s[/color]\n\n" % epic_format(GS.damage_inf_total)

	# ========================
	# SUFFERING ENDURED
	# ========================
	text += "[color=#FFA500]─── 🛡️ SUFFERING ENDURED 🛡️ ───[/color]\n"
	text += "[color=white]Total Punishment:[/color] [color=red]%s[/color]\n\n" % epic_format(GS.damage_rec_total)

	# ========================
	# NUCLEAR FURY
	# ========================
	text += "[color=#FFA500]─── ☢️ NUCLEAR FURY ☢️ ───[/color]\n"
	text += "[color=white]Disintegrated by Nuke:[/color] [color=lime]%s[/color]\n\n" % epic_format(GS.nuclear_kill_total)

	# ========================
	# ARSENAL & FORTUNE
	# ========================
	text += "[color=#FFA500]─── 🎯 ARSENAL & FORTUNE 🎯 ───[/color]\n"
	text += "[color=white]Bullets Unleashed:[/color] [color=lime]%s[/color]\n" % epic_format(GS.bullets_shoot_total)
	text += "[color=white]Bonuses Collected:[/color] [color=lime]%s[/color]\n\n" % epic_format(GS.bonus_get_total)

	# ========================
	# REALM STATUS
	# ========================
	text += "[color=#FFA500]─── 📜 REALM STATUS 📜 ───[/color]\n"
	text += "[color=white]Boss Fights Triggered:[/color] [color=lime]%d[/color]\n\n" % GS.boss_fight_counter

	# ========================
	# IMMORTAL CLOCK
	# ========================
	text += "[color=#FFA500]─── ⏳ IMMORTAL CLOCK ⏳ ───[/color]\n"
	text += "[color=white]Time Spent in the Fray:[/color] [color=cyan]%02d:%02d:%02d[/color]\n" % [GS.play_hours, GS.play_minutes, GS.play_seconds]

	stats_label.text = text

func _on_statsback_pressed() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0, 0.3)
	tw.tween_callback(Callable(self, "hide"))
