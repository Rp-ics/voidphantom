extends CharacterBody2D

signal base_destroyed
signal base_damaged(current_hp: int, max_hp: int)

# =====================
# CONFIGURAZIONE BASE
# =====================
@export var damage_per_hit: int = 1
@export var max_shield: int = 100
@export var spawn_enemy_scene: PackedScene               # Scena del nemico da spawnare
@export var spawn_interval: float = 4.0                  # Tempo tra uno spawn e l’altro
@export var max_enemies_from_base: int = 5               # Quanti nemici può tenere in campo
@export var spawn_distance: float = 150.0                # Distanza minima dal centro della base
@export var max_bases: int = 5
# Se true -> il level script gestisce gli spawn (Assault Mode). Base non spawnare.
@export var controlled_by_level: bool = false
@export var can_spawn: bool = false

var current_damaged: int = 0
var is_destroyed := false
var active_enemies: Array = []

@onready var hp_bar = $HPB
@onready var sprite = $Sprite
@onready var effect_scene = preload("res://Gres/Scenes/Effects/expl_p.tscn")
@onready var spawn_timer: Timer = $SpawnTime

func _ready() -> void:
	add_to_group("e_base")
	if not controlled_by_level:
		spawn_timer.wait_time = spawn_interval
		spawn_timer.start()

func _process(_delta: float) -> void:
	hp_bar.max_value = max_shield
	hp_bar.value = current_damaged
	_update_sprite_frame()

# =====================
# GESTIONE DANNI
# =====================
func _update_sprite_frame() -> void:
	if not sprite:
		return
	
	var percent = clamp(float(current_damaged) / max_shield, 0.0, 1.0)
	var total_frames := 5  # da 0 a 4
	var frame_index := int(round(percent * (total_frames - 1)))
	sprite.frame = frame_index

func damage():
	current_damaged += damage_per_hit
	current_damaged = clamp(current_damaged, 0, max_shield)

	# Effetto visivo impatto
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)

	var dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var dist = randf_range(20.0, 50.0)
	effect.global_position = global_position + dir * dist
	effect.scale = Vector2.ONE * randf_range(0.8, 1.5)

	# Notifica UI / level
	emit_signal("base_damaged", current_damaged, max_shield)

	if current_damaged >= max_shield and not is_destroyed:
		_on_base_destroyed()

func _on_base_destroyed() -> void:
	is_destroyed = true

	# Rimuovi dai gruppi
	self.remove_from_group("e_base")

	# Ferma il timer di spawn
	if spawn_timer:
		spawn_timer.stop()

	# Effetto visivo (se usi GlobalTweens)
	if Engine.has_singleton("GlobalTweens"):
		GlobalTweens.blink($".")  # mantieni come prima

	# Notifica locale
	emit_signal("base_destroyed")

	Global.base_destroyed += 1

	if Global.base_destroyed >= max_bases:
		Global.assault_done = true
# =====================
# SISTEMA DI SPAWN NEMICI (LOCALE)
# =====================
func _on_spawn_timer_timeout() -> void:
	if is_destroyed or controlled_by_level or !can_spawn:
		return
	
	# Pulisci lista da nemici morti (queue_free)
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e) and e.is_inside_tree())

	# Se raggiunto il limite massimo, non spawnare
	if active_enemies.size() >= max_enemies_from_base:
		return
	
	if not spawn_enemy_scene:
		return
	
	var enemy = spawn_enemy_scene.instantiate()
	get_parent().add_child(enemy)

	# Posizione di spawn casuale attorno alla base
	var angle = randf_range(0.0, TAU)
	var offset = Vector2(cos(angle), sin(angle)) * randf_range(spawn_distance, spawn_distance + 50)
	enemy.global_position = global_position + offset

	# assegna player come target se il nemico ha la proprietà 'player'
	var p = get_tree().get_first_node_in_group("player")
	if p and "player" in enemy:
		enemy.player = p
		
	# registra e connetti per rimuovere dall'array quando muore
	active_enemies.append(enemy)
	if enemy.has_signal("enemy_died"):
		enemy.connect("enemy_died", Callable(self, "_on_child_enemy_died").bind(enemy))
	else:
		enemy.connect("tree_exited", Callable(self, "_on_child_enemy_died").bind(enemy))

func _on_child_enemy_died(enemy):
	# safety: rimuovi qualsiasi riferimento
	active_enemies.erase(enemy)


func _on_focus_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		can_spawn = true


func _on_focus_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		can_spawn = false
