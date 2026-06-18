extends RichTextLabel

func _process(_delta):
	# =============================================
	# RACCOLTA DATI
	# =============================================
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var frame_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var physics_ms = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	
	var static_mem_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var video_mem_mb = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
	
	var objects = Performance.get_monitor(Performance.OBJECT_COUNT)
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	
	# =============================================
	# ANALISI FLUIDITÀ
	# =============================================
	var fps_color = _get_fps_color(fps)
	var fps_status = _get_fps_status(fps)
	var frame_color = _get_frame_time_color(frame_ms)
	var cpu_status = "✓ OK" if frame_ms < 10.0 else ("⚠ LENTO" if frame_ms < 16.6 else "✗ CRITICO")
	
	# =============================================
	# COSTRUZIONE BARRE DI UTILIZZO
	# =============================================
	# Barra CPU Time (riferimento: 16.6ms per 60fps)
	var cpu_percent = clamp(frame_ms / 16.6, 0.0, 1.0)
	var cpu_bar = _build_bar(cpu_percent, frame_color, 20)
	
	# Barra Memoria Video (riferimento: dipende dalla GPU, metto 1024MB come esempio)
	var vram_percent = clamp(video_mem_mb / 1024.0, 0.0, 1.0)
	var vram_bar = _build_bar(vram_percent, "cyan", 20)
	
	# Barra Draw Calls (riferimento: oltre 500 inizia a pesare)
	var draw_percent = clamp(draw_calls / 500.0, 0.0, 1.0)
	var draw_color = "#00ff00" if draw_calls < 200 else ("#ffff00" if draw_calls < 350 else "#ff4444")
	var draw_bar = _build_bar(draw_percent, draw_color, 20)
	
	# =============================================
	# OUTPUT FINALE
	# =============================================
	var text = ""
	
	# --- RIGA 1: FPS ---
	text += "[font_size=24][b][color=%s]%d FPS[/color][/b][/font_size]" % [fps_color, fps]
	text += "  [font_size=14][color=%s]%s[/color][/font_size]\n" % [fps_color, fps_status]
	
	# --- RIGA 2: CPU Time con barra ---
	text += "\n[color=#888888]CPU:[/color] "
	text += "[color=%s]%.1f ms[/color]  %s" % [frame_color, frame_ms, cpu_status]
	text += "\n[bgcolor=#222222]%s[/bgcolor]" % cpu_bar
	
	# --- RIGA 3: Physics Time ---
	text += "\n\n[color=#888888]Physics:[/color] [color=aqua]%.2f ms[/color]" % physics_ms
	
	# --- RIGA 4: Memoria con barra ---
	text += "\n\n[color=#888888]VRAM:[/color] [color=cyan]%.1f MB[/color]" % video_mem_mb
	text += "\n[bgcolor=#222222]%s[/bgcolor]" % vram_bar
	
	text += "\n[color=#888888]RAM Static:[/color] %.1f MB" % static_mem_mb
	
	# --- RIGA 5: Draw Calls con barra ---
	text += "\n\n[color=#888888]Draw Calls:[/color] [color=%s]%d[/color]" % [draw_color, draw_calls]
	text += "\n[bgcolor=#222222]%s[/bgcolor]" % draw_bar
	
	# --- RIGA 6: Oggetti totali ---
	text += "\n\n[color=#888888]Oggetti:[/color] %d" % objects
	
	self.text = text


# =============================================
# FUNZIONI DI SUPPORTO
# =============================================

func _get_fps_color(fps: int) -> String:
	if fps >= 55:
		return "#00ff00"   # Verde: ottimo
	elif fps >= 30:
		return "#ffff00"   # Giallo: discreto
	else:
		return "#ff4444"   # Rosso: pessimo

func _get_fps_status(fps: int) -> String:
	if fps >= 55:
		return "🔥 FLUIDO"
	elif fps >= 30:
		return "⚠ ACCETTABILE"
	else:
		return "✗ SCATTOSO"

func _get_frame_time_color(ms: float) -> String:
	if ms <= 8.0:
		return "#00ff00"   # Sotto 8ms → 120+ fps possibili
	elif ms <= 16.6:
		return "#aaff00"   # Fino a 16.6ms → 60fps
	else:
		return "#ff4444"   # Sopra 16.6ms → sotto i 60fps

func _build_bar(percent: float, color: String, length: int) -> String:
	"""
	Crea una barra di avanzamento stile terminale.
	percent: 0.0 a 1.0
	color: colore BBCode es. "#00ff00"
	length: numero totale di blocchi
	"""
	var filled = int(percent * length)
	var bar = ""
	
	# Parte piena
	if filled > 0:
		bar += "[color=%s]" % color
		for i in range(filled):
			bar += "█"
		bar += "[/color]"
	
	# Parte vuota
	var empty = length - filled
	if empty > 0:
		bar += "[color=#333333]"
		for i in range(empty):
			bar += "░"
		bar += "[/color]"
	
	# Etichetta percentuale
	bar += "  %d%%" % int(percent * 100)
	
	return bar
