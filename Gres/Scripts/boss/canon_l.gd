extends Node2D

# ======================================================
# PARAMETRI DI CONFIGURAZIONE
# ======================================================
@export var hp: int = 6666
@export var charge_time: float = 1.2
@export var beam_scene: PackedScene
@export var missile_scene: PackedScene
@export var bullet_path: String = "res://Gres/Scenes/enemies/bullets/enemy_bullet_1.tscn"

@export var rotate_limit_deg: float = 18.0
@export var turn_speed: float = 3.0
@export var shielded: bool = false
@export var fire_mode: String = "bullet" # beam, missile, bullet, rapid
@export var fire_delay: float = 1.4      # tempo tra colpi
@export var cooldown_delay: float = 3.0  # pausa dopo una raffica
@export var mitra_percent: int = 5       # % di probabilità di modalità mitra
@export var rapid_count: int = 6
@export var damage: int = 10
# ======================================================
# VARIABILI RUNTIME
# ======================================================
var player: Node = null
var is_dead: bool = false
var cooldown: bool = false
var bullet_scene: PackedScene
var can_phase_2: bool = true
var can_phase_3: bool = true
var can_hurt: bool = true

@onready var timer_fire: Timer = $TimerFire
@onready var timer_cooldown: Timer = $TimerCooldown

# ======================================================
# READY
# ======================================================
func _ready() -> void:
	match Global.dificulty:
		"easy":
			hp = 1500
			damage = 10
			rapid_count = 6
			mitra_percent = 10
			fire_delay = 1.4
		"normal":
			hp = 3500
			damage = 20
			rapid_count = 12
			mitra_percent = 20
			fire_delay = 1.2
		"hard":
			hp = 6666
			damage = 30
			rapid_count = 25
			mitra_percent = 20
			fire_delay = 0.8
			
	$Shield.hide()
	bullet_scene = load(bullet_path)
	
	if bullet_scene == null:
		push_error("❌ ERRORE FATALE: impossibile caricare il proiettile da " + bullet_path)
	else:
		pass#print("✅ Proiettile caricato correttamente:", bullet_scene)
	
	timer_fire.wait_time = fire_delay
	timer_cooldown.wait_time = cooldown_delay
	timer_fire.timeout.connect(_on_TimerFire_timeout)
	timer_cooldown.timeout.connect(_on_TimerCooldown_timeout)
	timer_fire.start()

# ======================================================
# CICLO DI FUOCO
# ======================================================
func _on_TimerFire_timeout() -> void:
	if is_dead or cooldown:
		timer_fire.stop()
		return
	
	if randi() % 100 < mitra_percent:
		fire_mode = "rapid"
	
	match fire_mode:
		"beam":
			charge_and_fire("beam")
			timer_fire.stop()
			timer_cooldown.start()
		"missile":
			charge_and_fire("missile")
			timer_fire.stop()
			timer_cooldown.start()
		"bullet":
			_fire_bullet()
		"rapid":
			rapid_fire(rapid_count)
			timer_fire.stop()
			timer_cooldown.start()

func _on_TimerCooldown_timeout() -> void:
	if is_dead: return
	cooldown = false
	timer_fire.start()

# ======================================================
# METODI DI FUOCO
# ======================================================
func charge_and_fire(mode: String = "beam") -> void:
	if is_dead or cooldown: return
	cooldown = true
	_play_charge_effect()
	await get_tree().create_timer(charge_time).timeout
	
	match mode:
		"beam":
			_fire_beam()
		"missile":
			_fire_missile()
	
	cooldown = false

func rapid_fire(count: int = 4) -> void:
	if is_dead or cooldown: return
	cooldown = true
	for i in range(count):
		_fire_bullet()
		await get_tree().create_timer(0.12).timeout
	cooldown = false
	fire_mode = "bullet"

func _fire_beam() -> void:
	if beam_scene == null: 
		push_warning("⚠️ beam_scene non impostata.")
		return
	
	var beam = beam_scene.instantiate()
	get_parent().add_child(beam)
	beam.global_position = $Muzzle.global_position + transform.x * 20
	
	if beam.has_method("init") and player:
		beam.init(player.global_position)
	
	_play_shot_sound("beam_shot")
	#print("💥 BEAM sparato!")

