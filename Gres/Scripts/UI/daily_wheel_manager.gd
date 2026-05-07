extends Control

@onready var wheel = $Wheel
@onready var spin_button = $center/SpinButton
@onready var pointer = $Pointer
@onready var reward_popup = $RewardPopup
@onready var reward_label = $RewardPopup/RewardLabel
@onready var void_shard = $RewardPopup/container/Values/VoidShard
@onready var magma_shard = $RewardPopup/container/Values/MagmaShard
@onready var ice_shard = $RewardPopup/container/Values/IceShard
@onready var light_shard = $RewardPopup/container/Values/LightShard
@onready var tablet = $RewardPopup/container/Values/TabletL
@onready var gold = $RewardPopup/container/Values/gold
@onready var spin_gems = $RewardPopup/container/Values/SpinGems
@onready var free_spin = $RewardPopup/container/Values/FreeSpins

var spinning := false
var tick_step := 10.0      # ogni quanti gradi fare il tick
var next_tick_angle := 0.0 # il prossimo angolo al quale suonare
var ticking_enabled := false

@export var gem_cost := 1

func _ready():
	if GlobalDailyWheel.special_event:
		$Wheel/Segments.hide()
		$Wheel/Segments_boost.show()
	elif !GlobalDailyWheel.special_event:
		$Wheel/Segments.show()
		$Wheel/Segments_boost.hide()
		
	spin_button.pressed.connect(_on_spin_pressed)
	$BackToMenu.pressed.connect(_on_back_to_menu_pressed)
	void_shard.text = str(GlobalStats.void_shard)
	magma_shard.text = str(GlobalStats.magma_shard)
	ice_shard.text = str(GlobalStats.ice_shard)
	light_shard.text = str(GlobalStats.light_shard)
	tablet.text = str(GlobalStats.tablet)
	gold.text = str(GlobalStats.gold)
	spin_gems.text = str(Global.spin_gem)
	if GlobalStats.free_spin_used_today:
		free_spin.text = "[img=50]res://Gres/Assets/UI/Buttons/unckeck.png[/img] Free Spin"
	elif !GlobalStats.free_spin_used_today:
		free_spin.text = "[img=50]res://Gres/Assets/UI/Buttons/check_1.png[/img] Free Spin"

func _on_spin_pressed():
	if spinning:
		return

	# anti-cheat
	if not TimeManager.check_time_validity():
		reward_label.text = "Time cheat detected!"
		reward_popup.show()
		return
	
	GlobalStats.total_spin += 1
	# calcola premio usando Global.spin_gem
	var reward = GlobalDailyWheel.try_spin(gem_cost)
	if "error" in reward:
		match reward.error:
			"TIME_CHEAT":
				reward_label.text = "DAMN, DO NOT CHEAT BRO!"
			"ALREADY_SPUN":
				reward_label.text = "Ehy Ehy, one spin per day!"
			"NO_GEMS":
				reward_label.text = "You need Gems!\n1 Gem = 1 Spin"
				$Gems_show/showhide.play("show")
				GlobalTweens.shake($RewardPopup/container/Values/SpinGem, 5)
		reward_popup.show()
		return
	
	spin_gems.text = str(Global.spin_gem)
	if GlobalStats.free_spin_used_today:
		free_spin.text = "[img=50]res://Gres/Assets/UI/Buttons/unckeck.png[/img] Free Spin"
	elif !GlobalStats.free_spin_used_today:
		free_spin.text = "[img=50]res://Gres/Assets/UI/Buttons/check_1.png[/img] Free Spin"
	start_spin_animation(reward)

func start_spin_animation(reward: Dictionary):
	GlobalTweens.activate($center/IndexBody/CollisionShape2D)
	$BackToMenu.disabled = true
	$Wheel/w_1/shine.play("cc") # color change
	spinning = true
	GlobalStats.spins += 1 # Contatore di quanti spin abbiamo fatto
	var slots_count := GlobalDailyWheel.slots.size()
	var angle_per_slot := 360.0 / slots_count

	# Trova indice del premio
	var reward_index := GlobalDailyWheel.slots.find(reward)

	# Pulizia: ruota sempre da 0 per evitare merda di rotazioni accumulate
	wheel.rotation_degrees = 0

	# === FORZA 3 GIRI COMPLETI MINIMO ===
	var forced_rotations := 3 * 360.0   # 1080° sicuri

	# Se vuoi aggiungere un po' di random sopra i 3 giri
	var extra_rot := randi_range(0, 2) * 360.0  # opzionale
	var total_rot := forced_rotations + extra_rot

	# Offset per arrivare al premio esatto
	var target_angle := total_rot - (reward_index * angle_per_slot)

	# === TWEEN ===
	var tween := create_tween()
	tween.set_parallel(false)

	tween.tween_property(
		wheel,
		"rotation_degrees",
		target_angle,
		3.5  # puoi aumentare per più epicità
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		_on_spin_complete(reward)
	)
	

