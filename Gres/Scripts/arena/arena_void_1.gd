extends Node

# =======================
# CONFIGURAZIONE ONDATE
# =======================
@export var wave_delay: float = 4.0
@export var min_spawn_distance: float = 300.0
@export var max_spawn_distance: float = 700.0
@export var max_enemies_on_field_base: int = 50

# =======================
# CHEST
# =======================
@export var chest_scenes: Array[PackedScene]   # le varie chest
@export var chest_spawn_points: Array[Node2D]  # punti fissi per le chest

# =======================
# PUNTI DI SPAWN NEMICI
# =======================
@export var enemy_spawn_points: Array[Node2D] = []

# =======================
# BOSS
# =======================
@export var boss_scene: PackedScene  # Trascina qui la scena del boss

# =======================
# STATO ONDATA
# =======================
var target_enemies: int = 0
var enemies_spawned: int = 0
var killed_enemies: int = 0
var current_enemies: int = 0

var can_spawn: bool = false
var spawn_rate: float = 2.0
var max_enemies_on_field: int = 50
var can_rew := true

var current_boss: Node2D = null

# =======================
# NODI
# =======================
@onready var enemy_container = $Gameplay/EnemyContainer
@onready var player = $Player
@onready var wave_info_label = $UI/WaveManager/WaveInfo
@onready var spawn_info_label = $UI/WaveManager/SpawnInfo
@onready var kill_info_label = $UI/WaveManager/KillInfo
# NUOVO: label per i premi (se non esiste puoi usare wave_info_label al suo posto)
@onready var reward_label = $UI/WaveManager/RewardLabel

# =======================
# READY
# =======================
func _ready():
	Global.mode = "endless"
	start_wave()

# Mostra un messaggio di ricompensa temporaneo
func show_reward(text: String, color: Color):
	if not reward_label:
		# Fallback: usa wave_info_label se RewardLabel non esiste
		if wave_info_label:
			wave_info_label.show()
			wave_info_label.text = text
			wave_info_label.modulate = color
			var tw = create_tween()
			tw.tween_property(wave_info_label, "modulate:a", 1.0, 0.15)
			tw.tween_interval(1.5)
			tw.tween_property(wave_info_label, "modulate:a", 0.0, 0.2)
			tw.tween_callback(wave_info_label.hide)
		return

	reward_label.show()
	reward_label.text = text
	reward_label.modulate = color
	var tw = create_tween()
	tw.tween_property(reward_label, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.5)
	tw.tween_property(reward_label, "modulate:a", 0.0, 0.2)
	tw.tween_callback(reward_label.hide)

# =======================
# REWARDS (Void Coins)
# =======================
func void_reward():
	# Fasce corrette con >= e <
	if Global.wave > 0 and Global.wave < 30 and Global.wave % 5 == 0:
		GlobalStats.void_coins += 2
		show_reward("+2 Void Coins", Color(0.6, 0.4, 1.0))
	elif Global.wave >= 30 and Global.wave < 45 and Global.wave % 5 == 0:
		GlobalStats.void_coins += 4
		show_reward("+4 Void Coins", Color(0.6, 0.4, 1.0))
	elif Global.wave >= 45 and Global.wave < 75 and Global.wave % 5 == 0:
		GlobalStats.void_coins += 6
		show_reward("+6 Void Coins", Color(0.6, 0.4, 1.0))
	elif Global.wave >= 75 and Global.wave % 5 == 0:
		GlobalStats.void_coins += 8
		show_reward("+8 Void Coins", Color(0.6, 0.4, 1.0))

