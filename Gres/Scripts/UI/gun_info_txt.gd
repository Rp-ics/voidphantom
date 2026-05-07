extends Node2D

@onready var gun_info_label: RichTextLabel = $GunInfo

func _process(_delta: float) -> void:
	gun_info_label.text = GlobalWeapons.gun_info