func _fire_missile() -> void:
	if missile_scene == null:
		push_warning("⚠️ missile_scene non impostata.")
		return
	
	var m = missile_scene.instantiate()
	get_parent().add_child(m)
	m.global_position = $Muzzle.global_position + Vector2(0, -10)
	
	if m.has_method("set_target") and player:
		m.set_target(player)
	
	_play_shot_sound("missile_launch")
	#print("🚀 MISSILE sparato!")

func _fire_bullet() -> void:
	if bullet_scene == null:
		push_error("❌ bullet_scene non caricato!")
		return
	
	_spawn_from_point($Muzzle.global_position, bullet_scene)
	if has_node("Muzzle2"):
		_spawn_from_point($Muzzle2.global_position, bullet_scene)

func _spawn_from_point(spawn_pos: Vector2, scene: PackedScene) -> void:
	if scene == null:
		push_error("❌ ERRORE: scena proiettile nulla.")
		return
	
	var bullet = scene.instantiate()
	if bullet == null:
		push_error("❌ Errore nell'istanza del proiettile!")
		return
	
	get_tree().current_scene.add_child(bullet)
	
	# Posizione con leggero spread
	var spread := 6.0
	var offset := Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
	bullet.global_position = spawn_pos + offset
	
	# Direzione
	var dir: Vector2
	if has_node("dir"):
		dir = ($dir.global_position - spawn_pos).normalized()
	else:
		dir = Vector2(0, -1).rotated(global_rotation)
	
	var angle_offset := deg_to_rad(randf_range(-25, 25))
	dir = dir.rotated(angle_offset)
	
	bullet.rotation = dir.angle()
	
	if bullet.has_method("set_direction"):
		bullet.set_direction(dir)
	
	#print("💥 Proiettile istanziato a:", bullet.global_position)

# ======================================================
# EFFETTI E DANNI
# ======================================================
func _play_charge_effect(): pass
func _play_shot_sound(name:String): pass

func take_damage(amount:int) -> void:
	if shielded or is_dead: return
	hp -= amount
	$HPLabel.text = str(hp)
	$HPLabel2.text = str(hp)
	
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	shielded = true
	Global.mother_left_canon_damaged = true
	match Global.state:
		"PHASE1":
			$Sprite2D.texture = load("res://Gres/Assets/Enemy/Boss/Red_Eye_die_2.png")
		"PHASE2":
			$Sprite2D.texture = load("res://Gres/Assets/Enemy/Boss/Red_Eye_die_2_2.png")
		"PHASE3":
			$Sprite2D.texture = load("res://Gres/Assets/Enemy/Boss/Red_Eye_phase_4_2.png")
	timer_fire.stop()
	timer_cooldown.stop()
	_play_shot_sound("cannon_explode")
	if has_method("shutdown"):
		shutdown()

func shutdown() -> void:
	cooldown = true


func _on_phase_checker_timeout() -> void:
	match Global.state:
		"PHASE1":
			fire_delay = 1.4
			if hp < 4000 and not shielded:
				Global.mother_left_canon_damaged = true
				shielded = true; $Shield.show()
			elif hp > 4000: 
				Global.mother_left_canon_damaged = false
				shielded = false; $Shield.hide()
		"PHASE2":
			if hp < 2000 and not shielded:
				Global.mother_left_canon_damaged = true
				shielded = true; $Shield.show()
			elif hp > 2000: 
				Global.mother_left_canon_damaged = false
				shielded = false; $Shield.hide()
			mitra_percent = 10
			rapid_count = 10
			damage = 6
			fire_delay = 1.0
			if can_phase_2 and not is_dead:
				can_phase_2 = false
				$phaser.play("phase_2")
		"PHASE3":
			shielded = false
			$Shield.hide()
			mitra_percent = 15
			rapid_count = 16
			damage = 4
			fire_delay = 0.6
			if can_phase_3 and not is_dead:
				can_phase_3 = false
				$phaser.play("phase_3")
	$PhaseChecker.start()


func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		area.queue_free()
		if not shielded:
			take_damage(int(Global.player_damage * damage))
			if can_hurt:
				can_hurt = false
				$hurt.play("hurt")

		

func _on_hurt_animation_finished(anim_name: StringName) -> void:
	can_hurt = true
