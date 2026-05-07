extends Node2D

func _ready():
	var area = $ShieldReflect
	if area:
		area.body_entered.connect(_on_shield_reflect_area_entered)

func _on_shield_reflect_area_entered(area: Area2D) -> void:
	if Global and Global.player:
		Global.player._on_aegis_deflect(area)
