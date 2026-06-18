extends CharacterBody2D
class_name BaseEnemy

signal enemy_died

@onready var player    = null
@onready var fire_area = $FireArea
@onready var dodge_area= $DodgeArea
@onready var canon     = $Canon
@onready var fire_timer= $FireTimer

@export var type:           String = "enemy"
@export var targhet_look:   PackedScene
@export var speed:          float  = 100.0
@export var originalspeed:  float  = 100.0
@export var dodge_distance: float  = 300.0
@export var dodge_duration: float  = 0.25
@export var shoot_bullet_paths: Array[String] = [
	"res://Gres/Scenes/enemies/bullets/enemy_bullet_1.tscn"
]
@export var hp:           int    = 1
@export var max_hp:       int    = 1
@export var fire_rate:    float  = 1.2
@export var dodge_chance: int    = 10
@export var group:        String = "player"
@export var chest_scenes:       Array[PackedScene]
@export var bonus_scenes:       Array[PackedScene]
@export var chest_spawn_points: Array[Node2D]

@export var bonus_scene: PackedScene
@export var spawn_interval: float = 5.0  # Secondi tra uno spawn e l'altro
@export var spawn_area: Vector2 = Vector2(800, 400)  # Area di spawn (larghezza, altezza)

@onready var spawn_timer: Timer = Timer.new()


var is_shielded:  bool = false
var shield_timer: Timer
var not_dead:     bool = true
var can_mitra:    bool = true
var bullet_scene

var shards = ["void_shard","magma_shard","ice_shard","light_shard"]
var shard  = ""
var can_random_bull := true
var bullet_texture:  Texture2D = null

var blood_linked_enemies: Array = []
var is_blood_linked:      bool  = false

var bullet_se = [
	"res://Gres/Music/SE/gun_1.ogg", "res://Gres/Music/SE/gun_2.ogg",
	"res://Gres/Music/SE/gun_3.ogg", "res://Gres/Music/SE/gun_6.ogg",
	"res://Gres/Music/SE/gun_7.ogg", "res://Gres/Music/SE/gun_13.ogg",
	"res://Gres/Music/SE/gun_20.ogg",
]

var current_skill = ["dash_attack","orbital","shield","mitra","magnet_pull","invisible"]

const SKILL_PATHS = {
	"dash_attack": "res://Gres/Scripts/EnemySkills/DashAttack.gd",
	"orbital":     "res://Gres/Scripts/EnemySkills/Orbital.gd",
	"shield":      "res://Gres/Scripts/EnemySkills/Shield.gd",
	"mitra":       "res://Gres/Scripts/EnemySkills/Mitra.gd",
	"magnet_pull": "res://Gres/Scripts/EnemySkills/MagnetPull.gd",
	"invisible":   "res://Gres/Scripts/EnemySkills/Invisible.gd"
}

var skills_timer:      int   = 10
var skill_anim_offset: float = 5.0

var can_move:    bool = true
var can_shoot:   bool = true
var on_shoot_area:bool= false
var can_follow:  bool = true
var can_dodge:   bool = true
var can_rotate:  bool = true

var dodge_vector:  Vector2 = Vector2.ZERO
var is_dodging:    bool    = false
var is_using_skill:bool    = false
var can_emit:      bool    = true

var bull_se

var can_mind := true

@onready var body_sprite  = $BodySprite
@onready var wings_sprite = $WingsSprite
@onready var prop_sprite  = $PropSprite

const MAX_BODY = 11; const MAX_WINGS = 10; const MAX_PROP = 10; const MAX_CANON = 10
const MAX_BODY_M = 4; const MAX_WINGS_M = 4; const MAX_PROP_M = 7; const MAX_CANON_M = 10

const COLORS = [
	Color(1.0,0.0,0.0,1.0), Color(0,0,1), Color(0,1,0), Color(1,1,0),
	Color(1,0.5,0), Color(1,1,1), Color(0.5,0,1), Color(0.0,1.0,0.836,1.0),
	Color(1.0,0.0,0.984,1.0), Color(0.613,0.398,0.585,1.0), Color(0.446,0.415,0.664,1.0),
	Color(0.664,0.296,0.296,1.0), Color(0.41,0.211,0.0,1.0), Color(0.274,0.418,0.381,1.0),
]

# ==============================================================
# STATO SPECIALE
# ==============================================================
var is_mind_controlled:          bool   = false
var _mind_control_original_group:String = ""
var _original_modulate:          Color  = Color.WHITE
var is_revived:                  bool   = false
var _no_dodge_timer:             float  = 0.0

# ==============================================================
# NODI AURA FX PERSISTENTI
# ==============================================================
var _aura_node:      Node2D = null   # aura procedurale attiva
var _burn_fx_node:   Node2D = null   # fiamme burn
var _windup_node:    Node2D = null   # indicatore windup skill

# Salva colore originale dei sprite (usato per ripristinare dopo freeze/MC)
var _sprite_base_modulate: Color = Color.WHITE


# ==============================================================
# SISTEMA BUFF / DEBUFF
# ==============================================================
var active_buffs: Array = []

func apply_buff(buff_name: String, duration: float, params: Dictionary = {}) -> void:
	for b in active_buffs:
		if b.name == buff_name:
			b.duration = max(b.duration, duration); b.timer = 0.0; return
	var buff = { "name": buff_name, "duration": duration,
				 "timer": 0.0, "params": params, "tick_timer": 0.0 }
	active_buffs.append(buff)
	_buff_on_apply(buff)

func remove_buff(buff_name: String) -> void:
	for i in range(active_buffs.size()):
		if active_buffs[i].name == buff_name:
			_buff_on_remove(active_buffs[i]); active_buffs.remove_at(i); break

func has_buff(buff_name: String) -> bool:
	for b in active_buffs:
		if b.name == buff_name: return true
	return false

func _update_buffs(delta: float) -> void:
	for i in range(active_buffs.size() - 1, -1, -1):
		var buff = active_buffs[i]
		buff.timer += delta
		if buff.params.has("dps"):
			buff.tick_timer += delta
			var interval = buff.params.get("interval", 1.0)
			if buff.tick_timer >= interval:
				buff.tick_timer = 0.0
				if not_dead:
					hp -= buff.params.dps * interval
					flash_damage()
					spawn_damage_popup(buff.params.dps * interval)
					if hp <= 0: not_dead = false; die()
		if buff.name == "no_dodge": can_dodge = false
		if buff.timer >= buff.duration:
			_buff_on_remove(buff); active_buffs.remove_at(i)
	if _no_dodge_timer > 0:
		_no_dodge_timer -= delta; can_dodge = false
	elif not has_buff("no_dodge"):
		can_dodge = true

func _update_mind_control_target() -> void:
	# Quando il nemico è sotto controllo mentale, deve attaccare altri nemici.
	# Cerchiamo un nemico valido (diverso da sé) nel gruppo "enemy".
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if e != self and is_instance_valid(e):
			player = e
			return
	# Se non ci sono altri nemici, il target rimane quello precedente (o null)

# === MIND CONTROLL === #
func mind_controll_zombie():
	if not is_mind_controlled: return
	if can_mind:
		can_mind = false
		# Crea il timer se non esiste
		if not has_node("ZombieDead"):
			var t = Timer.new()
			t.name = "ZombieDead"
			t.one_shot = true
			t.wait_time = 1.0
			t.timeout.connect(die)   # muore dopo 10 secondi precisi
			add_child(t)
		$ZombieDead.start()
	