# =======================
# WAVE MANAGEMENT
# =======================
func start_wave() -> void:
	_show_wave_text_sequence("[center]==== WAVE %d START ====" % Global.wave, Color.WHITE)
	if Global.wave > GlobalStats.max_wave:
		GlobalStats.max_wave = Global.wave

	if Global.wave >= GlobalStats.max_game_wave:
		GlobalStats.max_game_wave = Global.wave

	if Global.wave >= GlobalStats.max_wave:
		Global.update_mission_progress("resist_1", 1)
		Global.update_mission_progress("resist_2", 1)
		Global.update_mission_progress("resist_3", 1)

		if GlobalStats.damage_rec_lvl == 0:
			Global.update_mission_progress("perfect_waves_1", 1)
			Global.update_mission_progress("perfect_waves_2", 1)
			Global.update_mission_progress("perfect_waves_3", 1)

	# Reset variabili
	killed_enemies = 0
	current_enemies = 0
	enemies_spawned = 0
	current_boss = null

	# === BOSS WAVE (ogni 10) ===
	if Global.wave > 0 and Global.wave % 10 == 0:
		target_enemies = 1
		can_spawn = false
		spawn_info_label.text = "BOSS WAVE!"
		_spawn_boss()
		return

	# Void coins se multiplo di 5 (non boss)
	void_reward()

	# Chest se multiplo di 5
	if Global.wave > 0 and Global.wave % 5 == 0:
		_spawn_chest()
		show_reward("CHEST SPAWNED!", Color.GOLD)

	# === NORMAL WAVE ===
	target_enemies = 10 + int(Global.wave * 3.5)
	spawn_rate = clamp(2.0 - (Global.wave * 0.05), 0.4, 2.0)

	if Global.wave < 5:
		max_enemies_on_field = max_enemies_on_field_base
	else:
		max_enemies_on_field = clamp(50 + Global.wave * 2, 50, 120)

	# === ACHIEVEMENTS ===
	if Global.wave == 6 and GlobalStats.damage_rec_lvl < 20:
		GlobalSteamScript.unlock_achievement("Ascent of the Unbroken")

	can_spawn = true
	await spawn_enemies_loop()
	GlobalStats.save_data_stats()

func _process(delta: float) -> void:
	$UI/MiniMap.global_position = Vector2(Global.mapX, Global.mapY)
	if Global.can_show_map:
		$UI/MiniMap.show()
	else:
		$UI/MiniMap.hide()

	# === ACHIEVEMENTS (tutti originali, intatti) ===
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

# =======================
# SPAWN BOSS
# =======================
func _spawn_boss() -> void:
	if boss_scene == null:
		push_error("Boss scene not assigned!")
		await get_tree().create_timer(2.0).timeout
		end_wave()
		return

	var boss = boss_scene.instantiate()
	if not enemy_spawn_points.is_empty():
		boss.global_position = enemy_spawn_points.pick_random().global_position
	else:
		var angle = randf_range(0, TAU)
		boss.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * 600

	if boss.has_signal("boss_died"):
		boss.connect("boss_died", Callable(self, "_on_boss_killed"))
	else:
		boss.connect("tree_exiting", Callable(self, "_on_boss_killed"))

	enemy_container.add_child(boss)
	current_boss = boss
	enemies_spawned += 1
	current_enemies += 1
	spawn_info_label.text = "BOSS: Defeat it!"

func _on_boss_killed() -> void:
	if current_boss == null:
		return

	current_boss = null
	current_enemies -= 1
	killed_enemies += 1
	GlobalStats.kill_mobs_lvl += 1
	GlobalStats.kill_mobs_total += 1

	kill_info_label.text = "BOSS DEFEATED!"
	show_reward("BOSS DOWN!", Color.ORANGE_RED)
	await get_tree().create_timer(1.0).timeout
	end_wave()

# =======================
# SPAWN NEMICI NORMALI
# =======================
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

func get_spawn_position() -> Vector2:
	if not enemy_spawn_points.is_empty():
		return enemy_spawn_points.pick_random().global_position

	var angle = randf_range(0, TAU)
	var distance = randf_range(min_spawn_distance, max_spawn_distance)
	return player.global_position + Vector2(cos(angle), sin(angle)) * distance

func _on_enemy_killed() -> void:
	killed_enemies += 1
	current_enemies -= 1

	GlobalStats.kill_mobs_lvl += 1
	GlobalStats.kill_mobs_total += 1

	kill_info_label.text = "Enemies killed: %d / %d" % [killed_enemies, target_enemies]

	if killed_enemies >= target_enemies:
		end_wave()

# =======================
# CHEST
# =======================
func _spawn_chest() -> void:
	if chest_scenes.is_empty():
		return

	var chest_scene: PackedScene = chest_scenes.pick_random()
	var chest: Node2D = chest_scene.instantiate()

	if not chest_spawn_points.is_empty():
		chest.global_position = chest_spawn_points.pick_random().global_position
	else:
		var angle = randf_range(0, TAU)
		var distance = randf_range(200, 500)
		chest.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * distance

	get_parent().add_child(chest)

# =======================
# END WAVE
# =======================
func end_wave() -> void:
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
		show_reward("+%d GOLD" % int(reward), Color.GOLD)

	Global.wave += 1

	if Global.wave % 10 == 0:
		_spawn_chest()
		show_reward("CHEST SPAWNED!", Color.GOLD)

	await countdown_between_waves()
	start_wave()

# =======================
# COUNTDOWN & UI
# =======================
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
	tween.tween_callback(wave_info_label.hide)
	await tween.finished
