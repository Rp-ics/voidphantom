extends RichTextLabel

# ======================
# CONFIG
# ======================
@export_range(0.0, 1.0, 0.01) var min_delay: float = 0.02
@export_range(0.0, 1.0, 0.01) var max_delay: float = 0.08
@export var punctuation_pause: float = 4.0
@export var respect_bbcode_tags: bool = true
@export var letter_sfx: AudioStream
@export_range(0.0, 1.0, 0.01) var sfx_pitch_variance: float = 0.08
@export var pause_between_texts: float = 1.5

# ======================
# MULTI-TEXT
# ======================
@export var txt1: String = "UNIDENTIFIED!"
@export var txt2: String = "WHAT THE HELL IS THAT?"
# ======================
# INTERNAL
# ======================
var _rng := RandomNumberGenerator.new()
var _sfx_player: AudioStreamPlayer
var can_txt = true

func play_txt():
	randomize()
	clear()
	if letter_sfx:
		_sfx_player = AudioStreamPlayer.new()
		_sfx_player.stream = letter_sfx
		add_child(_sfx_player)
	await _play_all_texts()

func _process(delta: float) -> void:
	if Global.story_line == 1:
		Global.story_line = 0
		txt1 = "..."
		txt2 = "WHAT THE HELL IS THAT?"
		play_txt()
	elif Global.story_line == 2:
		Global.story_line = 0
		txt1 = ""
		txt2 = ""
		play_txt()

# ==========================================================
# MAIN SEQUENCE
# ==========================================================
func _play_all_texts() -> void:
	var texts := [txt1, txt2]
	for t in texts:
		if t.strip_edges() == "":
			continue
		clear()
		await _do_typing(t)
		await get_tree().create_timer(pause_between_texts).timeout
	# 🔁 se vuoi che riparta in loop:
	# await get_tree().create_timer(2.0).timeout
	# await _play_all_texts()

# ==========================================================
# TYPING EFFECT
# ==========================================================
func _do_typing(text: String) -> void:
	var i := 0
	var n := text.length()

	while i < n:
		var ch := text[i]

		# Gestione BBCode
		if respect_bbcode_tags and ch == "[":
			var j := i
			while j < n and text[j] != "]":
				j += 1
			if j < n:
				_append_text(text.substr(i, j - i + 1))
				i = j + 1
				await get_tree().create_timer(_rng.randf_range(min_delay, max_delay)).timeout
				continue

		_append_text(ch)
		_play_letter_sfx()
		i += 1

		var delay = _rng.randf_range(min_delay, max_delay)
		if ch in [".", ",", ";", ":", "!", "?", "\n"]:
			delay *= punctuation_pause
		elif ch == " ":
			delay *= 0.6

		await get_tree().create_timer(delay).timeout

# ==========================================================
# HELPERS
# ==========================================================
func _append_text(s: String) -> void:
	append_text(s)
	queue_redraw()

func _play_letter_sfx() -> void:
	if not letter_sfx or not _sfx_player:
		return
	_sfx_player.pitch_scale = 1.0 + _rng.randf_range(-sfx_pitch_variance, sfx_pitch_variance)
	_sfx_player.stop()
	_sfx_player.play()
