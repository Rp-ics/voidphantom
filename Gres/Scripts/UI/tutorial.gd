extends Node2D

var can_enemove := false
var tut_end := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tw = create_tween()
	tw.tween_property($Movement, 'modulate:a', 1, 2.5)
	move_tw()

func _process(delta: float) -> void:
	$DeadArea/up2.position.x = $Player.position.x
	$DeadArea/down2.position.x = $Player.position.x
	
	Global.bullets = 1
	Global.player_hp = Global.player_max_hp
	if not can_enemove:
		$Enemy.position = $initiall_pos.position
	if tut_end and Input.is_action_just_pressed("ui_accept"):
		Global.in_tutorial = false
		Global.spin_gem += 5
		GlobalInventory.clear()
		Global.equipped_weapon['name'] = "SOLBREAKER"
		Global.equipped_weapon['rarity'] = "common"
		GlobalSteamScript._unlock_achievement("Was Easy")
		await GlobalTweens.scene_pixel_dissolve(get_tree(),"res://Gres/Scenes/UI/main_menu.tscn", 100, 0.1)
		
func move_tw():
	GlobalTweens.blink($Movement/A, 5, 0.2)
	GlobalTweens.blink($Movement/D, 3, 0.1)
	GlobalTweens.blink($Movement/S, 5, 0.1)
	GlobalTweens.blink($Movement/W, 3, 0.2)
	GlobalTweens.activate($Rotation/Base2/rotact/CollisionShape2D)
	await get_tree().create_timer(1.5).timeout
	$Player.can_move = true
	
func rot_tw():
	GlobalTweens.blink($Rotation/RotL, 5, 0.2)
	GlobalTweens.blink($Rotation/Bord, 4, 0.3)
	GlobalTweens.activate($Dash/Base2/dash/CollisionShape2D)
	$Player.can_rotate = true

func dash_tw():
	GlobalTweens.blink($Dash/DashL, 5, 0.2)
	GlobalTweens.blink($Dash/Bord, 4, 0.3)
	GlobalTweens.activate($Shoot/Base2/shoot/CollisionShape2D)
	$Player.can_dash = true
	
func shoot_tw():
	GlobalTweens.blink($Shoot/ShootL, 5, 0.2)
	GlobalTweens.blink($Shoot/TutoriaL, 3, 0.1)
	GlobalTweens.blink($Shoot/Bord, 4, 0.3)
	GlobalTweens.activate($portal/portal/CollisionShape2D)
	$Player.can_shoot = true
	can_enemove = true

func _on_rotact_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		rot_tw()

func _on_dash_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		dash_tw()


func _on_shoot_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		shoot_tw()

func _on_end_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GlobalTweens.move_to($Player, Vector2(0, 0), 1.5)
		GlobalTweens.blink($Player, 6)
		await get_tree().create_timer(1.5).timeout
		move_tw()


func _on_portal_body_entered(body: Node2D) -> void:
	tut_end = true
	var tw = create_tween()
	tw.tween_property($portal/enter, 'modulate:a', 1.0, 0.5)
	
	# Aspetta la fine del tween prima di cambiare scena
	tw.tween_callback(func(): 
		get_tree().change_scene_to_file("res://Gres/Scenes/UI/main_menu.tscn")
	)

func _on_portal_body_exited(body: Node2D) -> void:
	tut_end = false
	var tw = create_tween()
	tw.tween_property($portal/enter, 'modulate:a', 0.0, 0.5)


func _on_enemy_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().reload_current_scene()


func _on_secure_body_exited(body: Node2D) -> void:
	$Enemy/walk.play("wakl")
