extends CharacterBody2D
class_name MinionBoss

@export var speed := 200.0
@export var max_hp := 20
@export var damage := 20
@export var fire_rate := 1.5
@export var bullet_scene: PackedScene
@export var target_group := "player"

@onready var fire_timer = $shoot_timer
@onready var move_timer = $move_timer
@onready var queue_timer = $queue_timer
@onready var sprite = $Sprite2D
@onready var fire_area = $FireArea

var hp := max_hp
var can_shoot := true
var can_move := true
var can_dmg := true
var target: Node2D
var direction := Vector2.ZERO

func _ready():
	speed = randi_range(200, 350)
	fire_timer.wait_time = fire_rate
	move_timer.timeout.connect(_on_move_timer_timeout)
	queue_timer.timeout.connect(_on_queue_timer_timeout)
	move_timer.start()
	
	# trova il player
	var players = get_tree().get_nodes_in_group(target_group)
	if players.size() > 0:
		target = players[0]
	
	rotation = randf() * TAU

func _physics_process(delta):
	if not target: return
	
	if can_move:
		direction = (target.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

	# rotazione visiva verso il player
	sprite.rotation = lerp_angle(sprite.rotation, direction.angle(), 5 * delta)

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		_die()

func _die():
	can_move = false
	can_shoot = false
	GlobalTweens.deactivate($CollisionShape2D)
	_spawn_damage_effects(3)
	GlobalTweens.explode_and_free(self)
	

func _spawn_damage_effects(amount:int):
	var effect_scene = load("res://Gres/Scenes/Effects/expl_boss.tscn")
	# Effetto visivo impatto
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)

	var dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var dist = randf_range(20.0, 50.0)
	effect.global_position = global_position + dir * dist
	effect.scale = Vector2.ONE * randf_range(0.5, 1.0)

func _on_move_timer_timeout():
	# Cambia leggermente la direzione o esegue micro-scatti casuali
	if not target: return
	if randi() % 100 < 40:
		var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		var dir = (target.global_position + offset - global_position).normalized()
		velocity = dir * speed


func _on_fire_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if can_dmg:
			can_dmg = false
			Global.player_hp -= damage
		GlobalTweens.explode_and_free(self)

func _on_fire_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		area.queue_free()
		hp -= 10
		_spawn_damage_effects(1)
		if hp <= 0:
			_die()

func _on_queue_timer_timeout() -> void:
	_spawn_damage_effects(2)
	_die()
