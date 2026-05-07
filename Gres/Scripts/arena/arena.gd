extends Node

# =============================================
# REGION: Configurazione esportata
# =============================================

# ---------- ONDATE ----------
@export var wave_delay: float = 4.0
@export var min_spawn_distance: float = 300.0
@export var max_spawn_distance: float = 700.0
@export var max_enemies_on_field_base: int = 50

# ---------- CHEST ----------
@export var chest_scenes: Array[PackedScene]
@export var chest_spawn_points: Array[Node2D]

# ---------- SPAWN NEMICI ----------
@export var enemy_spawn_points: Array[Node2D] = []

# ---------- BOSS ----------
## Scene dei boss tra cui scegliere casualmente
@export var boss_scenes: Array[PackedScene] = []
## Punti fissi di spawn per i boss (opzionale)
@export var boss_spawn_points: Array[Node2D] = []
## Intervallo minimo di ondate tra un boss e l'altro
@export var boss_wave_interval_min: int = 7
## Intervallo massimo di ondate tra un boss e l'altro
@export var boss_wave_interval_max: int = 10

# =============================================
# REGION: Stato interno
# =============================================

var target_enemies: int = 0
var enemies_spawned: int = 0
var killed_enemies: int = 0
var current_enemies: int = 0

var can_spawn: bool = false
var spawn_rate: float = 2.0
var max_enemies_on_field: int = 50
var can_rew: bool = true

# --- Boss ---
var next_boss_wave: int = 0          # ondata in cui apparirà il prossimo boss
var boss_wave_active: bool = false   # true se l'ondata corrente è una bossfight
var boss_alive: bool = false
var boss_dead: bool = false

# =============================================
# REGION: Nodi
# =============================================
@onready var enemy_container = $Gameplay/EnemyContainer
@onready var player = $Player
@onready var wave_info_label = $UI/WaveManager/WaveInfo
@onready var spawn_info_label = $UI/WaveManager/SpawnInfo
@onready var kill_info_label = $UI/WaveManager/KillInfo

# =============================================
# REGION: Ready
# =============================================
func _ready() -> void:
	Global.mode = "endless"
	# Prima ondata boss dopo 7-10 ondate (dalla 0)
	next_boss_wave = randi_range(boss_wave_interval_min, boss_wave_interval_max)
	start_wave()

# =============================================
# REGION: Gestione ondata
# =============================================
func start_wave() -> void:
	_show_wave_text_sequence("[center]==== WAVE %d START ====" % Global.wave, Color.WHITE)
	if Global.wave > GlobalStats.max_wave:
		GlobalStats.max_wave = Global.wave

	# Record personale
	if Global.wave > GlobalStats.max_game_wave:
		GlobalStats.max_game_wave = Global.wave

	if Global.wave >= GlobalStats.max_wave:
		Global.update_mission_progress("resist_1", 1)
		Global.update_mission_progress("resist_2", 1)
		Global.update_mission_progress("resist_3", 1)
		if GlobalStats.damage_rec_lvl == 0:
			Global.update_mission_progress("perfect_waves_1", 1)
			Global.update_mission_progress("perfect_waves_2", 1)
			Global.update_mission_progress("perfect_waves_3", 1)

	# Reset contatori
	killed_enemies = 0
	current_enemies = 0
	enemies_spawned = 0

	# --- Gestione Bossfight ---
	if Global.wave == next_boss_wave:
		_start_boss_wave()
		return

	# --- Ondata normale ---
	boss_wave_active = false
	target_enemies = 10 + int(Global.wave * 3.5)
	spawn_rate = clamp(2.0 - (Global.wave * 0.05), 0.4, 2.0)

	if Global.wave < 5:
		max_enemies_on_field = max_enemies_on_field_base
	else:
		max_enemies_on_field = clamp(50 + Global.wave * 2, 50, 120)

	# Achievement "Ascent of the Unbroken"
	if Global.wave == 6 and GlobalStats.damage_rec_lvl < 20:
		GlobalSteamScript._unlock_achievement("Ascent of the Unbroken")

	can_spawn = true
	await spawn_enemies_loop()
	GlobalStats.save_data_stats()

# =============================================
# REGION: Boss wave
# =============================================
func _start_boss_wave() -> void:
	boss_wave_active = true
	boss_dead = false
	can_spawn = false   # nessun nemico normale durante il boss

	await _show_wave_text_sequence("⚠ BOSS INCOMING ⚠", Color.RED)
	_spawn_boss()

	# La funzione non termina finché il boss non è morto
	# (end_wave sarà chiamata da _on_boss_killed)
	await _wait_for_boss_death()

