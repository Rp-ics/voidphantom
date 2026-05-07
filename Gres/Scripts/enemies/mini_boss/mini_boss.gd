extends CharacterBody2D
class_name MiniBoss

signal enemy_died

@onready var player = null
@onready var fire_area = $FireArea
@onready var dodge_area = $DodgeArea
@onready var canon = $Canon 
@onready var fire_timer = $FireTimer

@export var targhet_look: PackedScene
@export var speed: float = 100.0
@export var originalspeed: float = 100.0
@export var dodge_distance: float = 300.0
@export var dodge_duration: float = 0.25
@export var shoot_bullet_paths: Array[String] = [
	"res://Gres/Scenes/enemies/bullets/enemy_bullet_1.tscn"
]

var hp := 1
var max_hp := 1
var fire_rate := 1.2
var dodge_chance := 10
var is_shielded: bool = false
var shield_timer: Timer

var can_mitra := true

var can_random_bull := true
var bullet_texture: Texture2D = null
var group = "player"

var current_skill = [
	"dash_attack",
	"orbital",
	"shield",
	"mitra",
	"magnet_pull",
	#"phase_clone",
]

const SKILL_PATHS = {
	"dash_attack": "res://Gres/Scripts/EnemySkills/DashAttack.gd",
	"orbital": "res://Gres/Scripts/EnemySkills/Orbital.gd",
	"shield": "res://Gres/Scripts/EnemySkills/Shield.gd",
	"mitra": "res://Gres/Scripts/EnemySkills/Mitra.gd",
	"magnet_pull": "res://Gres/Scripts/EnemySkills/MagnetPull.gd",
	#"phase_clone": "res://Gres/Scripts/EnemySkills/PhaseClone.gd"
}

var skills_timer := 10
var skill_anim_offset := 5.0

var can_move := true
var can_shoot := true
var on_shoot_area := false
var can_follow := true
var can_dodge := true
var can_rotate := true

var dodge_vector := Vector2.ZERO
var is_dodging := false
var is_using_skill := false
var can_emit := true

@onready var body_sprite = $BodySprite
@onready var wings_sprite = $WingsSprite
@onready var prop_sprite = $PropSprite

# numeri massimi disponibili #
const MAX_BODY = 4
const MAX_WINGS = 4
const MAX_PROP = 7
const MAX_CANON = 10

# palette colori #
const COLORS = [
	Color(1,0,0),   # rosso
	Color(0,0,1),   # blu
	Color(0,1,0),   # verde
	Color(1,1,0),   # giallo
	Color(1,0.5,0), # arancione
	Color(1,1,1),   # bianco
	Color(0.5,0,1)  # viola
	]

func _ready():
	randomize()

	#--bullets--#
	var textures = [
		load("res://Gres/Assets/UI/Bullets/Bullet_1.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_2.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_3.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_5.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_6.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_7.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_8.png")]

	bullet_texture = textures.pick_random()

	#-skills#
	current_skill = current_skill.pick_random()
	skills_timer = randi_range(10, 15)
	
	$SkillAnimTimer.wait_time = skills_timer - 5
	$SkillAnimTimer.start()
	$SkillAnimTimer.wait_time = max(skills_timer - skill_anim_offset, 0.1)
	$SkillTimer.wait_time = skills_timer
	$SkillTimer.start()
	can_dodge = true
	can_follow = true
	can_move = true
	can_shoot = true
	can_rotate = true
	
	_apply_random_skin()
	
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		queue_free()
	
	# Scala con la wave
	var wave = Global.wave
	hp = clamp(1 + wave * 10, 5, 400)
	fire_rate = clamp(1.2 - wave * 0.05, 0.2, 1.2)
	dodge_chance = clamp(10 + wave * 5, 10, 70)
	fire_timer.wait_time = fire_rate
	fire_timer.start()

func _apply_random_skin() -> void:
	# body
	var body_t = randi_range(1, MAX_BODY)
	var body_path = "res://Gres/Assets/Enemy/part/MiniBoss/body/e_body_%s.png" % body_t
	body_sprite.texture = load(body_path)
	
	# wings
	var wings_t = randi_range(1, MAX_WINGS)
	var wings_path = "res://Gres/Assets/Enemy/part/MiniBoss/wings/e_wings_%s.png" % wings_t
	wings_sprite.texture = load(wings_path)

	# propulsor
	var prop_t = randi_range(1, MAX_PROP)
	var prop_path = "res://Gres/Assets/Enemy/part/MiniBoss/prop/w_pro_%s.png" % prop_t
	prop_sprite.texture = load(prop_path)

	# colore random
	var c = COLORS.pick_random()
	body_sprite.modulate = c
	wings_sprite.modulate = c
	prop_sprite.modulate = c

