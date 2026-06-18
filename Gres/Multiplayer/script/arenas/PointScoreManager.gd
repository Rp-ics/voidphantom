extends Node

signal scores_updated(scores: Dictionary)

var _scores: Dictionary = {}
var _is_point_mode: bool = false   # true = POINT, false = KING (o altro)
var _is_king_mode: bool = false    # comodo per distinguere
var _is_progression_mode: bool = false

@onready var score_l = $InfoUI/ScoreLabel # RichTextLabel

# ------------------------------------------------------------------
# INIT
# ------------------------------------------------------------------

func init(peer_ids: Array, is_point_mode: bool = false) -> void:
	_is_point_mode = is_point_mode
	_is_king_mode = GameModes.is_king_mode()
	_is_progression_mode = GameModes.is_progression_mode()
	_scores.clear()
	
	for pid in peer_ids:
		_scores[pid] = 0
	
	# Invia sia i punteggi che i flag di modalità a tutti i client.
	_broadcast_full_state.rpc(_scores.duplicate(), _is_point_mode, _is_king_mode, _is_progression_mode)

# ------------------------------------------------------------------
# EVENT REGISTRATION (server only)
# ------------------------------------------------------------------

# POINT mode events
func register_hit(shooter_id: int, _victim_id: int) -> void:
	if not multiplayer.is_server(): return
	if not _is_point_mode: return
	if not _scores.has(shooter_id):
		_scores[shooter_id] = 0
	_scores[shooter_id] += GameModes.POINT_HIT_SCORE
	_broadcast_scores.rpc(_scores.duplicate())
	
func register_kill(killer_id: int, _victim_id: int) -> void:
	if not multiplayer.is_server(): return
	if not _is_point_mode: return
	if killer_id <= 0 or not _scores.has(killer_id): return
	_scores[killer_id] += GameModes.POINT_KILL_SCORE
	_broadcast_scores.rpc(_scores.duplicate())

func register_death(dead_id: int) -> void:
	if not multiplayer.is_server(): return
	if not _is_point_mode: return
	if not _scores.has(dead_id):
		_scores[dead_id] = 0
	_scores[dead_id] = max(0, _scores[dead_id] + GameModes.POINT_DEATH_SCORE)
	_broadcast_scores.rpc(_scores.duplicate())

# PROGRESSION mode events
func register_progression_kill(killer_id: int, _victim_id: int) -> void:
	if not multiplayer.is_server(): return
	if not _is_progression_mode: return
	if killer_id <= 0: return
	if not _scores.has(killer_id):
		_scores[killer_id] = 0
	_scores[killer_id] += GameModes.PROGRESSION_KILL_SCORE
	_broadcast_scores.rpc(_scores.duplicate())

func register_progression_death(dead_id: int) -> void:
	if not multiplayer.is_server(): return
	if not _is_progression_mode: return
	if not _scores.has(dead_id):
		_scores[dead_id] = 0
	_scores[dead_id] += GameModes.PROGRESSION_DEATH_SCORE
	_broadcast_scores.rpc(_scores.duplicate())

# KING mode events
func register_king_zone(peer_id: int) -> void:
	if not multiplayer.is_server(): return
	if not _is_king_mode: return
	if not _scores.has(peer_id):
		_scores[peer_id] = 0
	_scores[peer_id] += GameModes.KING_ZONE_SCORE_PER_SEC
	_broadcast_scores.rpc(_scores.duplicate())

func register_king_kill(killer_id: int, victim_id: int) -> void:
	if not multiplayer.is_server(): return
	if not _is_king_mode: return
	if killer_id > 0 and _scores.has(killer_id):
		_scores[killer_id] += GameModes.KING_KILL_SCORE
	if victim_id > 0 and _scores.has(victim_id):
		_scores[victim_id] = max(0, _scores[victim_id] + GameModes.KING_DEATH_SCORE)
	_broadcast_scores.rpc(_scores.duplicate())

func register_king_death(dead_id: int) -> void:
	if not multiplayer.is_server(): return
	if not _is_king_mode: return
	if _scores.has(dead_id):
		_scores[dead_id] = max(0, _scores[dead_id] + GameModes.KING_DEATH_SCORE)
		_broadcast_scores.rpc(_scores.duplicate())

# ------------------------------------------------------------------
# QUERY
# ------------------------------------------------------------------

func get_score(peer_id: int) -> int:
	return _scores.get(peer_id, 0)

func get_all_scores() -> Dictionary:
	return _scores.duplicate()

func get_winner_id() -> int:
	var best_id  := -1
	var best_pts := -1
	for pid in _scores:
		if _scores[pid] > best_pts:
			best_pts = _scores[pid]
			best_id  = pid
	return best_id

# ------------------------------------------------------------------
# UI UPDATE
# ------------------------------------------------------------------

func _update_score_display() -> void:
	# Mostra il punteggio sia per POINT che per KING
	if not (_is_point_mode or _is_king_mode or _is_progression_mode):
		# Se non siamo in una modalità con punteggio, nascondi il label
		if score_l:
			score_l.visible = false
		return
	
	if not score_l:
		return
		
	score_l.visible = true
	var my_id = multiplayer.get_unique_id()
	var my_score = _scores.get(my_id, 0)
	
	# Format text for RichTextLabel
	score_l.text = "[center][color=white]SCORE: [color=yellow]%d[/color][/color][/center]" % my_score

# ------------------------------------------------------------------
# SYNC — server → everyone
# ------------------------------------------------------------------

# Nuovo RPC per inviare stato completo all'inizio
@rpc("authority", "reliable", "call_local")
func _broadcast_full_state(new_scores: Dictionary, is_point: bool, is_king: bool, is_progression: bool) -> void:
	_scores = new_scores
	_is_point_mode = is_point
	_is_king_mode = is_king
	_is_progression_mode = is_progression
	_update_score_display()
	emit_signal("scores_updated", _scores.duplicate())

# RPC per aggiornamenti incrementali
@rpc("authority", "reliable", "call_local")
func _broadcast_scores(new_scores: Dictionary) -> void:
	_scores = new_scores
	_update_score_display()
	emit_signal("scores_updated", _scores.duplicate())
