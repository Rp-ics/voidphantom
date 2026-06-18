extends Control

@onready var score_label: RichTextLabel = $container/Score
@onready var btn_richest: Button = $container/TopRichest
@onready var btn_tophunter: Button = $container/TopHunter
@onready var btn_wavemaster: Button = $container/WaveMaster

var current_leaderboard: int = GlobalScoreboard.LeaderboardType.RICHEST_IN_VOID

var ICONS = {
	GlobalScoreboard.LeaderboardType.RICHEST_IN_VOID: "res://Gres/Assets/Icons/parts/gold_icon_1.png",
	GlobalScoreboard.LeaderboardType.TOP_HUNTER: "res://Gres/Assets/Icons/hard_skull.png",
	GlobalScoreboard.LeaderboardType.WAVE_MASTER: "res://Gres/Assets/Icons/skull_miniboss.png"
}

var TITLES = {
	GlobalScoreboard.LeaderboardType.RICHEST_IN_VOID: "👑  RICHEST IN VOID  👑",
	GlobalScoreboard.LeaderboardType.TOP_HUNTER: "💀  TOP HUNTER  💀",
	GlobalScoreboard.LeaderboardType.WAVE_MASTER: "🌊  WAVE MASTER  🌊"
}

func _ready() -> void:
	score_label.bbcode_enabled = true
	GlobalScoreboard.leaderboard_updated.connect(_on_leaderboard_updated)
	
	btn_richest.pressed.connect(func(): _switch_tab(GlobalScoreboard.LeaderboardType.RICHEST_IN_VOID))
	btn_tophunter.pressed.connect(func(): _switch_tab(GlobalScoreboard.LeaderboardType.TOP_HUNTER))
	btn_wavemaster.pressed.connect(func(): _switch_tab(GlobalScoreboard.LeaderboardType.WAVE_MASTER))
	
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		_refresh_ui()

func _switch_tab(type: int) -> void:
	current_leaderboard = type
	_refresh_ui()

func _refresh_ui() -> void:
	score_label.text = "\n[center][color=#bdfbff]Synchronizing with Void...[/color][/center]"
	await GlobalScoreboard.upload_score(current_leaderboard)
	GlobalScoreboard.refresh_leaderboard(current_leaderboard)

func _on_leaderboard_updated(lb_type: int) -> void:
	if visible and lb_type == current_leaderboard:
		_display_ranking()

func _display_ranking() -> void:
	var entries = GlobalScoreboard.get_leaderboard_entries(current_leaderboard)
	var icon_bbcode = "[img=24x24]%s[/img]" % ICONS[current_leaderboard]
	
	var lines = PackedStringArray()
	lines.append("[center][color=#FFD700]%s[/color][/center]\n" % TITLES[current_leaderboard])
	
	if entries.size() == 0:
		lines.append("[center][color=#aaaaaa]No entries found in this Void.[/color][/center]")
	else:
		for i in range(entries.size()):
			var rank = i + 1
			var player = entries[i].name
			var score = entries[i].score
			var rank_color = "#bdfbff"
			var trophy = "   "
			
			if rank == 1: rank_color = "#FFD700"; trophy = "🥇"
			elif rank == 2: rank_color = "#C0C0C0"; trophy = "🥈"
			elif rank == 3: rank_color = "#CD7F32"; trophy = "🥉"

			lines.append("[color=%s]%s %d.[/color] [color=#ffffff]%s[/color] [right]%s [color=#ffae00]%d[/color][/right]" % [
				rank_color, trophy, rank, player, icon_bbcode, score
			])

	lines.append("\n[color=#335555]──────────────────────────────[/color]")
	var my_score = _get_current_personal_stat()
	var my_name = GlobalScoreboard._get_player_name()
	lines.append("[color=#bdfbff]YOUR RECORD:[/color] [color=#ffffff]%s[/color] [right]%s [color=#ffae00]%d[/color][/right]" % [my_name, icon_bbcode, my_score])

	score_label.text = "\n".join(lines)

func _get_current_personal_stat() -> int:
	match current_leaderboard:
		GlobalScoreboard.LeaderboardType.RICHEST_IN_VOID: return GlobalStats.gold
		GlobalScoreboard.LeaderboardType.TOP_HUNTER: return GlobalStats.kill_boss_total + GlobalStats.kill_mobs_total + GlobalStats.kill_mini_boss_total
		GlobalScoreboard.LeaderboardType.WAVE_MASTER: return GlobalStats.max_game_wave
	return 0

func _on_close_score_pressed() -> void:
	self.hide()