# --------------------------------------------------------------
func _buff_on_apply(buff: Dictionary) -> void:
	match buff.name:

		"frozen":
			can_move = false; can_follow = false; can_dodge = false
			# FX: tween modulate + cristalli — scala mai toccata
			_fx_tween_modulate(Color(0.4, 0.85, 1.0, 1.0), 0.18)
			_fx_crystal_burst(Color(0.7, 0.95, 1.0, 0.85))
			_replace_aura(_FrozenAura.new())
			# Burst draw impatto freeze
			var fz := _FreezeImpactFX.new()
			call_deferred("add_child", fz)
			# ==================================================
			# IMPLEMENTA TU: se hai GPUParticles2D $IceParticles
			# if has_node("IceParticles"): $IceParticles.emitting = true
			# ==================================================

		"slowed":
			speed = originalspeed * buff.params.get("amount", 0.4)
			# FX: alone azzurro distorto + modulate lieve
			_replace_aura(_SlowedAura.new())
			_fx_tween_modulate(Color(0.6, 0.8, 1.0, 1.0), 0.2)
			# ==================================================
			# IMPLEMENTA TU: riduce la velocità dell'AnimationPlayer
			# if has_node("AnimationPlayer"):
			#   $AnimationPlayer.speed_scale = buff.params.get("amount", 0.4)
			# ==================================================

		"shielded":
			is_shielded = true
			# FX: ring burst difensivo + aura scudo
			_fx_ring_burst(Color(0.5, 0.8, 1.0, 0.6), 100.0, 0.35)
			_replace_aura(_ShieldedAura.new())

		"burn":
			# FX: fiamme procedurali (nodo draw)
			if not is_instance_valid(_burn_fx_node):
				_burn_fx_node = _BurnFX.new()
				call_deferred("add_child", _burn_fx_node)
			# ==================================================
			# IMPLEMENTA TU: GPUParticles2D $BurnParticles
			# if has_node("BurnParticles"): $BurnParticles.emitting = true
			# ==================================================

		"mind_controlled":
			is_mind_controlled = true
			_mind_control_original_group = group
			_original_modulate = modulate
			group = "enemy"
			can_dodge = false
			_fx_mind_control_possession()
			_replace_aura(_MindControlAura.new())
			_update_mind_control_target()
			mind_controll_zombie()   # <-- AVVIA IL TIMER

		"marked":
			# FX: indicatore cross-hairs sul nemico (mirino)
			_replace_aura(_MarkedAura.new())
			# ==================================================
			# IMPLEMENTA TU: in player_bullet._on_body_entered
			# if source.has_meta("herald_judgment_active") and has_buff("marked"):
			#   # chain 70% danno verso altri marked
			# ==================================================

		"no_dodge":
			can_dodge = false
			# FX: micro-tremolio della posizione
			_fx_micro_shake(0.25)

		"haunted":
			# +20% danno subito — gestito in take_damage()
			# FX: aura fantasmagorica bianco/azzurra
			_replace_aura(_HauntedAura.new())

		"entropy_stunned":
			can_move = false; can_follow = false; can_dodge = false
			# FX: draw puro — scala mai toccata
			var es := _EntropyStunFX.new()
			call_deferred("add_child", es)
			_fx_ring_burst(Color(0.6, 0.6, 0.6, 0.7), 80.0, 0.3)
			_fx_tween_modulate(Color(0.7, 0.7, 0.7, 1.0), 0.15)

# --------------------------------------------------------------
func _buff_on_remove(buff: Dictionary) -> void:
	match buff.name:

		"frozen":
			can_move = true; can_follow = true; can_dodge = true
			_fx_tween_modulate(_sprite_base_modulate, 0.25)
			_remove_aura()
			# Burst di "scongelamento": scintille bianche
			_fx_ring_burst(Color(0.8, 1.0, 1.0, 0.5), 60.0, 0.25)
			# ==================================================
			# IMPLEMENTA TU: if has_node("IceParticles"): $IceParticles.emitting = false
			# ==================================================

		"slowed":
			speed = originalspeed
			_fx_tween_modulate(_sprite_base_modulate, 0.2)
			_remove_aura()
			# ==================================================
			# IMPLEMENTA TU:
			# if has_node("AnimationPlayer"): $AnimationPlayer.speed_scale = 1.0
			# ==================================================

		"shielded":
			is_shielded = false
			_remove_aura()

		"burn":
			if is_instance_valid(_burn_fx_node):
				_burn_fx_node.queue_free(); _burn_fx_node = null
			# ==================================================
			# IMPLEMENTA TU: if has_node("BurnParticles"): $BurnParticles.emitting = false
			# ==================================================

		"mind_controlled":
			is_mind_controlled = false
			group = _mind_control_original_group
			_fx_tween_modulate(_original_modulate, 0.3)
			can_dodge = true
			_remove_aura()
			var tg = group if group != null and group != "" else "player"
			player = get_tree().get_first_node_in_group(tg)

		"marked":
			_remove_aura()

		"no_dodge":
			can_dodge = true

		"haunted":
			_remove_aura()

		"entropy_stunned":
			can_move = true; can_follow = true; can_dodge = true
			_fx_tween_modulate(_sprite_base_modulate, 0.2)


# ==============================================================
# FX PROCEDURALI — NEMICO
# ==============================================================

func _fx_tween_modulate(col: Color, dur: float) -> void:
	create_tween().tween_property(self, "modulate", col, dur)

func _fx_ring_burst(col: Color, radius: float, dur: float) -> void:
	var ring := _RingBurst.new()
	ring.global_position = global_position
	ring.ring_color = col
	ring.max_radius = radius
	ring.duration = dur
	# Usa call_deferred per evitare il problema di "parent busy"
	get_parent().call_deferred("add_child", ring)

func _fx_crystal_burst(col: Color) -> void:
	var burst := _CrystalBurst.new()
	burst.global_position = global_position
	burst.burst_color = col
	get_parent().call_deferred("add_child", burst)

func _fx_micro_shake(duration: float) -> void:
	var tw = create_tween()
	var reps := int(duration / 0.05)
	for _i in range(reps):
		tw.tween_property(self, "position", position + Vector2(randf_range(-3,3), randf_range(-3,3)), 0.025)
		tw.tween_property(self, "position", position, 0.025)

func _fx_mind_control_possession() -> void:
	# Flash viola x3 rapido — scala mai toccata
	var tw = create_tween()
	for _i in range(3):
		tw.tween_property(self, "modulate", Color(1.2, 0.0, 1.8, 1.0), 0.06)
		tw.tween_property(self, "modulate", Color(0.3, 0.0, 0.5, 1.0), 0.06)
	tw.tween_property(self, "modulate", Color(0.6, 0.0, 0.9, 1.0), 0.1)
	# Draw overlay possessione psichica
	var mc_fx := _MindControlPossessionFX.new()
	call_deferred("add_child", mc_fx)
	# Ring psichico
	_fx_ring_burst(Color(0.7, 0.0, 1.0, 0.65), 120.0, 0.45)

# --- HURT: flash + impatto draw puro — MAI tocca scale ---
func flash_damage(amount: float = 0.0) -> void:
	var is_heavy := max_hp > 0 and amount > max_hp * 0.18
	var restore  := Color(0.6, 0.0, 0.9, 1.0) if is_mind_controlled else _sprite_base_modulate

	# Modulate flash: tween solo colore, scala intatta
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color(2.2, 0.0, 0.0, 1.0) if is_heavy else Color(1.8, 0.0, 0.0, 1.0), 0.04)
	tw.tween_property(self, "modulate", restore, 0.18).set_delay(0.04)

	# Shake posizione (non tocca scale)
	if is_heavy:
		_fx_micro_shake(0.28)

	# FX draw puro: ring + schegge proporzionali al danno
	var hit_fx := _HitFlashFX.new()
	hit_fx.is_heavy  = is_heavy
	hit_fx.hit_color = Color(2.2, 0.0, 0.0, 1.0) if is_heavy else Color(1.6, 0.0, 0.0, 1.0)
	hit_fx.enemy_scale = scale
	call_deferred("add_child", hit_fx)

# --- Aura management ---
func _replace_aura(new_aura: Node2D) -> void:
	_remove_aura()
	_aura_node = new_aura
	call_deferred("add_child", _aura_node)

func _remove_aura() -> void:
	if is_instance_valid(_aura_node): _aura_node.queue_free(); _aura_node = null

# --- Windup skill (indicatore pre-attivazione) ---
func _spawn_windup(skill_name: String) -> void:
	if is_instance_valid(_windup_node):
		_windup_node.queue_free()
	_windup_node = _WindupIndicator.new()
	_windup_node.skill_name = skill_name
	_windup_node.duration = skill_anim_offset
	call_deferred("add_child", _windup_node)

func _remove_windup() -> void:
	if is_instance_valid(_windup_node): _windup_node.queue_free(); _windup_node = null

# --- SPAWN FX — scala mai toccata ---
func _fx_spawn() -> void:
	# Glitch alpha (solo modulate, no scale)
	var tw2 = create_tween()
	for _i in range(3):
		tw2.tween_property(self, "modulate:a", 0.05, 0.05)
		tw2.tween_property(self, "modulate:a", 1.0,  0.05)
	# Ring burst apparizione
	_fx_ring_burst(_sprite_base_modulate * Color(1,1,1,0.55), 70.0, 0.35)
	# Overlay draw: flash burst esplosivo di spawn
	var sfx := _SpawnFX.new()
	sfx.spawn_color = _sprite_base_modulate
	sfx.is_boss     = (type == "mini_boss")
	add_child(sfx)