func _physics_process(delta):
	if player == null:
		return
	
	# ROTAZIONE
	if can_rotate:
		look_at(player.global_position)
	
	# TIME SLOW
	if GlobalStats.time_slow:
		match GlobalStats.time_slow_bonus:
			1: speed = 70
			2: speed = 50
			3: speed = 20
	else:
		speed = originalspeed
	
	# DEAD
	if Global.player_dead:
		can_dodge = false
		can_follow = false
		can_move = false
		can_shoot = false
		can_rotate = false
		queue_free()
		return
	
	# FIRE TIMER
	if on_shoot_area and fire_timer.is_stopped():
		fire_timer.start()
	
	# SE IN SKILL (tipo dash), lascio velocity così com’è
	if is_using_skill:
		move_and_slide()
		return
	
	# DODGE
	if is_dodging:
		velocity = dodge_vector
	elif can_follow:
		# Movimento verso player
		velocity = (player.global_position - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO
	
	# APPLICO VELOCITÀ
	move_and_slide()

func _on_FireTimer_timeout():
	if not on_shoot_area:
		return
	
	var bullet_scene = load("res://Gres/Scenes/enemies/bullets/enemy_bullet_1.tscn")
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	
	bullet.global_position = canon.global_position
	bullet.rotation = canon.global_rotation
	bullet.set_direction((player.global_position - canon.global_position).normalized())

	# PASSO la texture scelta dal nemico
	bullet.set_texture(bullet_texture)

	fire_timer.start()

func use_skill(skill_name: String):
	if not SKILL_PATHS.has(skill_name):
		push_warning("Skill non trovata: %s" % skill_name)
		return
	
	var skill_script = load(SKILL_PATHS[skill_name])
	var skill = skill_script.new(self)
	add_child(skill)
	skill.activate()

func take_damage(amount: float) -> void:
	# Se il nemico ha lo scudo attivo → niente danni
	if is_shielded:
		return

	# Effetto d’impatto normale
	var effect_scene = load("res://Gres/Scenes/Effects/expl_p.tscn")
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
	
	# Applica danno
	hp -= amount
	flash_damage()  
	spawn_damage_popup(amount)
	
	if hp <= 0:
		die()


func flash_damage() -> void:
	var tween = create_tween()
	# Cambia colore a rosso
	tween.tween_property(self, "modulate", Color(1, 0, 0), 0.1)
	# Torna al colore originale (bianco)
	tween.tween_property(self, "modulate", Color(1, 1, 1), 0.1).set_delay(0.1)

func spawn_damage_popup(amount: int) -> void:
	var dmg_label_scene = preload("res://Gres/Scenes/UI/damage_label.tscn")
	var dmg_label = dmg_label_scene.instantiate()
	get_tree().current_scene.add_child(dmg_label) 
	# lo aggiungo alla scena principale, non al nemico (così non viene deletato insieme)
	dmg_label.show_damage(amount, global_position)

func die() -> void:
	if randi() % 100 < GlobalStats.drop_percent:
		var effect_scene = load("res://Gres/Scenes/Bonus/bonus_drop.tscn")
		var effect = effect_scene.instantiate()
		get_parent().call_deferred("add_child", effect)
		effect.global_position = global_position
	
	if can_emit:
		can_emit = false
		emit_signal("enemy_died")
	can_dodge = false
	can_follow = false
	can_move = false
	can_rotate = false
	can_shoot = false
	$dead.play("dead")

func _on_DodgeArea_body_entered(body):
	if not can_dodge or is_dodging:
		return
	if not body.is_in_group("p_bullet"):
		return
	if randi() % 100 < dodge_chance:
		start_dodge()

func start_dodge():
	is_dodging = true
	dodge_vector = get_random_dodge_direction() * (speed + 100)
	await get_tree().create_timer(dodge_duration).timeout
	is_dodging = false

func get_random_dodge_direction() -> Vector2:
	var dirs = [
		Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
		Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)
	]
	return dirs[randi() % dirs.size()].normalized()


func _on_stop_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(group):
		can_move = false


func _on_stop_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(group):
		can_move = true


func _on_fire_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(group):
		can_shoot = true
		on_shoot_area = true


