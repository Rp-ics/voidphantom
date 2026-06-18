extends Control

var gold = "res://Gres/Assets/Icons/parts/gold_icon_1.png"
var void_coin = "res://Gres/Assets/Icons/black_hole_bonus.png"
var spin = "res://Gres/Assets/Icons/exotic_icon.png"

func _ready() -> void:
	match Global.boss_mame:
		"wrath":
			$info_rewards.text = str("[img]",gold,"[/img]\n")
			
