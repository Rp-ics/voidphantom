extends Node2D

var card_name = ""
var info_en = [
	"[color=#fc5a03]+34% Critical Chance[/color]\n\nYour aim sharpens beyond reason: permanently gain +34% Crit Chance, fully stacking with all other sources.",
	
	"[color=#fc5a03]+3.0x Critical Damage[/color]\n\nWhen you strike, you strike like a beast: permanently adds +3.0x Crit Damage, stacking with everything else.",
	
	"[color=#fc5a03]40% chance: Crits heal +3 HP[/color]\n\nYour violence becomes survival-each critical hit has a 40% chance to restore 3 HP."
]

func _ready() -> void:
	GlobalTweens.fade($Card, 0.0, 1.0, 2.0)
	self.modulate = Color(1,1,1,0)
	var tw = create_tween()
	tw.tween_property(self, 'modulate:a', 1.0, 1.5)
	GlobalTweens.glitch_flash($Card1, 6, 0.4)
	GlobalTweens.glitch_flash($Card2, 4, 0.2)
	GlobalTweens.glitch_flash($Card3, 5, 0.4)
	$Card1/Info.text = info_en[0]
	$Card2/Info.text = info_en[1]
	$Card3/Info.text = info_en[2]
	$Card1/Card1.connect("pressed", on_card1_pressed)
	$Card2/Card2.connect("pressed", on_card2_pressed)
	$Card3/Card2.connect("pressed", on_card3_pressed)
	$confirm/confirm.connect("pressed", on_confirm_pressed)
	$confirm/CloseConfirm.connect("pressed", on_close_confirm_pressed)

func show_tw():
	var tw = create_tween()
	$confirm.modulate = Color(1,1,1,0.0)
	$confirm.show()
	tw.tween_property($confirm, 'modulate:a', 1.0, 0.5)
	
func hide_tw():
	var tw = create_tween()
	tw.tween_property($confirm, 'modulate:a', 0.0, 0.5)
	await get_tree().create_timer(0.8).timeout
	$confirm.hide()
	
func on_card1_pressed() -> void:
	card_name = "card_1"
	$confirm/Card.texture = $Card1.texture
	$confirm/Card/Info.text = info_en[0]
	show_tw()
func on_card2_pressed() -> void:
	card_name = "card_2"
	$confirm/Card.texture = $Card2.texture
	$confirm/Card/Info.text = info_en[1]
	show_tw()
func on_card3_pressed() -> void:
	card_name = "card_3"
	$confirm/Card.texture = $Card3.texture
	$confirm/Card/Info.text = info_en[2]
	show_tw()

func on_confirm_pressed() -> void:
	$confirm/confirm.disabled = true
	$confirm/CloseConfirm.disabled = true
	match  card_name:
		"card_1":
			GlobalStats.critical += 34
			GlobalSkills.zodiac_cards['aries']['card_1'] = true
		"card_2":
			GlobalStats.critical_damage += 3.0
			GlobalSkills.zodiac_cards['aries']['card_2'] = true
		"card_3":
			GlobalStats.critical_vampire = true
			GlobalSkills.zodiac_cards['aries']['card_3'] = true
	$Animation.play("confirm")
func on_close_confirm_pressed() -> void:
	hide_tw()
	
func _on_animation_animation_finished(anim_name: StringName) -> void:
	Global.can_activate = true
	queue_free()