# --- MORTE EPICA ---
func _fx_death_explosion() -> void:
	# Flash bianco istantaneo
	var tw_flash = create_tween().set_parallel(true)
	for sp in [body_sprite, wings_sprite, prop_sprite]:
		if is_instance_valid(sp):
			tw_flash.tween_property(sp, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.03)

	# Ring burst colore tipo morte
	var death_col := Color(1.0, 0.4, 0.0, 0.8)
	if is_mind_controlled: death_col = Color(0.9, 0.0, 1.0, 0.85)
	if is_revived:         death_col = Color(0.0, 1.0, 0.3, 0.85)
	_fx_ring_burst(death_col, 140.0 if type == "enemy" else 260.0, 0.5)

	# Dispersione pezzi con rotazione
	var parts := [body_sprite, wings_sprite, prop_sprite]
	for part in parts:
		if not is_instance_valid(part): continue
		var rand_dir  := Vector2(randf_range(-1,1), randf_range(-1,1)).normalized()
		var target_pos = part.global_position + rand_dir * randf_range(55.0, 120.0)
		var tw = create_tween()
		tw.tween_property(part, "global_position", target_pos, randf_range(0.5, 1.1)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var tw_rot = create_tween().set_loops()
		tw_rot.tween_property(part, "rotation_degrees", randf_range(360, 720), randf_range(1.5, 3.0)).as_relative()
		var tw_fade = create_tween()
		tw_fade.tween_property(part, "modulate:a", 0.0, 0.9).set_delay(0.15)


# ==============================================================
# NODI DRAW INTERNI — AURE E FX PROCEDURALI
# ==============================================================

class _RingBurst extends Node2D:
	var ring_color: Color = Color(1,1,1,0.6)
	var max_radius: float = 200.0
	var duration:   float = 0.4
	var _age:       float = 0.0
	func _process(delta): _age += delta; queue_redraw(); if _age >= duration: queue_free()
	func _draw():
		var t := _age / duration
		for ri in range(2):
			var phase = min(t + ri * 0.15, 1.0)
			var r := max_radius * pow(phase, 0.6)
			var c := ring_color; c.a = (1.0 - phase) * ring_color.a
			draw_arc(Vector2.ZERO, r, 0, TAU, 48, c, 4.0 * (1.0 - t), true)

class _CrystalBurst extends Node2D:
	var burst_color: Color = Color(0.7, 0.95, 1.0, 0.85)
	var _age: float = 0.0; var _dur: float = 0.5
	var _arms: Array = []
	func _ready():
		for i in range(12):
			var angle := (TAU / 12.0) * i + randf_range(-0.15, 0.15)
			_arms.append({"dir": Vector2(cos(angle), sin(angle)), "len": randf_range(18.0, 34.0)})
	func _process(delta): _age += delta; queue_redraw(); if _age >= _dur: queue_free()
	func _draw():
		var t := _age / _dur; var a := 1.0 - t
		for arm in _arms:
			var tip: Vector2 = arm.dir * arm.len * pow(t, 0.45)
			draw_line(Vector2.ZERO, tip, Color(burst_color.r, burst_color.g, burst_color.b, a * 0.8), 1.8, true)
			draw_circle(tip, (1.0 - t) * 3.0, Color(1.0, 1.0, 1.0, a * 0.7))
			var perp = Vector2(-arm.dir.y, arm.dir.x) * arm.len * 0.28 * (1.0 - t)
			draw_line(arm.dir * arm.len * 0.5 * pow(t, 0.45),
					  arm.dir * arm.len * 0.5 * pow(t, 0.45) + perp,
					  Color(burst_color.r, burst_color.g, burst_color.b, a * 0.4), 1.0, true)

class _BurnFX extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 18.0) * 0.5 + 0.5
		for i in range(8):
			var a := (TAU / 8.0) * i + _t * 2.0
			var r := 12.0 + p * 6.0
			var tip := Vector2(cos(a), sin(a) - 0.4) * r
			draw_line(Vector2.ZERO, tip, Color(1.0, 0.28 + p * 0.45, 0.0, 0.6 * p), 2.0 * p, true)
			if i % 3 == 0: draw_circle(tip, 1.5 + p * 1.5, Color(1.0, 0.9, 0.2, 0.65 * p))
		draw_circle(Vector2.ZERO, 4.5 + p * 3.0, Color(1.0, 0.3, 0.0, 0.4))

class _FrozenAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 5.0) * 0.5 + 0.5
		for arm in range(8):
			var angle := (TAU / 8.0) * arm + _t * 0.25
			var r := 24.0 + p * 6.0
			var tip := Vector2(cos(angle), sin(angle)) * r
			draw_line(Vector2.ZERO, tip, Color(0.65, 0.92, 1.0, 0.55 + p * 0.25), 1.5, true)
			draw_circle(tip, 2.0 + p * 1.5, Color(0.88, 1.0, 1.0, 0.8))
			var perp := Vector2(-sin(angle), cos(angle)) * 5.5 * (1.0 - p * 0.4)
			draw_line(Vector2(cos(angle), sin(angle)) * r * 0.55 - perp,
					  Vector2(cos(angle), sin(angle)) * r * 0.55 + perp,
					  Color(0.6, 0.9, 1.0, 0.4), 1.0, true)
		draw_arc(Vector2.ZERO, 22.0 + p * 5.0, 0, TAU, 32, Color(0.5, 0.85, 1.0, 0.22), 7.0, true)

class _SlowedAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 3.0) * 0.5 + 0.5
		draw_arc(Vector2.ZERO, 22.0 + p * 6.0, 0, TAU, 32, Color(0.2, 0.5, 1.0, 0.18 + p * 0.1), 7.0, true)
		# Distorsione: piccole onde concentriche
		for ri in range(2):
			var phase := fmod(_t * 0.6 + ri * 0.5, 1.0)
			draw_arc(Vector2.ZERO, lerp(0.0, 35.0, phase), 0, TAU, 24, Color(0.3, 0.6, 1.0, (1.0-phase)*0.25), 2.0, true)

class _ShieldedAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 4.0) * 0.5 + 0.5
		draw_circle(Vector2.ZERO, 30.0 + p * 4.0, Color(0.5, 0.8, 1.0, 0.08))
		draw_arc(Vector2.ZERO, 30.0 + p * 4.0, _t * 2.0, _t * 2.0 + TAU * 0.6, 24, Color(0.6, 0.9, 1.0, 0.55 + p * 0.2), 3.0, true)
		draw_arc(Vector2.ZERO, 30.0 + p * 4.0, _t * 2.0 + PI, _t * 2.0 + PI + TAU * 0.6, 24, Color(0.4, 0.7, 1.0, 0.45), 2.0, true)
		for dot in range(4):
			var da := _t * 2.8 + (TAU / 4.0) * dot
			draw_circle(Vector2(cos(da), sin(da)) * (30.0 + p * 4.0), 2.5, Color(0.8, 1.0, 1.0, 0.85))

class _MindControlAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 5.0) * 0.5 + 0.5
		for ring in range(2):
			var phase := _t * 2.8 + ring * PI
			var r := 26.0 + float(ring) * 10.0 + p * 3.0
			draw_arc(Vector2.ZERO, r, phase, phase + TAU * 0.65, 20,
					 Color(0.7, 0.0, 1.0, 0.55 - ring * 0.15), 2.5, true)
		for dot in range(3):
			var da := _t * 4.5 + (TAU / 3.0) * dot
			draw_circle(Vector2(cos(da), sin(da)) * 22.0, 3.5, Color(0.9, 0.3, 1.0, 0.88))
		# Occhio centrale psichico
		draw_circle(Vector2.ZERO, 5.5 + p * 2.0, Color(0.5, 0.0, 0.9, 0.55))
		draw_circle(Vector2.ZERO, 2.5, Color(0.05, 0.0, 0.15, 1.0))

class _MarkedAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 8.0) * 0.5 + 0.5
		var r := 28.0 + p * 5.0
		# Cross-hairs che si restringono
		var arm := 10.0 - p * 4.0
		draw_line(Vector2(-r - arm, 0), Vector2(-r + arm, 0), Color(0.5, 0.0, 1.0, 0.9), 2.5)
		draw_line(Vector2( r - arm, 0), Vector2( r + arm, 0), Color(0.5, 0.0, 1.0, 0.9), 2.5)
		draw_line(Vector2(0, -r - arm), Vector2(0, -r + arm), Color(0.5, 0.0, 1.0, 0.9), 2.5)
		draw_line(Vector2(0,  r - arm), Vector2(0,  r + arm), Color(0.5, 0.0, 1.0, 0.9), 2.5)
		draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.6, 0.0, 1.0, 0.3 + p * 0.2), 1.5, true)
		draw_circle(Vector2.ZERO, 3.0 + p * 1.5, Color(0.8, 0.2, 1.0, 0.7))