func _on_fire_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(group):
		can_shoot = false
		on_shoot_area = false


func _on_dodge_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet"):
		if randi() % 100 < 95:
			start_dodge()
		
#============================#
# DEAD #
#============================#
func die_enemy_explosion():
	can_move = false
	can_shoot = false
	
	var parts = [$BodySprite, $WingsSprite, $PropSprite]
	var tween = create_tween()
	
	for part in parts:
		var angle = randf_range(-PI, PI)
		var dist = randf_range(20, 80)
		var dir = Vector2(cos(angle), sin(angle))
		
		tween.tween_property(part, "rotation", angle, 0.5)
		tween.tween_property(part, "position", part.position + dir * dist, 0.5)
		tween.tween_property(part, "scale", Vector2.ZERO, 0.5)

	tween.tween_callback(queue_free)


func _on_dead_animation_finished(anim_name: StringName) -> void:
	queue_free()

func _magnet_end():
	$PullFX.hide()
	$PullFX/loop.stop()

func _on_skill_timer_timeout() -> void:
	use_skill(current_skill)
	if current_skill == "magnet_pull":
		$PullFX.show()
		$PullFX/loop.play("loop")
		var t = Timer.new()
		t.wait_time = 5.6
		t.one_shot = true
		add_child(t)
		t.timeout.connect(Callable(self, "_magnet_end"))
		t.start()

	skills_timer = randi_range(10, 15)
	
	$SkillAnimTimer.wait_time = skills_timer - 5
	$SkillAnimTimer.start()
	
	$SkillAnimTimer.wait_time = max(skills_timer - skill_anim_offset, 0.1)
	$SkillTimer.wait_time = skills_timer
	$SkillTimer.start()

func _spawn_bullet() -> void:
	var bullet_scene: PackedScene = load("res://Gres/Scenes/enemies/bullets/enemy_bullet_1.tscn")
	var bullet: Node2D = bullet_scene.instantiate()
	get_parent().add_child(bullet)

	# --- POSIZIONE + SPREAD ---
	var spread := 6.0  # quanto i colpi si allargano lateralmente
	var offset := Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
	bullet.global_position = canon.global_position + offset

	# --- DIREZIONE ---
	var dir: Vector2 = (player.global_position - canon.global_position).normalized()
	var angle_offset := deg_to_rad(randf_range(-25, 25))  # cono ±25°
	dir = dir.rotated(angle_offset)

	# --- APPLICAZIONE ---
	bullet.rotation = dir.angle()
	bullet.set_direction(dir)
	bullet.set_texture(bullet_texture)



func shoot_mitra():
	if not can_mitra:
		return
	can_mitra = false
	$SkillMitra.start()

	for i in range(6):
		_spawn_bullet()
		await get_tree().create_timer(0.1).timeout  # 0.1 secondi tra colpi

	fire_timer.start()  # cooldown generale


func _on_skill_anim_timer_timeout() -> void:
	#===SKILL ANIMATIONS===#
	match  current_skill:
		"dash_attack":
			var s_tween = create_tween()
			s_tween.tween_property($DashAttackFX, "modulate:a", 1.0, 4).set_ease(Tween.EASE_IN)
			s_tween.tween_property($DashAttackFX, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_OUT)
			await s_tween.finished
		"shield":
			is_shielded = true
			$SkillShield.wait_time = randi_range(4.0, 8.0)
			$SkillShield.start()
			var s_tween = create_tween()
			s_tween.tween_property($ShieldFX, "visible", true, 0.1).set_ease(Tween.EASE_IN)
			s_tween.tween_property($ShieldFX, "visible", false, 0.15).set_ease(Tween.EASE_OUT)
			s_tween.tween_property($ShieldFX, "visible", true, 0.1).set_ease(Tween.EASE_IN)
			await s_tween.finished
		"mitra":
			shoot_mitra()
				
			

func _on_skill_shield_timeout() -> void:
	is_shielded = false
	var s_tween = create_tween()
	s_tween.tween_property($ShieldFX, "visible", false, 0.1).set_ease(Tween.EASE_IN)
	s_tween.tween_property($ShieldFX, "visible", true, 0.15).set_ease(Tween.EASE_OUT)
	s_tween.tween_property($ShieldFX, "visible", false, 0.1).set_ease(Tween.EASE_IN)
	await s_tween.finished
	$SkillTimer.wait_time = skills_timer
	$SkillTimer.start()
	
func _on_skill_mitra_timeout() -> void:
	can_mitra = true
