extends AudioStreamPlayer

# =========================
# CONFIG
# =========================
@export var fade_time: float = 1.0
@export var playlist: Array[AudioStream] = []
@export var in_loop: bool = true
@export var is_random: bool = true

# =========================
# VARIABILI
# =========================
var current_track_index: int = -1
var played_indices: Array[int] = []

func apply_music_volume():
	if Engine.has_singleton("Global"):
		var db_val = -80 if Global.music_volume == 0 else linear_to_db(Global.music_volume / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db_val)

# =========================
# READY
# =========================
func _ready():
	bus = "Music"  # <- fondamentale!
	connect("finished", Callable(self, "_on_track_finished"))
	apply_music_volume()
	autoplay_next_track()
	
# =========================
# PLAY TRACK
# =========================
func play_track(index: int) -> void:
	if index < 0 or index >= playlist.size():
		return
	current_track_index = index
	stream = playlist[index]
	play()
	fade_in()

func autoplay_next_track() -> void:
	if playlist.size() == 0:
		return

	if is_random:
		var available = []
		for i in range(playlist.size()):
			if i not in played_indices:
				available.append(i)
		if available.size() == 0:
			played_indices.clear()
			available = []
			for i in range(playlist.size()):
				available.append(i)
		current_track_index = available[randi() % available.size()]
	else:
		current_track_index += 1
		if current_track_index >= playlist.size():
			if in_loop:
				current_track_index = 0
			else:
				return  # fine playlist
	play_track(current_track_index)
	if is_random:
		played_indices.append(current_track_index)


# =========================
# FADE IN
# =========================
func fade_in() -> void:
	volume_db = -80
	var tween = create_tween()
	tween.tween_property(self, "volume_db", 0.0, fade_time)

# =========================
# FINISH HANDLER
# =========================
func _on_track_finished() -> void:
	if in_loop:
		play_track(current_track_index)
	else:
		autoplay_next_track()