class _HauntedAura extends Node2D:
	var _t: float = 0.0
	func _process(delta): _t += delta; queue_redraw()
	func _draw():
		var p := sin(_t * 7.0) * 0.5 + 0.5
		draw_arc(Vector2.ZERO, 28.0 + p * 7.0, 0, TAU, 32,
				 Color(0.7, 0.8, 1.0, 0.15 + p * 0.12), 10.0, true)
		# "Fantasmini" orbitanti: 2 piccole sfere sfumate
		for gh in range(2):
			var ga := _t * 2.5 + gh * PI
			var gp := Vector2(cos(ga), sin(ga)) * (20.0 + sin(_t * 4.0 + gh) * 5.0)
			draw_circle(gp, 4.5 * (0.6 + p * 0.4), Color(0.8, 0.9, 1.0, 0.35 + p * 0.2))

class _WindupIndicator extends Node2D:
	var skill_name: String = ""
	var duration:   float  = 5.0
	var _age:       float  = 0.0
	func _process(delta): _age += delta; queue_redraw(); if _age >= duration: queue_free()
	func _draw():
		var pct := _age / duration
		var blink := fmod(_age, 0.4) < 0.2 if pct > 0.75 else true
		if not blink: return
		# Colore basato su skill
		var col := Color.WHITE
		match skill_name:
			"dash_attack":  col = Color(1.0, 0.7, 0.0, 0.85)
			"shield":       col = Color(0.4, 0.7, 1.0, 0.85)
			"mitra":        col = Color(1.0, 0.3, 0.0, 0.85)
			"invisible":    col = Color(0.5, 0.5, 1.0, 0.85)
			"magnet_pull":  col = Color(0.8, 0.2, 1.0, 0.85)
			"orbital":      col = Color(0.3, 0.6, 1.0, 0.85)
		# Arco che si riempie (progressione windup)
		draw_arc(Vector2(0, -42), 14.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 32,
				 Color(col.r, col.g, col.b, 0.3), 5.0, true)
		draw_arc(Vector2(0, -42), 14.0, -PI * 0.5, -PI * 0.5 + TAU * pct, 32,
				 col, 2.0, true)
		# Icona skill semplice: cerchio con lettera (usa punto come segno)
		draw_circle(Vector2(0, -42), 3.5 * (0.7 + pct * 0.3), col)

# ==============================================================
# AURA PERMANENTE — si aggiorna ogni frame in base allo stato
# (usare invece di _replace_aura quando si vuole una sola aura
#  che gestisce tutto)
# ==============================================================
class _PermanentAura extends Node2D:
	var enemy_ref: Node2D = null
	var _t: float = 0.0
	func _process(delta):
		if not is_instance_valid(enemy_ref): queue_free(); return
		_t += delta; queue_redraw()
	func _draw():
		if not is_instance_valid(enemy_ref): return
		var hp_ratio := float(enemy_ref.hp) / float(max(enemy_ref.max_hp, 1))
		var is_boss  = enemy_ref.type == "mini_boss"
		# HP critico: rosso pulsante
		if hp_ratio < 0.3:
			var danger := (1.0 - hp_ratio / 0.3)
			var dp = abs(sin(_t * 9.0 * (1.0 + danger)))
			draw_arc(Vector2.ZERO, 20.0 + dp * 5.0, 0, TAU, 24,
					 Color(1.0, 0.0, 0.0, dp * 0.45 * danger), 5.5, true)
		# Mini boss: corona dorata permanente
		if is_boss:
			var bp := sin(_t * 2.5) * 0.4 + 0.6
			for ci in range(10):
				var ca := (TAU / 10.0) * ci + _t * 0.35
				var cr := 42.0 + bp * 7.0
				draw_circle(Vector2(cos(ca), sin(ca)) * cr, 2.5 * bp, Color(1.0, 0.75, 0.0, 0.7 * bp))
			draw_arc(Vector2.ZERO, 40.0, 0, TAU, 48, Color(1.0, 0.7, 0.0, 0.1), 12.0, true)



# ==============================================================
# NUOVI FX DRAW — ZERO TWEEN SULLA SCALA
# ==============================================================

# --- HIT FLASH: ring di impatto + schegge radiali al colpo ---
class _HitFlashFX extends Node2D:
	var is_heavy:     bool  = false
	var hit_color:    Color = Color(2.0, 0.0, 0.0, 1.0)
	var enemy_scale:  Vector2 = Vector2.ONE
	var _age:         float = 0.0
	var _dur:         float = 0.0
	var _shards:      Array = []

	func _ready() -> void:
		_dur = 0.35 if is_heavy else 0.22
		var shard_count := 12 if is_heavy else 7
		for i in range(shard_count):
			var angle := randf() * TAU
			var length := randf_range(10.0, 22.0) if is_heavy else randf_range(6.0, 14.0)
			_shards.append({"dir": Vector2(cos(angle), sin(angle)), "len": length,
							"speed": randf_range(1.2, 2.4)})

	func _process(delta) -> void:
		_age += delta
		queue_redraw()
		if _age >= _dur: queue_free()

	func _draw() -> void:
		var t := _age / _dur
		var inv := 1.0 - t
		var base_r = (16.0 if is_heavy else 10.0) / max(enemy_scale.x, 0.01)

		# Ring di impatto principale
		var ring_r = lerp(base_r * 0.3, base_r * 2.0, pow(t, 0.5))
		var ring_a := inv * (0.9 if is_heavy else 0.65)
		draw_arc(Vector2.ZERO, ring_r, 0, TAU, 32,
				 Color(hit_color.r, hit_color.g, hit_color.b, ring_a),
				 lerp(3.5, 0.5, t) if is_heavy else lerp(2.5, 0.3, t), true)

		# Secondo ring sfasato (solo heavy)
		if is_heavy and t < 0.6:
			var r2 = lerp(base_r * 0.6, base_r * 1.5, pow(t * 1.4, 0.6))
			draw_arc(Vector2.ZERO, r2, 0, TAU, 24,
					 Color(1.0, 0.6, 0.0, inv * 0.5), lerp(2.0, 0.2, t), true)

		# Schegge di impatto radiali
		for sh in _shards:
			var tip = sh.dir * sh.len * min(t * sh.speed * 3.0, 1.0)
			var fade := inv * (0.85 if is_heavy else 0.55)
			draw_line(Vector2.ZERO, tip,
					  Color(hit_color.r, hit_color.g * 0.5, hit_color.b * 0.3, fade),
					  lerp(2.0, 0.3, t), true)
			if is_heavy and t < 0.5:
				draw_circle(tip, (1.0 - t) * 2.5, Color(1.0, 0.9, 0.4, fade * 0.7))

		# Flash centrale (solo nei primi frame)
		if t < 0.12:
			var flash_r = base_r * 0.8 * (1.0 - t / 0.12)
			draw_circle(Vector2.ZERO, flash_r,
						Color(1.0, 1.0, 1.0, (1.0 - t / 0.12) * 0.8))


# --- SPAWN FX: burst esplosivo di materializzazione ---
class _SpawnFX extends Node2D:
	var spawn_color: Color  = Color(1.0, 1.0, 1.0, 0.8)
	var is_boss:     bool   = false
	var _age:        float  = 0.0
	var _dur:        float  = 0.55
	var _arms:       Array  = []
	var _sparks:     Array  = []

	func _ready() -> void:
		_dur = 0.7 if is_boss else 0.45
		var arm_count := 14 if is_boss else 9
		for i in range(arm_count):
			var angle := (TAU / arm_count) * i + randf_range(-0.15, 0.15)
			_arms.append({"dir": Vector2(cos(angle), sin(angle)),
						  "len": randf_range(22.0, 45.0) if is_boss else randf_range(14.0, 30.0)})
		for _s in range(16 if is_boss else 8):
			_sparks.append({"dir": Vector2(randf_range(-1,1), randf_range(-1,1)).normalized(),
							"spd": randf_range(0.8, 2.0), "sz": randf_range(1.5, 3.5)})

	func _process(delta) -> void:
		_age += delta; queue_redraw()
		if _age >= _dur: queue_free()

	func _draw() -> void:
		var t  := _age / _dur
		var inv := 1.0 - t
		var burst_t := pow(t, 0.4)

		# Alone esplosivo centrale
		var aura_r = lerp(5.0, 55.0 if is_boss else 38.0, burst_t)
		draw_circle(Vector2.ZERO, aura_r,
					Color(spawn_color.r, spawn_color.g, spawn_color.b, inv * 0.18))

		# Anello energetico
		draw_arc(Vector2.ZERO, aura_r * 0.85, 0, TAU, 32,
				 Color(spawn_color.r + 0.4, spawn_color.g + 0.2, spawn_color.b, inv * 0.7),
				 lerp(4.0, 0.5, t), true)

		# Raggi di spawn che si espandono
		for arm in _arms:
			var tip = arm.dir * arm.len * burst_t
			var fade := inv * 0.8
			draw_line(Vector2.ZERO, tip,
					  Color(1.0, spawn_color.g * 0.8 + 0.2, spawn_color.b * 0.5, fade),
					  lerp(2.5, 0.3, t), true)
			if t < 0.45:
				draw_circle(tip, (1.0 - t) * 4.0 if is_boss else (1.0 - t) * 2.5,
							Color(1.0, 1.0, 1.0, inv * 0.75))

		# Scintille volanti
		for sp in _sparks:
			var spos = sp.dir * sp.spd * aura_r * t
			draw_circle(spos, sp.sz * inv, Color(1.0, 0.9, 0.5, inv * 0.65))

		# Boss: corona boss extra
		if is_boss and t < 0.6:
			for ci in range(8):
				var ca = (TAU / 8.0) * ci + _age * 6.0
				var cr = aura_r * 0.7
				draw_circle(Vector2(cos(ca), sin(ca)) * cr,
							(1.0 - t) * 4.5, Color(1.0, 0.75, 0.0, inv * 0.9))


