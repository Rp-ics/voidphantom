extends Area2D

signal bonus_touched

@export var speed: float = 120.0
@onready var sprite: Sprite2D     = $Sprite
@onready var shape: CollisionShape2D = $CollisionShape2D

var bonuses := ["heal", "times", "shield", "stamina"]
var bonus:  String  = "heal"
var target: Node2D  = null

# --- VFX state ---
var _pulse:      float = 0.0    # fase oscillazione
var _trail:      Array = []     # scia di posizioni
var _particles:  Array = []     # particelle di raccolta
var _collected:  bool  = false

# Colori per tipo bonus
const BONUS_COLORS := {
	"heal":    Color(1.0, 0.25, 0.35),
	"shield":  Color(0.2, 0.6,  1.0),
	"stamina": Color(0.1, 0.9,  0.4),
	"times":   Color(1.0, 0.85, 0.1),
	"speed":   Color(0.1, 1.0,  0.9),
	"slowness":Color(0.6, 0.1,  0.8),
}

const BONUS_GLOW := {
	"heal":    Color(1.0, 0.1,  0.2,  0.3),
	"shield":  Color(0.1, 0.4,  1.0,  0.3),
	"stamina": Color(0.0, 0.8,  0.3,  0.3),
	"times":   Color(1.0, 0.8,  0.0,  0.3),
	"speed":   Color(0.0, 1.0,  0.8,  0.3),
	"slowness":Color(0.5, 0.0,  0.9,  0.3),
}

# Quanti trail samples conservare
const TRAIL_MAX := 12

func _ready() -> void:
	# FIX: randi() % 2 per vero 50/50
	if randi() % 2 == 0:
		$loop.play("rottion_1")
	else:
		$loop.play("rotation_2")

	bonus = bonuses.pick_random()
	_set_bonus_texture()
	_find_player()

	if target == null:
		set_physics_process(false)

	# Entrata epica: scala da 0 con bounce
	scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)

func _physics_process(delta: float) -> void:
	if target == null:
		_find_player()
		return
	if _collected:
		return

	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta

	# Aggiorna scia
	_trail.push_front(global_position)
	if _trail.size() > TRAIL_MAX:
		_trail.resize(TRAIL_MAX)

func _process(delta: float) -> void:
	_pulse = fmod(_pulse + delta * 3.0, TAU)

	# aggiorna particelle raccolta
	for i in range(_particles.size() - 1, -1, -1):
		var p = _particles[i]
		p.life -= delta
		if p.life <= 0.0:
			_particles.remove_at(i)
			continue
		p.pos += p.vel * delta
		p.vel.y -= 80.0 * delta
		p.alpha = clamp(p.life / p.max_life, 0.0, 1.0)

	queue_redraw()

func _draw() -> void:
	if _collected:
		_draw_collect_particles()
		return

	var bc: Color = BONUS_COLORS.get(bonus, Color.WHITE)
	var gc: Color = BONUS_GLOW.get(bonus,  Color(1,1,1,0.2))

	# --- SCIA ---
	_draw_trail(bc)

	# --- GLOW PULSANTE ---
	var glow_r = 26.0 + sin(_pulse) * 5.0
	var glow_a = gc.a + sin(_pulse) * 0.07
	for i in range(3):
		var c = gc
		c.a = max(0.0, glow_a - i * 0.08)
		draw_circle(Vector2.ZERO, glow_r + i * 9.0, c)

	# --- ANELLO ROTANTE attorno allo sprite ---
	_draw_orbit_ring(bc)

	# --- PARTICELLE ambient ---
	_draw_collect_particles()

func _draw_trail(bc: Color) -> void:
	if _trail.size() < 2:
		return
	for i in range(1, _trail.size()):
		var t  = 1.0 - float(i) / float(_trail.size())
		var c  = bc
		c.a    = t * 0.55
		var p1 = _trail[i - 1] - global_position   # converti in spazio locale
		var p2 = _trail[i]     - global_position
		var width = max(1.0, t * 5.0)
		draw_line(p1, p2, c, width, true)

