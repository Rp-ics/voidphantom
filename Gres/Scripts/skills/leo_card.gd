extends Node2D

var card_name = ""
var info_en = [
	"[color=#fc5a03]50% chance to resurrect with 50% HP[/color]\n\nYour essence refuses to fade. Reality bends, dragging you back from the void with brutal force.",
	
	"[color=#fc5a03]20% chance to drain 50% non-boss HP and heal 10%[/color]\n\nYou become a walking anomaly: enemies collapse as their life is ripped out and funneled straight into you.",
	
	"[color=#fc5a03]Gain 10 seconds of God power after respawn[/color]\n\nDeath only pisses you off. When you return, you’re untouchable—pure cosmic rage made flesh."
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
			GlobalStats.respawn = 50.0 # with 50%
		"card_2":
			GlobalStats.huge_dmg = 20.0
		"card_3":
			GlobalStats.respawn_god = true
			
			
	$Animation.play("confirm")
func on_close_confirm_pressed() -> void:
	hide_tw()
	
func _on_animation_animation_finished(anim_name: StringName) -> void:
	Global.can_activate = true
	queue_free()