# --- FREEZE IMPACT FX: cristalli esplosivi e onda ghiaccio ---
class _FreezeImpactFX extends Node2D:
	var _age:  float = 0.0
	var _dur:  float = 0.4
	var _crys: Array = []

	func _ready() -> void:
		for i in range(10):
			var angle := (TAU / 10.0) * i + randf_range(-0.2, 0.2)
			_crys.append({"dir": Vector2(cos(angle), sin(angle)),
						  "len": randf_range(12.0, 28.0), "w": randf_range(1.2, 2.8)})

	func _process(delta) -> void:
		_age += delta; queue_redraw()
		if _age >= _dur: queue_free()

	func _draw() -> void:
		var t := _age / _dur; var inv := 1.0 - t
		# Onda ghiaccio espansiva
		var wave_r = lerp(8.0, 60.0, pow(t, 0.55))
		draw_arc(Vector2.ZERO, wave_r, 0, TAU, 32,
				 Color(0.5, 0.9, 1.0, inv * 0.75), lerp(4.0, 0.5, t), true)
		draw_arc(Vector2.ZERO, wave_r * 0.7, 0, TAU, 24,
				 Color(0.8, 1.0, 1.0, inv * 0.35), lerp(2.0, 0.2, t), true)
		# Schegge di cristallo
		for cr in _crys:
			var tip = cr.dir * cr.len * pow(t, 0.5)
			draw_line(Vector2.ZERO, tip,
					  Color(0.6, 0.92, 1.0, inv * 0.9), cr.w, true)
			if t < 0.5:
				draw_circle(tip, (1.0 - t) * cr.w * 1.8,
							Color(1.0, 1.0, 1.0, inv * 0.8))
		# Flash bianco centrale
		if t < 0.1:
			draw_circle(Vector2.ZERO, lerp(20.0, 0.0, t / 0.1),
						Color(0.85, 0.97, 1.0, (1.0 - t / 0.1) * 0.7))


# --- ENTROPY STUN FX: collasso statico grigio con archi ---
class _EntropyStunFX extends Node2D:
	var _age:   float = 0.0
	var _dur:   float = 0.38
	var _bolts: Array = []

	func _ready() -> void:
		for _b in range(8):
			var angle := randf() * TAU
			_bolts.append({"dir": Vector2(cos(angle), sin(angle)),
						   "mid_off": randf_range(-8.0, 8.0),
						   "len": randf_range(14.0, 28.0)})

	func _process(delta) -> void:
		_age += delta; queue_redraw()
		if _age >= _dur: queue_free()

	func _draw() -> void:
		var t := _age / _dur; var inv := 1.0 - t
		# Onde concentriche statiche
		for ri in range(3):
			var ph = fmod(t * 2.5 + ri * 0.33, 1.0)
			var r  = lerp(5.0, 45.0, ph)
			draw_arc(Vector2.ZERO, r, 0, TAU, 20,
					 Color(0.65, 0.65, 0.65, (1.0 - ph) * inv * 0.6), 2.5, true)
		# Archi elettrostatici grigi
		for bl in _bolts:
			if t > 0.7: break
			var mid = bl.dir.rotated(PI * 0.5) * bl.mid_off + bl.dir * bl.len * 0.5
			var tip  = bl.dir * bl.len
			draw_line(Vector2.ZERO, mid, Color(0.75, 0.75, 0.75, inv * 0.8), 1.5, true)
			draw_line(mid, tip, Color(0.9, 0.9, 1.0, inv * 0.7), 1.0, true)
		# Flash grigio centrale
		if t < 0.12:
			draw_circle(Vector2.ZERO, lerp(18.0, 0.0, t / 0.12),
						Color(0.7, 0.7, 0.7, (1.0 - t / 0.12) * 0.65))


# --- SHIELD ACTIVATE FX: bolla scudo esplosa verso l'esterno ---
class _ShieldActivateFX extends Node2D:
	var _age: float = 0.0
	var _dur: float = 0.45

	func _process(delta) -> void:
		_age += delta; queue_redraw()
		if _age >= _dur: queue_free()

	func _draw() -> void:
		var t := _age / _dur; var inv := 1.0 - t
		# Bolla principale che si espande
		var r = lerp(5.0, 55.0, pow(t, 0.5))
		draw_arc(Vector2.ZERO, r, 0, TAU, 48,
				 Color(0.5, 0.82, 1.0, inv * 0.85), lerp(5.0, 0.5, t), true)
		# Alone interno morbido
		draw_circle(Vector2.ZERO, r * 0.7,
					Color(0.5, 0.82, 1.0, inv * 0.12))
		# Scintille azzurre alle 6 direzioni
		for ci in range(6):
			var ca = (TAU / 6.0) * ci
			var cp = Vector2(cos(ca), sin(ca)) * r
			draw_circle(cp, inv * 4.5, Color(0.7, 1.0, 1.0, inv * 0.9))
		# Hexagono energetico interno
		for side in range(6):
			var a1 := (TAU / 6.0) * side
			var a2 := (TAU / 6.0) * (side + 1)
			var hr  = r * 0.55
			draw_line(Vector2(cos(a1), sin(a1)) * hr,
					  Vector2(cos(a2), sin(a2)) * hr,
					  Color(0.6, 0.9, 1.0, inv * 0.6), 1.2, true)


# --- MIND CONTROL POSSESSION FX: vortice psichico d'ingresso ---
class _MindControlPossessionFX extends Node2D:
	var _age:    float = 0.0
	var _dur:    float = 0.55
	var _tendrils: Array = []

	func _ready() -> void:
		for i in range(8):
			var angle := (TAU / 8.0) * i
			_tendrils.append({"base_angle": angle, "len": randf_range(18.0, 35.0),
							  "curve": randf_range(-0.6, 0.6)})

	func _process(delta) -> void:
		_age += delta; queue_redraw()
		if _age >= _dur: queue_free()

	func _draw() -> void:
		var t := _age / _dur; var inv := 1.0 - t
		# Vortice spirale in entrata
		for ri in range(3):
			var phase = fmod(t * 2.2 + ri * 0.33, 1.0)
			var r     = lerp(60.0, 5.0, pow(phase, 0.6))
			var alpha = phase * inv * 0.55
			draw_arc(Vector2.ZERO, r, _age * 8.0 + ri * 2.1,
					 _age * 8.0 + ri * 2.1 + TAU * 0.55, 18,
					 Color(0.8, 0.0, 1.0, alpha), lerp(3.5, 0.5, phase), true)
		# Tentacoli psichici
		for td in _tendrils:
			var angle = td.base_angle + _age * 4.5 * td.curve
			var reach  = td.len * min(t * 2.5, 1.0)
			var tip    = Vector2(cos(angle), sin(angle)) * reach
			draw_line(Vector2.ZERO, tip,
					  Color(0.7, 0.0, 0.9, inv * 0.75), 1.8, true)
			if t < 0.5:
				draw_circle(tip, (1.0 - t) * 3.5, Color(1.0, 0.4, 1.0, inv * 0.85))
		# Occhio psichico centrale
		var eye_r = lerp(0.0, 12.0, pow(t, 0.4)) * inv
		draw_circle(Vector2.ZERO, eye_r, Color(0.5, 0.0, 0.9, inv * 0.75))
		draw_circle(Vector2.ZERO, eye_r * 0.45, Color(0.0, 0.0, 0.0, inv))
		# Flash viola centrale iniziale
		if t < 0.15:
			draw_circle(Vector2.ZERO, lerp(25.0, 0.0, t / 0.15),
						Color(1.0, 0.0, 1.0, (1.0 - t / 0.15) * 0.75))

