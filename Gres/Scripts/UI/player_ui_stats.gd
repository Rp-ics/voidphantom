extends Node2D

func _ready() -> void:
	$PFPBG/player_name.text = str(GlobalSteamScript.player_name)
	# Nella ready() o dove imposti il testo
	$PFPBG/player_name.clip_text = true
	$PFPBG/player_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	$PFPBG/player_name.text = str(GlobalSteamScript.player_name)
	var img = "res://Gres/Assets/Icons/pfp/pfp_%s.png" % Global.texture_pfp_icon
	$PFPBG/PFPIcon.texture = load(img)

func _process(delta: float) -> void:
	$BulletsBar.max_value = Global.max_bullets
	$BulletsBar.value = Global.bullets
	$gold.text = str(GlobalStats.gold)
	$HPBar.max_value = Global.player_max_hp
	$HPBar.value = Global.player_hp
	$HPBar/HPCounter.text = str(Global.player_hp)
	$STMBar.max_value = Global.player_max_stamina
	$STMBar.value = Global.player_stamina
	$STMBar/STCounter.text = str(Global.player_stamina)
	$"../Manager/VoidShard".text = str(GlobalStats.void_shard)
	$"../Manager/MagmaShard".text = str(GlobalStats.magma_shard)
	$"../Manager/IceShard".text = str(GlobalStats.ice_shard)
	$"../Manager/LightShard".text = str(GlobalStats.light_shard)
	$"../Manager/Tablet".text = str(GlobalStats.tablet)
	
func _on_pause_b_mouse_entered() -> void:
	var tw = create_tween()
	tw.tween_property($PauseB, "modulate:a", 1.0, 0.2)

func _on_pause_b_mouse_exited() -> void:
	var tw = create_tween()
	tw.tween_property($PauseB, "modulate:a", 0.2, 0.2)