func _draw_orbit_ring(bc: Color) -> void:
	var segments  = 10
	var radius    = 22.0 + sin(_pulse * 1.3) * 3.0
	var rot_speed = _pulse * 1.2

	for i in range(segments):
		var a1 = rot_speed + (TAU / segments) * i
		var a2 = rot_speed + (TAU / segments) * (i + 0.55)
		var p1 = Vector2(cos(a1), sin(a1)) * radius
		var p2 = Vector2(cos(a2), sin(a2)) * radius
		var alpha = 0.4 + sin(_pulse + i * 0.8) * 0.25
		var c = bc
		c.a = alpha
		draw_line(p1, p2, c, 2.0, true)

func _draw_collect_particles() -> void:
	for p in _particles:
		var c: Color = p.color
		c.a = p.alpha
		# converti da global a local
		var local_pos = p.pos - global_position
		draw_circle(local_pos, p.size, c)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body.is_in_group("player"):
		_collected = true
		_apply_bonus_to_player(body)
		GlobalStats.powerups_lvl   += 1
		GlobalStats.total_powerups += 1

		# Spawn burst particelle
		_spawn_collect_burst()

		# FIX: rimosso queue_free() immediato — ora aspetta il tween
		var tw = create_tween()
		tw.tween_property(self, "scale",      Vector2(2.2, 2.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.35)
		tw.tween_callback(queue_free)

		# Disabilita collisione subito
		if is_instance_valid(shape):
			shape.set_deferred("disabled", true)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]
		set_physics_process(true)

# ---------------------------
# BONUS TEXTURE  (FIX: stat corrette per tipo)
# ---------------------------
func _set_bonus_texture() -> void:
	match bonus:
		"heal":
			sprite.texture = load("res://Gres/Assets/Icons/heart_%d.png"    % GlobalStats.heal_bonus)
		"shield":
			sprite.texture = load("res://Gres/Assets/Icons/shield_%d.png"   % GlobalStats.shield_bonus)
		"stamina":
			sprite.texture = load("res://Gres/Assets/Icons/stamina_%d.png"  % GlobalStats.stamina_bonus)
		"times":
			sprite.texture = load("res://Gres/Assets/Icons/time_slow_%d.png" % GlobalStats.time_slow_bonus)
		"speed":
			sprite.texture = load("res://Gres/Assets/Icons/speed.png")
		"slowness":
			sprite.texture = load("res://Gres/Assets/Icons/slowness.png")

# ---------------------------
# APPLY BONUS
# ---------------------------
func _apply_bonus_to_player(_player: Node2D) -> void:
	match bonus:
		"heal":
			Global.player_hp = min(Global.player_hp + 20, Global.player_max_hp)
		"shield":
			var add_time := [0.0, 1.5, 3.0, 6.0]
			Global.player_immunity_time += add_time[clamp(GlobalStats.shield_bonus, 0, 3)]
			Global.player_immunity = true
		"stamina":
			var add_stam := [0, 10, 20, 50]
			Global.player_stamina += add_stam[clamp(GlobalStats.stamina_bonus, 0, 3)]
		"times":
			var add_time := [0.0, 1.0, 2.5, 4.0]
			GlobalStats.time_slow_time += add_time[clamp(GlobalStats.time_slow_bonus, 0, 3)]
			GlobalStats.time_slow = true
		"speed":
			pass
		"slowness":
			pass

	Global.emit_signal("bonus_touched", bonus)

# ---------------------------
# PARTICELLE
# ---------------------------
func _spawn_collect_burst() -> void:
	var bc = BONUS_COLORS.get(bonus, Color.WHITE)
	for i in range(16):
		var angle = TAU * i / 16.0 + randf_range(-0.3, 0.3)
		var spd   = randf_range(50.0, 160.0)
		_particles.append({
			"pos":      global_position + Vector2(randf_range(-5,5), randf_range(-5,5)),
			"vel":      Vector2(cos(angle), sin(angle)) * spd,
			"life":     randf_range(0.3, 0.7),
			"max_life": 0.7,
			"alpha":    1.0,
			"size":     randf_range(2.5, 6.0),
			"color":    bc.lightened(randf_range(0.0, 0.35)),
		})