# --- DODGE DASH FX: scia afterimage + frecce direzionali ---
class _DodgeDashFX extends Node2D:
	var dash_dir: Vector2 = Vector2.RIGHT
	var _age:     float   = 0.0
	var _dur:     float   = 0.3
	var _ghosts:  Array   = []

	func _ready() -> void:
		for i in range(5):
			_ghosts.append({"offset": -dash_dir * float(i) * 7.0,
							"delay":  float(i) * 0.035})

	func _process(delta: float) -> void:
		_age += delta
		queue_redraw()
		if _age >= _dur:
			queue_free()

	func _draw() -> void:
		var t := _age / _dur
		var inv := 1.0 - t
		# Afterimage trail: cerchi sfumati nella direzione opposta
		for gh in _ghosts:
			var age_off = max(_age - gh.delay, 0.0)
			if age_off <= 0.0:
				continue
			var gt = min(age_off / _dur, 1.0)
			draw_circle(gh.offset, lerp(10.0, 2.0, gt),
						Color(1.0, 0.8, 0.2, (1.0 - gt) * 0.55))
		# Frecce velocità nella direzione del dash
		for ai in range(3):
			var off := dash_dir * float(ai) * 9.0 * t
			var a   := dash_dir * 8.0 * inv
			var perp := Vector2(-dash_dir.y, dash_dir.x) * 4.0 * inv
			draw_line(-off - perp, -off + a, Color(1.0, 0.9, 0.3, inv * 0.6), 1.5, true)
			draw_line(-off + perp, -off + a, Color(1.0, 0.9, 0.3, inv * 0.6), 1.5, true)

func _become_ally(duration: float) -> void:
	is_mind_controlled = true
	_mind_control_original_group = group
	apply_buff("mind_controlled", duration)


# ==============================================================
# READY
# ==============================================================
func _ready() -> void:
	randomize()
	bull_se = bullet_se.pick_random()
	if Global.wave >= 5 and randi() % 100 < 10: type = "mini_boss"

	if type == "enemy":      scale = Vector2(1,1)
	elif type == "mini_boss":scale = Vector2(2,2)

	var textures = [
		load("res://Gres/Assets/UI/Bullets/Bullet_1.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_2.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_3.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_5.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_6.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_7.png"),
		load("res://Gres/Assets/UI/Bullets/Bullet_8.png"),
	]
	Global.enemy_type  = type
	bullet_texture     = textures.pick_random()
	current_skill      = current_skill.pick_random()
	skills_timer       = randi_range(10, 15)
	$SkillAnimTimer.wait_time = max(skills_timer - skill_anim_offset, 0.1)
	$SkillAnimTimer.start()
	$SkillTimer.wait_time = skills_timer
	$SkillTimer.start()
	can_dodge = true; can_follow = true; can_move = true; can_shoot = true; can_rotate = true

	_apply_random_skin()

	if Global.mode == "dungeon":
		match Global.dificulty:
			"easy":   max_hp = randi_range(10,40);  originalspeed = float(randi_range(100,110)); speed = originalspeed
			"normal": max_hp = randi_range(60,100); originalspeed = randi_range(120,140);       speed = originalspeed
			"hard":   max_hp = randi_range(100,400);originalspeed = randi_range(160,220);       speed = originalspeed
		if Global.campaign_goal_type != "time":
			group = "player"; GlobalTweens.deactivate($FireArea/BaseFireColl); GlobalTweens.activate($FireArea/PlayerFireColl)
		elif Global.campaign_goal_type == "time":
			group = "base";   GlobalTweens.deactivate($FireArea/PlayerFireColl); GlobalTweens.activate($FireArea/BaseFireColl)

	var target_group = group if group != null and group != "" else "player"
	player = get_tree().get_first_node_in_group(target_group)
	if player == null: queue_free(); return

	if Global.mode == "endless":
		var wave := Global.wave
		var is_aggressive := (wave % 5 == 0)
		if type == "enemy":
			max_hp       = clamp(5 + wave * 10, 10, 600)
			originalspeed= clamp(150 + wave * 1.2, 100, 300)
			fire_rate    = clamp(1.0 - wave * 0.02, 0.2, 1.2)
			dodge_chance = clamp(30 + wave * 2, 10, 70)
		elif type == "mini_boss":
			max_hp       = clamp(150 + wave * 10, 100, 2000)
			originalspeed= clamp(140 + wave * 2.0, 120, 400)
			fire_rate    = clamp(0.7 - wave * 0.04, 0.15, 0.6)
			dodge_chance = clamp(20 + wave * 3, 20, 85)
		if is_aggressive:
			if type == "enemy":
				max_hp += 100; originalspeed += 20
				fire_rate = max(fire_rate - 0.15, 0.15); dodge_chance = min(dodge_chance + 10, 90)
			elif type == "mini_boss":
				max_hp += 250; originalspeed += 40
				fire_rate = max(fire_rate - 0.25, 0.10); dodge_chance = min(dodge_chance + 20, 95)
		speed = originalspeed; hp = max_hp
		fire_timer.wait_time = fire_rate
		fire_timer.start()

	# FX spawn + aura permanente
	_fx_spawn()
	var perm := _PermanentAura.new()
	perm.enemy_ref = self
	add_child(perm)

	if not bonus_scene:
			bonus_scene = preload("res://Gres/Scenes/Bonus/bonus_drop.tscn")
		
	# Configura il timer
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func _spawn_bonus() -> void:
	# Create a bonus instance
	var bonus_instance = bonus_scene.instantiate()
	
	# Calculate random position in the spawn area
	var random_x = randf_range(-spawn_area.x/2, spawn_area.x/2)
	var random_y = randf_range(-spawn_area.y/2, spawn_area.y/2)
	var spawn_position = Vector2(random_x, random_y)
	
	bonus_instance.position = spawn_position
	
	# Add the bonus to the scene using call_deferred to avoid physics flushing issues
	call_deferred("add_child", bonus_instance)

func _on_spawn_timer_timeout():
	pass

func _apply_random_skin() -> void:
	var path_body: String; var path_wings: String; var path_prop: String
	if type == "enemy":
		path_body  = "res://Gres/Assets/Enemy/part/body/e_body_%s.png"   % randi_range(1, MAX_BODY)
		path_wings = "res://Gres/Assets/Enemy/part/wings/e_wings_%s.png" % randi_range(1, MAX_WINGS)
		path_prop  = "res://Gres/Assets/Enemy/part/prop/w_pro_%s.png"    % randi_range(1, MAX_PROP)
	elif type == "mini_boss":
		path_body  = "res://Gres/Assets/Enemy/part/MiniBoss/body/e_body_%s.png"   % randi_range(1, MAX_BODY_M)
		path_wings = "res://Gres/Assets/Enemy/part/MiniBoss/wings/e_wings_%s.png" % randi_range(1, MAX_WINGS_M)
		path_prop  = "res://Gres/Assets/Enemy/part/MiniBoss/prop/w_pro_%s.png"    % randi_range(1, MAX_PROP_M)
	else:
		return
	body_sprite.texture  = load(path_body)
	wings_sprite.texture = load(path_wings)
	prop_sprite.texture  = load(path_prop)
	var c = COLORS.pick_random()
	body_sprite.modulate = c; wings_sprite.modulate = c; prop_sprite.modulate = c
	_sprite_base_modulate = c   # salva colore originale per i ripristini


# ==============================================================
# PHYSICS PROCESS
# ==============================================================
func _physics_process(delta: float) -> void:
	if is_mind_controlled:
		# Se il target attuale non è più valido o non è un nemico, cercane un altro
		if not is_instance_valid(player) or not player.is_in_group("enemy"):
			_update_mind_control_target()
	
	if player == null: return
	
	_update_buffs(delta)

	if can_rotate and is_instance_valid(player):
		look_at(player.global_position)

	if GlobalStats.time_slow:
		match GlobalStats.time_slow_bonus:
			1: speed = 70
			2: speed = 50
			3: speed = 20
	else:
		if not has_buff("slowed") and not has_buff("frozen"):
			speed = originalspeed

	if Global.player_dead and not is_mind_controlled and not is_revived:
		can_dodge = false; can_follow = false; can_move = true; can_shoot = false; can_rotate = true
		queue_free(); return

	if on_shoot_area and fire_timer.is_stopped(): fire_timer.start()
	if is_using_skill: move_and_slide(); return

	if is_dodging:
		velocity = dodge_vector
	elif can_follow and is_instance_valid(player):
		velocity = (player.global_position - global_position).normalized() * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()


