extends CharacterBody2D
# ================================================================
# PlayerPvP — Nave giocatore per modalità PvP
# Il nome del nodo DEVE essere il peer_id come stringa es. "1", "2"
# ================================================================
"""
signal hp_changed(new_hp: float, max_hp: float)
signal player_died(peer_id: int)

const PVP_MAX_HP:            float = 300.0
const PVP_MOVE_SPEED:        float = 220.0
const PVP_DASH_SPEED:        float = 520.0
const PVP_DASH_DURATION:     float = 0.18
const PVP_DASH_COOLDOWN:     float = 1.2
const PVP_STAMINA_MAX:       float = 100.0
const PVP_STAMINA_DASH_COST: float = 25.0
const INVINCIBILITY_TIME:    float = 0.4

var hp:             float   = PVP_MAX_HP
var stamina:        float   = PVP_STAMINA_MAX
var is_dead:        bool    = false
var can_move:       bool    = true
var can_shoot:      bool    = true
var can_dash:       bool    = true
var can_be_damaged: bool    = true
var peer_id:        int     = 0
var player_name:    String  = ""
var current_weapon: Dictionary = {}

var input_dir:      Vector2 = Vector2.ZERO
var last_input_dir: Vector2 = Vector2.DOWN
var _dash_timer:    float   = 0.0
var _dash_cd_timer: float   = 0.0
var _shoot_cooldown:float   = 0.0
var _inv_timer:     float   = 0.0
var _is_invincible: bool    = false

@onready var sprite:       Sprite2D    = $Sprite2D
@onready var canon_point:  Marker2D    = $CanonPoint
@onready var hud_local:    Control     = $HUD_Local
@onready var hp_bar:       ProgressBar = $HUD_Local/HPBar
@onready var stamina_bar:  ProgressBar = $HUD_Local/StaminaBar
@onready var name_label:   Label       = $HUD_Local/NameLabel

const BULLET_SCENE := "res://Multiplayer/Scenes/BulletPvP.tscn"

func _ready() -> void:
	peer_id = name.to_int()
	set_multiplayer_authority(peer_id)
	hp      = PVP_MAX_HP
	stamina = PVP_STAMINA_MAX
	_setup_hud()
	_start_stamina_regen()
	hud_local.visible = is_multiplayer_authority()
	print("[PlayerPvP] Ready — peer_id: ", peer_id, " authority: ", is_multiplayer_authority())

func _setup_hud() -> void:
	if is_instance_valid(hp_bar):
		hp_bar.max_value = PVP_MAX_HP
		hp_bar.value     = hp
	if is_instance_valid(stamina_bar):
		stamina_bar.max_value = PVP_STAMINA_MAX
		stamina_bar.value     = stamina
	if is_instance_valid(name_label):
		name_label.text = player_name

func _start_stamina_regen() -> void:
	var t = Timer.new()
	t.wait_time = 1.5
	t.autostart = true
	t.timeout.connect(_regen_stamina)
	add_child(t)

func _regen_stamina() -> void:
	if not is_multiplayer_authority():
		return
	stamina = min(stamina + 12.0, PVP_STAMINA_MAX)
	_update_hud()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	if is_dead:
		return
	_handle_input()
	if can_move:
		_process_movement()
	if can_dash:
		_process_dash(delta)
	_rotate_towards_mouse()
	_process_shoot(delta)
	_process_invincibility(delta)
	_update_hud()

func _handle_input() -> void:
	input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down")  - Input.get_action_strength("move_up")
	).normalized()
	if input_dir != Vector2.ZERO:
		last_input_dir = input_dir

func _process_movement() -> void:
	var dir = last_input_dir if _dash_timer > 0.0 else input_dir
	var spd = PVP_DASH_SPEED  if _dash_timer > 0.0 else PVP_MOVE_SPEED
	velocity = dir * spd
	move_and_slide()

func _process_dash(delta: float) -> void:
	if _dash_timer    > 0.0: _dash_timer    -= delta
	if _dash_cd_timer > 0.0: _dash_cd_timer -= delta
	if Input.is_action_just_pressed("dash") \
	and _dash_timer    <= 0.0 \
	and _dash_cd_timer <= 0.0 \
	and stamina >= PVP_STAMINA_DASH_COST:
		stamina       -= PVP_STAMINA_DASH_COST
		_dash_timer    = PVP_DASH_DURATION
		_dash_cd_timer = PVP_DASH_COOLDOWN
		_fx_dash()

func _fx_dash() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.3, 0.05)
	tw.tween_property(self, "modulate:a", 1.0, 0.1)

func _rotate_towards_mouse() -> void:
	look_at(get_global_mouse_position())

func _process_shoot(delta: float) -> void:
	if _shoot_cooldown > 0.0:
		_shoot_cooldown -= delta
		return
	if not can_shoot or current_weapon.is_empty():
		return
	if not Input.is_action_pressed("shoot"):
		return
	_shoot_cooldown = current_weapon.get("fire_rate", 0.25)
	var dir = (get_global_mouse_position() - canon_point.global_position).normalized()
	_spawn_bullet.rpc(canon_point.global_position, dir)

@rpc("call_local", "reliable")
func _spawn_bullet(spawn_pos: Vector2, direction: Vector2) -> void:
	if not ResourceLoader.exists(BULLET_SCENE):
		push_error("[PlayerPvP] BulletPvP.tscn not found!")
		return
	var bullet = load(BULLET_SCENE).instantiate()
	bullet.global_position  = spawn_pos
	bullet.direction        = direction
	bullet.damage           = current_weapon.get("damage",          20.0)
	bullet.speed            = current_weapon.get("bullet_speed",   700.0)
	bullet.owner_peer_id    = peer_id
	bullet.projectile_type  = current_weapon.get("projectile_type", "line")
	get_parent().add_child(bullet)

@rpc("any_peer", "reliable")
func take_damage_rpc(amount: float, attacker_peer_id: int) -> void:
	if not is_multiplayer_authority():
		return
	if is_dead or _is_invincible or not can_be_damaged:
		return
	hp             = max(hp - amount, 0.0)
	_is_invincible = true
	_inv_timer     = INVINCIBILITY_TIME
	emit_signal("hp_changed", hp, PVP_MAX_HP)
	GlobalPvP.apply_damage(peer_id, amount, attacker_peer_id)
	_fx_hurt()
	_update_hud()
	if hp <= 0.0 and not is_dead:
		_die.rpc(attacker_peer_id)

func _process_invincibility(delta: float) -> void:
	if _is_invincible:
		_inv_timer -= delta
		if _inv_timer <= 0.0:
			_is_invincible = false
			modulate.a     = 1.0

@rpc("call_local", "reliable")
func _die(killer_peer_id: int) -> void:
	if is_dead:
		return
	is_dead   = true
	can_move  = false
	can_shoot = false
	can_dash  = false
	print("[PlayerPvP] Player ", peer_id, " died. Killer: ", killer_peer_id)
	emit_signal("player_died", peer_id)
	_fx_death()
	await get_tree().create_timer(1.2).timeout
	visible = false

func respawn(spawn_pos: Vector2) -> void:
	if not is_multiplayer_authority():
		return
	_respawn_rpc.rpc(spawn_pos)

@rpc("call_local", "reliable")
func _respawn_rpc(spawn_pos: Vector2) -> void:
	hp              = PVP_MAX_HP
	stamina         = PVP_STAMINA_MAX
	is_dead         = false
	can_move        = true
	can_shoot       = true
	can_dash        = true
	_is_invincible  = false
	_inv_timer      = 0.0
	global_position = spawn_pos
	visible         = true
	modulate        = Color.WHITE
	_update_hud()

func _update_hud() -> void:
	if not is_multiplayer_authority():
		return
	if is_instance_valid(hp_bar):
		hp_bar.value = hp
	if is_instance_valid(stamina_bar):
		stamina_bar.value = stamina

func _fx_hurt() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(1.5, 0.2, 0.2, 1.0), 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)

func _fx_death() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)
	tw.tween_property(self, "scale",      Vector2(2.0, 2.0), 0.8)

func set_weapon(weapon_data: Dictionary) -> void:
	current_weapon = weapon_data
	print("[PlayerPvP] Weapon set: ", weapon_data.get("name", "unknown"))

func get_hp_percent() -> float:
	return hp / PVP_MAX_HP

func is_alive() -> bool:
	return not is_dead
"""