func _on_spin_complete(reward: Dictionary):
	$Exlossive.emitting = true
	$win_se.playing = true
	$BackToMenu.disabled = false
	spinning = false
	$Wheel/w_1/shine.stop()
	if reward.name == "Common Skin":
		$RewardPopup/InfoHolder/Icon.texture = load("res://Gres/Assets/player/body/body_12.png")
		$RewardPopup/InfoHolder/Icon/Icon1.texture = load("res://Gres/Assets/player/propuls/prop_12.png")
		$RewardPopup/InfoHolder/Icon/Icon2.texture = load("res://Gres/Assets/player/wings/wing_12.png")
	elif reward.name == "Rare Skin":
		$RewardPopup/InfoHolder/Icon.texture = load("res://Gres/Assets/player/body/body_14.png")
		$RewardPopup/InfoHolder/Icon/Icon1.texture = load("res://Gres/Assets/player/propuls/prop_14.png")
		$RewardPopup/InfoHolder/Icon/Icon2.texture = load("res://Gres/Assets/player/wings/wing_14.png")
	elif reward.name == "Epic Skin":
		$RewardPopup/InfoHolder/Icon.texture = load("res://Gres/Assets/player/body/body_13.png")
		$RewardPopup/InfoHolder/Icon/Icon1.texture = load("res://Gres/Assets/player/propuls/prop_13.png")
		$RewardPopup/InfoHolder/Icon/Icon2.texture = load("res://Gres/Assets/player/wings/wing_13.png")
	elif reward.name == "Gold":
		$RewardPopup/InfoHolder/Icon.texture = load("res://Gres/Assets/Icons/parts/gold_pack.png")
		$RewardPopup/InfoHolder/Icon/Icon1.texture = load("res://Gres/Assets/UI/Buttons/inv.png")
		$RewardPopup/InfoHolder/Icon/Icon2.texture = load("res://Gres/Assets/UI/Buttons/inv.png")
	elif reward.name == "Tablet":
		$RewardPopup/InfoHolder/Icon.texture = load("res://Gres/Assets/obj/tablet_2.png")
		$RewardPopup/InfoHolder/Icon/Icon1.texture = load("res://Gres/Assets/UI/Buttons/inv.png")
		$RewardPopup/InfoHolder/Icon/Icon2.texture = load("res://Gres/Assets/UI/Buttons/inv.png")
	elif reward.name == "Shards":
		$RewardPopup/InfoHolder/Icon.texture = load("res://Gres/Assets/Icons/parts/crystal_pack.png")
		$RewardPopup/InfoHolder/Icon/Icon1.texture = load("res://Gres/Assets/UI/Buttons/inv.png")
		$RewardPopup/InfoHolder/Icon/Icon2.texture = load("res://Gres/Assets/UI/Buttons/inv.png")
	elif reward.name == "HELLWING":
		$RewardPopup/InfoHolder/Icon.texture = load("res://Gres/Assets/player/weapons/common/rotated/gun_2R.png")
		$RewardPopup/InfoHolder/Icon/Icon1.texture = load("res://Gres/Assets/UI/Buttons/inv.png")
		$RewardPopup/InfoHolder/Icon/Icon2.texture = load("res://Gres/Assets/UI/Buttons/inv.png")
		
		
	reward_label.text = "You got: %s x%d" % [reward.name, reward.amount]
	reward_popup.show()

	# anima il premio specifico
	match reward.name:
		"SOLBREAKER":
			var old_val = gold.text.to_int()
			var new_val = GlobalStats.gold
			animate_counter(gold, old_val, new_val)

		"Shards":
			var old_ice   = ice_shard.text.to_int()
			var old_void  = void_shard.text.to_int()
			var old_magma = magma_shard.text.to_int()
			var old_light = light_shard.text.to_int()

			var new_ice   = GlobalStats.ice_shard
			var new_void  = GlobalStats.void_shard
			var new_magma = GlobalStats.magma_shard
			var new_light = GlobalStats.light_shard

			animate_counter(ice_shard, old_ice, new_ice)
			animate_counter(void_shard, old_void, new_void)
			animate_counter(magma_shard, old_magma, new_magma)
			animate_counter(light_shard, old_light, new_light)


		"Gold":
			var old_val = gold.text.to_int()
			var new_val = GlobalStats.gold
			animate_counter(gold, old_val, new_val)

		"Tablet":
			var old_val = tablet.text.to_int()
			var new_val = GlobalStats.tablet
			animate_counter(tablet, old_val, new_val)

func animate_counter(label: Label, start_value: int, end_value: int, duration: float = 0.6):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	var v := start_value

	tween.tween_method(
		func(value):
			label.text = str(int(value)),
		start_value,
		end_value,
		duration
	)

func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")


func _on_index_body_area_entered(area: Area2D) -> void:
	if not area.is_in_group("player"):
		return

	call_deferred("_safe_play_spin_sound")

func _safe_play_spin_sound():
	var audio = $spin_se
	if audio and is_instance_valid(audio):
		audio.play() # molto meglio di .playing = true