# ==============================================================
# FIRE TIMER
# ==============================================================
func _on_FireTimer_timeout() -> void:
	if not on_shoot_area: return
	$GunSE.volume_db = Global.effects_volume / 2
	$GunSE.stream    = load(bull_se)
	$GunSE.playing   = true
	
	var bullet_scene: PackedScene
	if not is_mind_controlled:
		bullet_scene = load("res://Gres/Scenes/enemies/bullets/enemy_bullet_1.tscn")
	else:
		bullet_scene = load("res://Gres/Scenes/weapons/bullet/player_bullet.tscn")
	
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = canon.global_position
	
	# Calcola la direzione verso il player
	if is_instance_valid(player):
		var direction = (player.global_position - canon.global_position).normalized()
		# Per il mind-controlled, il proiettile deve andare verso il player (nemico ora)
		# ma usando il comportamento del player bullet
		if is_mind_controlled:
			# Ruota il proiettile verso il player
			bullet.rotation = direction.angle()
			# Se il player bullet usa direction per muoversi
			if "direction" in bullet:
				bullet.direction = direction
			# Se invece usa rotation per la direzione
			elif bullet.has_method("set_direction"):
				bullet.set_direction(direction)
		else:
			# Comportamento normale enemy bullet
			bullet.rotation = canon.global_rotation
			if bullet.has_method("set_direction"):
				bullet.set_direction(direction)
			elif "direction" in bullet:
				bullet.direction = direction
	else:
		return
		
	# Applica texture solo se esiste il metodo
	if bullet.has_method("set_texture"):
		bullet.set_texture(bullet_texture)
	
	# Gestisci il gruppo
	if is_mind_controlled:
		bullet.add_to_group("p_bullet")
	
	fire_timer.start()

# ==============================================================
# SKILL
# ==============================================================
func use_skill(skill_name: String) -> void:
	if not SKILL_PATHS.has(skill_name): push_warning("Skill non trovata: %s" % skill_name); return
	var skill = load(SKILL_PATHS[skill_name]).new(self)
	add_child(skill); skill.activate()

func _on_skill_timer_timeout() -> void:
	use_skill(current_skill)
	if current_skill == "magnet_pull":
		$PullFX.show(); $PullFX/loop.play("loop")
		var t := Timer.new(); t.wait_time = 5.6; t.one_shot = true; add_child(t)
		t.timeout.connect(Callable(self, "_magnet_end")); t.start()
	skills_timer = randi_range(10, 15)
	$SkillAnimTimer.wait_time = max(skills_timer - skill_anim_offset, 0.1)
	$SkillAnimTimer.start()
	$SkillTimer.wait_time = skills_timer
	$SkillTimer.start()

func _on_skill_anim_timer_timeout() -> void:
	# Spawna l'indicatore windup prima dell'attivazione
	_spawn_windup(current_skill)

	match current_skill:
		"dash_attack":
			# Tremolio pre-dash + bagliore giallo-arancio
			_fx_micro_shake(0.5)
			var tw = create_tween()
			tw.tween_property(self, "modulate", Color(1.5, 0.8, 0.0, 1.0), 0.18)
			tw.tween_property(self, "modulate", _sprite_base_modulate, 0.8)
			# FX animazione nodo $DashAttackFX (come originale)
			if has_node("DashAttackFX"):
				var s_tween = create_tween()
				s_tween.tween_property($DashAttackFX, "modulate:a", 1.0, 4).set_ease(Tween.EASE_IN)
				s_tween.tween_property($DashAttackFX, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_OUT)
				await s_tween.finished
			else:
				await get_tree().create_timer(4.9).timeout

		"shield":
			# Scudo: bagliore blu draw — scala mai toccata
			var tw = create_tween().set_parallel(true)
			tw.tween_property(self, "modulate", Color(0.5, 0.8, 1.5, 1.0), 0.2)
			tw.tween_property(self, "modulate", _sprite_base_modulate, 0.5).set_delay(0.2)
			var sh_fx := _ShieldActivateFX.new()
			add_child(sh_fx)
			is_shielded = true
			$SkillShield.wait_time = randi_range(4.0, 8.0)
			$SkillShield.start()
			if has_node("ShieldFX"):
				var s_tween = create_tween()
				s_tween.tween_property($ShieldFX, "visible", true,  0.1).set_ease(Tween.EASE_IN)
				s_tween.tween_property($ShieldFX, "visible", false, 0.15).set_ease(Tween.EASE_OUT)
				s_tween.tween_property($ShieldFX, "visible", true,  0.1).set_ease(Tween.EASE_IN)
				await s_tween.finished

		"mitra":
			# Rotazione rapida pre-raffica + flash giallo
			var tw = create_tween()
			tw.tween_property(self, "rotation_degrees", rotation_degrees + 18.0, 0.07).as_relative()
			tw.tween_property(self, "rotation_degrees", rotation_degrees - 18.0, 0.07).as_relative()
			tw.tween_property(self, "rotation_degrees", rotation_degrees,         0.1)
			tw.tween_property(self, "modulate", Color(1.6, 1.5, 0.2, 1.0), 0.05)
			tw.tween_property(self, "modulate", _sprite_base_modulate, 0.35)
			shoot_mitra()

		"invisible":
			# Dissolve smooth
			$SkillInvisble.start()
			var tw = create_tween()
			tw.tween_property(self, "modulate:a", 0.08, 0.4).set_trans(Tween.TRANS_QUAD)
			await tw.finished

		"magnet_pull":
			# Pulsazione viola + spirale psichica
			_fx_ring_burst(Color(0.8, 0.2, 1.0, 0.55), 80.0, 0.4)
			var tw = create_tween().set_loops(2)
			tw.tween_property(self, "modulate", Color(0.9, 0.3, 1.5, 1.0), 0.2)
			tw.tween_property(self, "modulate", _sprite_base_modulate, 0.2)

		"orbital":
			# Rotazione su se stesso + ring blu
			_fx_ring_burst(Color(0.4, 0.7, 1.5, 0.6), 90.0, 0.4)
			var tw = create_tween().set_parallel(true)
			tw.tween_property(self, "rotation_degrees", rotation_degrees + 360.0, 0.55).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(self, "modulate", Color(0.4, 0.7, 1.5, 1.0), 0.15)
			tw.tween_property(self, "modulate", _sprite_base_modulate, 0.5).set_delay(0.15)


# ==============================================================
# TAKE DAMAGE
# ==============================================================
func take_damage(amount: float, source = null) -> void:
	if source != null and source is PlayerBullet and Global.is_deflected:
		Global.is_deflected = false
		if source.projectile_type == "blood_nexus_main":
			create_blood_link_network()
	if is_shielded or !not_dead: return
	var actual := amount
	if has_buff("haunted"): actual *= 1.20
	# Sovereign decree: x3 danno
	if is_instance_valid(Global.player) and Global.player.has_meta("sovereign_active"):
		actual *= 3.0
	var effect = load("res://Gres/Scenes/Effects/expl_p.tscn").instantiate()
	get_parent().add_child(effect); effect.global_position = global_position
	hp -= actual
	if is_blood_linked: propagate_blood_link_damage(actual)
	Global.update_mission_progress("damage_done", actual)
	flash_damage(actual)   # passa amount per squash proporzionale
	spawn_damage_popup(actual)
	if hp <= 0 and not_dead: not_dead = false; die()

func spawn_damage_popup(amount: int, crit: bool = false) -> void:
	var lbl: Label = preload("res://Gres/Scenes/UI/damage_label.tscn").instantiate()
	get_tree().current_scene.add_child(lbl)
	lbl.show_damage(amount, global_position, crit)
	

