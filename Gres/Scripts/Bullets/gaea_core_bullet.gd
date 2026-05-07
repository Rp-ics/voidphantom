extends Area2D
class_name GaeaCoreBullet

@export var speed: float = 600.0
@export var lifetime: float = 1.3
@export var damage: float = GlobalWeapons.current_weapon["damage"]
@export var fragment_scene: PackedScene = preload("res://Gres/Scenes/Bullets/gaea_fragment.tscn")

var direction: Vector2 = Vector2.RIGHT
var owner_ref: Node2D

func init_from_weapon(weapon_data: Dictionary, dir: Vector2, owner: Node2D) -> void:
	direction = dir.normalized()
	owner_ref = owner
	damage = weapon_data.get("damage", damage)
	speed = weapon_data.get("speed", speed)

func _ready():
	GlobalStats.bullets_shoot_lvl += 1
	GlobalStats.bullets_shoot_total += 1
	if GlobalStats.bullets_shoot_total >= 1000000:
		GlobalStats.achievements["Mirage of Million Shots"] = true
	add_to_group("p_bullet")
	await get_tree().create_timer(lifetime).timeout
	_explode()

func _process(delta: float) -> void:
	position += direction * speed * delta
	rotation = direction.angle()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy"):
		if area.has_method("take_damage"):
			area.take_damage(damage * Global.player_damage)
		call_deferred("_explode")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		if randi() % 100 < GlobalStats.critical: 
			body.take_damage(damage * GlobalStats.critical_damage)
			if Global.enemy_type == "enemy":
				GlobalStats.damage_inf_mob_lvl += (damage * GlobalStats.critical_damage)
				GlobalStats.damage_inf_mob_total += (damage * GlobalStats.critical_damage)
			if Global.enemy_type == "mini_boss":
				GlobalStats.damage_inf_miniboss_lvl += (damage * GlobalStats.critical_damage)
				GlobalStats.damage_inf_miniboss_total += (damage * GlobalStats.critical_damage)
			GlobalStats.damage_inf_total_lvl += (damage * GlobalStats.critical_damage)
			GlobalStats.damage_inf_total += (damage * GlobalStats.critical_damage)
			
			if randi() % 100 < 40 and GlobalStats.critical_vampire: Global.player_hp += 3
		else: 
			body.take_damage(damage)
			if Global.enemy_type == "enemy":
				GlobalStats.damage_inf_mob_lvl += damage
				GlobalStats.damage_inf_mob_total += damage
			if Global.enemy_type == "mini_boss":
				GlobalStats.damage_inf_miniboss_lvl += damage
				GlobalStats.damage_inf_miniboss_total += damage
			GlobalStats.damage_inf_total_lvl += damage
			GlobalStats.damage_inf_total += damage
			
		
		call_deferred("_explode")
		
	if body.is_in_group("e_base") and body.has_method("damage"):
		body.damage()
		queue_free()


func _explode() -> void:
	GlobalTweens.activate($Explode)
	if not is_inside_tree():
		return

	# Genera frammenti orbitanti attorno al player
	if is_instance_valid(owner_ref):
		for i in range(6):
			var frag = fragment_scene.instantiate()
			owner_ref.add_child(frag)
			var angle = (TAU / 6) * i
			var offset = Vector2(cos(angle), sin(angle)) * 80.0
			frag.global_position = owner_ref.global_position + offset
			frag.init_fragment(owner_ref, angle, 80.0, 1.5, damage * 0.4)

	# dissolvenza del core
	if has_node("Sprite2D"):
		var tween = get_tree().create_tween()
		tween.tween_property($Sprite2D, "scale", Vector2(2, 2), 0.15)
		tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.15)
		await tween.finished

	call_deferred("queue_free")