func _spawn_boss() -> void:
	if boss_scenes.is_empty():
		push_error("Nessuna scena boss assegnata! L'ondata proseguirà come normale.")
		boss_wave_active = false
		start_wave()
		return

	var boss_scene: PackedScene = boss_scenes.pick_random()
	var boss: Node2D = boss_scene.instantiate()

	# Posizionamento
	if not boss_spawn_points.is_empty():
		var point: Node2D = boss_spawn_points.pick_random()
		boss.global_position = point.global_position
	else:
		boss.global_position = player.global_position + Vector2(500, 0).rotated(randf_range(0, TAU))

	enemy_container.add_child(boss)
	boss_alive = true
	current_enemies += 1

	# Connessione al segnale di morte del boss
	if boss.has_signal("died"):
		boss.died.connect(_on_boss_killed)
	elif boss.has_method("connect"):
		# Tenta un nome generico
		boss.connect("tree_exiting", Callable(self, "_on_boss_killed"), CONNECT_ONE_SHOT)
	else:
		push_warning("Il boss non espone un segnale 'died'. Il sistema potrebbe bloccarsi.")

func _on_boss_killed() -> void:
	if not boss_wave_active:
		return
	boss_alive = false
	boss_dead = true
	current_enemies -= 1
	end_wave()

func _wait_for_boss_death() -> void:
	# Ciclo di attesa non bloccante
	while not boss_dead:
		await get_tree().process_frame

# =============================================
# REGION: Loop di spawn nemici normali
# =============================================
func spawn_enemies_loop() -> void:
	while can_spawn and enemies_spawned < target_enemies:
		if current_enemies < max_enemies_on_field:
			var enemy = preload("res://Gres/Scenes/enemies/enemy.tscn").instantiate()
			enemy.global_position = get_spawn_position()
			enemy.connect("enemy_died", Callable(self, "_on_enemy_killed"))
			enemy_container.add_child(enemy)

			enemies_spawned += 1
			current_enemies += 1
			spawn_info_label.text = "Enemies spawned: %d / %d" % [enemies_spawned, target_enemies]

		await get_tree().create_timer(spawn_rate).timeout

# =============================================
# REGION: Posizione di spawn generica
# =============================================
func get_spawn_position() -> Vector2:
	if not enemy_spawn_points.is_empty():
		var point: Node2D = enemy_spawn_points.pick_random()
		return point.global_position

	var angle = randf_range(0, TAU)
	var distance = randf_range(min_spawn_distance, max_spawn_distance)
	return player.global_position + Vector2(cos(angle), sin(angle)) * distance

# =============================================
# REGION: Eventi nemici
# =============================================
func _on_enemy_killed() -> void:
	current_enemies -= 1

	if boss_wave_active:
		# Durante la bossfight non si contano i nemici uccisi per la wave
		# ma si aggiornano comunque le statistiche globali
		GlobalStats.kill_mobs_lvl += 1
		GlobalStats.kill_mobs_total += 1
		return

	killed_enemies += 1
	GlobalStats.kill_mobs_lvl += 1
	GlobalStats.kill_mobs_total += 1
	kill_info_label.text = "Enemies killed: %d / %d" % [killed_enemies, target_enemies]

	if killed_enemies >= target_enemies:
		await end_wave()

# =============================================
# REGION: Chest
# =============================================
func _spawn_chest() -> void:
	if chest_scenes.is_empty():
		return

	var chest_scene: PackedScene = chest_scenes.pick_random()
	var chest: Node2D = chest_scene.instantiate()

	if not chest_spawn_points.is_empty():
		var point: Node2D = chest_spawn_points.pick_random()
		chest.global_position = point.global_position
	else:
		var angle = randf_range(0, TAU)
		var distance = randf_range(200, 500)
		chest.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * distance

	get_parent().add_child(chest)

# =============================================
# REGION: Fine ondata
# =============================================
func end_wave() -> void:
	# Se era una bossfight, aggiorna la prossima ondata boss
	if boss_wave_active:
		boss_wave_active = false
		# La prossima bossfight sarà tra 7-10 ondate **dopo questa**
		next_boss_wave = (Global.wave) + randi_range(boss_wave_interval_min, boss_wave_interval_max)

	wave_finished_sequence()