# ==============================================================
# MORTE
# ==============================================================
func die() -> void:
	if randi() % 100 < 10:
		_spawn_bonus()
		
	Global.update_mission_progress("kill_common", 1)
	if type == "mini_boss" and randi() % 100 < 10:
		_spawn_chest()
		Global.update_mission_progress("expert_hunter_1", 1)
		Global.update_mission_progress("expert_hunter_2", 1)
		Global.update_mission_progress("expert_hunter_3", 1)
	if type == "mini_boss":
		GlobalStats.kill_mini_boss_lvl   += 1
		GlobalStats.kill_mini_boss_total += 1

	if type != "boss":
		if Global.mode == "endless":
			if randi() % 100 < GlobalStats.drop_percent:
				var gold_gain := 0
				if   Global.wave < 20: gold_gain = randi_range(3, 8)
				elif Global.wave < 40: gold_gain = randi_range(8, 16)
				elif Global.wave < 60: gold_gain = randi_range(16, 24)
				else:                  gold_gain = randi_range(24, 32)
				if GlobalStats.double_gold_drop and randi() % 100 < GlobalStats.d_g_drop_percent:
					gold_gain *= 2
				GlobalStats.gold += gold_gain
				Global.update_mission_progress("rich_game_1", gold_gain)
				Global.update_mission_progress("rich_game_2", gold_gain)
				Global.update_mission_progress("rich_game_3", gold_gain)
				GlobalStats.save_data_stats()
			if Global.wave >= 20 and randi() % 100 < GlobalStats.craft_drop:
				var s = shards.pick_random()
				match s:
					"void_shard":  GlobalStats.void_shard  += 1
					"magma_shard": GlobalStats.magma_shard += 1
					"ice_shard":   GlobalStats.ice_shard   += 1
					"light_shard": GlobalStats.light_shard += 1
				GlobalStats.save_data_stats()
		elif Global.mode == "dungeon":
			var gold_gain := 0
			match Global.dificulty:
				"easy":
					gold_gain = randi_range(5, 20); GlobalStats.save_data_stats()
				"normal":
					if randi() % 100 < GlobalStats.drop_percent:
						gold_gain = randi_range(15,30) * (2 if GlobalStats.double_gold_drop and randi()%100 < GlobalStats.d_g_drop_percent else 1)
						GlobalStats.save_data_stats()
				"hard":
					if randi() % 100 < GlobalStats.drop_percent:
						gold_gain = randi_range(30,60) * (2 if GlobalStats.double_gold_drop and randi()%100 < GlobalStats.d_g_drop_percent else 1)
						GlobalStats.save_data_stats()
			GlobalStats.gold += gold_gain; GlobalStats.save_data_stats()
			if randi() % 100 < GlobalStats.craft_drop:
				var s = shards.pick_random()
				var amount := 1
				if Global.dificulty == "normal": amount = randi_range(1,2)
				elif Global.dificulty == "hard":  amount = randi_range(2,4)
				match s:
					"void_shard":  GlobalStats.void_shard  += amount
					"magma_shard": GlobalStats.magma_shard += amount
					"ice_shard":   GlobalStats.ice_shard   += amount
					"light_shard": GlobalStats.light_shard += amount
				GlobalStats.save_data_stats()
		var effect = load("res://Gres/Scenes/Effects/value_drop.tscn").instantiate()
		get_parent().call_deferred("add_child", effect)
		effect.global_position = global_position

	if can_emit: can_emit = false; emit_signal("enemy_died")
	can_dodge = false; can_follow = false; can_move = false; can_rotate = false; can_shoot = false
	_remove_aura()
	_remove_windup()

	# FX morte epica
	_fx_death_explosion()

	# Modulate fade out prima della death animation
	if is_mind_controlled:
		_fx_tween_modulate(Color(0.9, 0.0, 1.0, 0.0), 0.28)
	elif is_revived:
		_fx_tween_modulate(Color(0.0, 1.0, 0.3, 0.0), 0.28)
	else:
		_fx_tween_modulate(Color(modulate.r, modulate.g, modulate.b, 0.0), 0.35)

	$dead.play("dead")


# ==============================================================
# BLOOD LINK
# ==============================================================
func create_blood_link_network() -> void:
	if is_blood_linked: return
	var enemies := get_tree().get_nodes_in_group("enemy")
	var linked  := []
	for e in enemies:
		if e != self and e.global_position.distance_to(global_position) <= 600:
			linked.append(e)
			if linked.size() >= 4: break
	linked.append(self)
	for e in linked: e.blood_linked_enemies = linked; e.is_blood_linked = true

func propagate_blood_link_damage(amount: float) -> void:
	var shared := amount * 0.5
	for e in blood_linked_enemies:
		if is_instance_valid(e) and e != self and e.not_dead: e.receive_blood_damage(shared)

func receive_blood_damage(amount: float) -> void:
	hp -= amount; flash_damage(amount); spawn_damage_popup(amount)
	if hp <= 0 and not_dead: not_dead = false; die()

# ==============================================================
# DODGE
# ==============================================================
func _on_DodgeArea_body_entered(body) -> void:
	if not can_dodge or is_dodging: return
	if not body.is_in_group("p_bullet"): return
	if _no_dodge_timer > 0: return
	if randi() % 100 < dodge_chance: start_dodge()

func start_dodge() -> void:
	is_dodging = true
	dodge_vector = get_random_dodge_direction() * (speed + 100)
	# FX draw: scia velocità durante il dodge — scala mai toccata
	var dg := _DodgeDashFX.new()
	dg.dash_dir = dodge_vector.normalized()
	add_child(dg)
	await get_tree().create_timer(dodge_duration).timeout
	is_dodging = false

func get_random_dodge_direction() -> Vector2:
	var dirs = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
				Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1)]
	return dirs[randi() % dirs.size()].normalized()

func _on_dodge_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_bullet") and randi() % 100 < 95: start_dodge()


# ==============================================================
# SHOOT MITRA
# ==============================================================
func shoot_mitra() -> void:
	if not can_mitra: return
	can_mitra = false; $SkillMitra.start()
	for _i in range(6):
		_spawn_bullet()
		await get_tree().create_timer(0.1).timeout
	fire_timer.start()

func _spawn_bullet() -> void:
	var bullet_scene = load("res://Gres/Scenes/enemies/bullets/enemy_bullet_1.tscn")
	if type == "enemy":
		_spawn_from_point(canon.global_position, bullet_scene)
	elif type == "mini_boss":
		_spawn_from_point($BulletSpawnPM1.global_position, bullet_scene)
		_spawn_from_point($BulletSpawnPM2.global_position, bullet_scene)

func _spawn_from_point(spawn_pos: Vector2, bullet_scene: PackedScene) -> void:
	if not is_instance_valid(player):
		return   # esce senza generare proiettili se il target non esiste più
	var bullet := bullet_scene.instantiate()
	get_parent().add_child(bullet)
	var offset := Vector2(randf_range(-6, 6), randf_range(-6, 6))
	bullet.global_position = spawn_pos + offset
	var dir = (player.global_position - spawn_pos).normalized().rotated(deg_to_rad(randf_range(-25, 25)))
	bullet.rotation = dir.angle()
	bullet.set_direction(dir)
	bullet.set_texture(bullet_texture)
	if is_mind_controlled: bullet.group = "p_bullet"

func die_enemy_explosion() -> void:
	# ==================================================
	# Versione legacy mantenuta per compatibilità.
	# La nuova logica è in _fx_death_explosion() + die().
	# ==================================================
	can_move = false; can_shoot = false
	var parts := [$BodySprite, $WingsSprite, $PropSprite]
	var tween := create_tween()
	for part in parts:
		var angle := randf_range(-PI, PI)
		var dir   := Vector2(cos(angle), sin(angle))
		tween.tween_property(part, "rotation", angle, 0.5)
		tween.tween_property(part, "position", part.position + dir * randf_range(20,80), 0.5)
		tween.tween_property(part, "scale", Vector2.ZERO, 0.5)
	tween.tween_callback(queue_free)


# ==============================================================
# STOP AREA / FIRE AREA
# ==============================================================
func _on_stop_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(group): can_move = false; can_follow = false

func _on_stop_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(group): can_move = true; can_follow = true

func _on_fire_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(group): can_shoot = true; on_shoot_area = true

func _on_fire_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(group): can_shoot = false; on_shoot_area = false


# ==============================================================
# TIMER CALLBACKS
# ==============================================================
func _on_skill_shield_timeout() -> void:
	is_shielded = false
	_remove_aura()
	if has_node("ShieldFX"):
		var tw = create_tween()
		tw.tween_property($ShieldFX, "visible", false, 0.1).set_ease(Tween.EASE_IN)
		tw.tween_property($ShieldFX, "visible", true,  0.15).set_ease(Tween.EASE_OUT)
		tw.tween_property($ShieldFX, "visible", false, 0.1).set_ease(Tween.EASE_IN)
		await tw.finished
	$SkillTimer.wait_time = skills_timer; $SkillTimer.start()

func _on_skill_mitra_timeout() -> void:   can_mitra = true

func _on_skill_invisble_timeout() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_IN)
	await tw.finished

func _on_dead_animation_finished(anim_name: StringName) -> void: queue_free()

func _spawn_chest() -> void:
	if chest_scenes.is_empty(): return
	var chest: Node2D = chest_scenes.pick_random().instantiate()
	if not chest_spawn_points.is_empty():
		chest.global_position = chest_spawn_points.pick_random().global_position
	else:
		var angle   := randf_range(0, TAU)
		var distance:= randf_range(200, 500)
		chest.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	get_parent().call_deferred("add_child", chest)

func _magnet_end() -> void:
	$PullFX.hide(); $PullFX/loop.stop()

func _on_zombie_dead_timeout() -> void:
	hp -= max_hp * 0.1
	hp = clamp(hp, 0, max_hp)  # mantieni hp tra 0 e max_hp
	can_mind = true
	if hp <= 0:
		die()