func wave_finished_sequence() -> void:
	if Global.wave == 10:
		GlobalSteamScript._unlock_achievement("Wave-Master I")

	can_spawn = false
	if can_rew:
		can_rew = false
		var reward = Global.wave * 10
		GlobalStats.gold += int(reward)
		GlobalStats.total_gold_collected += int(reward)
		Global.update_mission_progress("rich_game_1", reward)
		Global.update_mission_progress("rich_game_2", reward)
		Global.update_mission_progress("rich_game_3", reward)

	Global.wave += 1

	# Chest ogni 5-10 ondate
	if Global.wave % randi_range(5, 10) == 0:
		_spawn_chest()

	await countdown_between_waves()
	start_wave()

# =============================================
# REGION: UI e countdown
# =============================================
func countdown_between_waves() -> void:
	await _show_wave_text_sequence("==== WAVE %d COMPLETED ====" % (Global.wave - 1), Color.GREEN)

	for i in range(int(wave_delay), 0, -1):
		await _show_wave_text_sequence("%d..." % i, Color.YELLOW)
		await get_tree().create_timer(1.0).timeout

	await _show_wave_text_sequence("START!", Color.CYAN)
	can_rew = true

func _show_wave_text_sequence(text: String, color: Color) -> void:
	wave_info_label.show()
	wave_info_label.text = text
	wave_info_label.modulate = color
	var tween = create_tween()
	tween.tween_property(wave_info_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(0.8)
	tween.tween_property(wave_info_label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(Callable(wave_info_label, "hide"))
	await tween.finished

# =============================================
# REGION: Process (minimappa e achievements)
# =============================================
func _process(_delta: float) -> void:
	#Global.player_hp = 200
	#if Input.is_action_just_pressed("ui_cancel"): 
		#Global.wave += 12
		#print(Global.wave)
	$UI/MiniMap.global_position = Vector2(Global.mapX, Global.mapY)
	if Global.can_show_map:
		$UI/MiniMap.show()
	else:
		$UI/MiniMap.hide()

	# Achievement vari (alcuni già presenti nel codice originale)
	if Global.player_hp >= 60 and GlobalStats.kill_mobs_lvl >= 40:
		GlobalStats.achievements["Ascent of the Unbroken"] = true
	if Global.enemy_type == "mini_boss" and GlobalStats.kill_mini_boss_lvl >= 1 and GlobalStats.damage_rec_miniboss_lvl < 10:
		GlobalStats.achievements["Walker of the Abyss"] = true
	if GlobalStats.powerups_lvl >= 25:
		GlobalStats.achievements["Harvest of Power"] = true
	if GlobalStats.play_hours >= 168:
		GlobalStats.achievements["Frost-Bound Epoch"] = true
	if Global.wave == 20:
		GlobalStats.achievements["Phantom of the Twentieth Dawn"] = true
	if GlobalStats.kill_mobs_lvl >= 30 and GlobalStats.damage_rec_lvl < 1:
		GlobalStats.achievements["Leviathan’s Hunger"] = true
	if GlobalStats.bullets_shoot_total >= 10000000 and GlobalStats.kill_mobs_total >= 500 and GlobalStats.kill_mini_boss_total >= 50:
		GlobalStats.achievements["Abyssal Deadshot"] = true
	if GlobalStats.kill_mobs_lvl >= 250:
		GlobalStats.achievements["Celestial Onslaught"] = true
	if Global.wave >= 10 and GlobalStats.damage_rec_lvl < 1:
		GlobalStats.achievements["Solar Tide Immortal"] = true
	if current_enemies >= 50:
		GlobalStats.achievements["Frozen Catastrophe"] = true
	if GlobalStats.kill_mobs_lvl >= 1000:
		GlobalStats.achievements["Godslayer Marksman"] = true
	if Global.wave >= 50 and GlobalStats.kill_mini_boss_lvl >= 1 and GlobalStats.kill_mobs_lvl >= 1500:
		GlobalStats.achievements["Forge of the Shattered Moon"] = true

func _on_check_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$DeadArea/up.emitting = true
		$DeadArea/down.emitting = true
		$DeadArea/right.emitting = true
		$DeadArea/left.emitting = true
	
func _on_check_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		$DeadArea/up.emitting = false
		$DeadArea/down.emitting = false
		$DeadArea/right.emitting = false
		$DeadArea/left.emitting = false
