extends Area2D

# ========= PARAMETRI LASER =========
@export var lunghezza_massima: float = 500.0
@export var spessore_base: float = 4.0
@export var colore_nucleo: Color = Color(1.0, 0.2, 0.2, 1.0)      # rosso acceso
@export var colore_alone: Color = Color(1.0, 0.4, 0.1, 0.5)       # arancione trasparente
@export var danno_laser: int = 1
@export var impulsi_per_secondo: float = 10.0    # frequenza intermittenza (0 = continuo)

# ========= STATO INTERNO =========
var laser_attivo: bool = false
var tempo_laser: float = 0.0
var direzione: Vector2 = Vector2.RIGHT   # direzione del raggio (modificabile)
var nodi_colpiti: Array = []              # traccia chi è già stato danneggiato in questo frame

# Tween per effetti
var tween_laser: Tween


func _ready() -> void:
	monitoring = false   # il laser non è un'area di trigger, colpisce tramite raycast
	queue_redraw()


func _process(delta: float) -> void:
	if laser_attivo:
		tempo_laser += delta
		rileva_e_colpisci()
		queue_redraw()   # ridisegna ogni frame per l'animazione continua


# ========= ATTIVAZIONE / DISATTIVAZIONE =========
func attiva_laser(durata: float = -1.0) -> void:
	"""Attiva il laser. Se durata > 0, si spegne automaticamente dopo quel tempo."""
	laser_attivo = true
	tempo_laser = 0.0
	
	if durata > 0:
		if tween_laser:
			tween_laser.kill()
		tween_laser = create_tween()
		tween_laser.tween_callback(disattiva_laser).set_delay(durata)


func disattiva_laser() -> void:
	laser_attivo = false
	queue_redraw()


# ========= RILEVAMENTO COLPI =========
func rileva_e_colpisci() -> void:
	var space_state = get_world_2d().direct_space_state
	var origine = global_position
	var fine = origine + direzione * lunghezza_massima
	
	# Raycast 2D verso la direzione
	var query = PhysicsRayQueryParameters2D.create(origine, fine)
	query.exclude = [self]
	query.collision_mask = 1   # regola in base ai tuoi layer
	var risultato = space_state.intersect_ray(query)
	
	if not risultato.is_empty():
		var corpo = risultato.collider
		var punto_impatto = risultato.position
		
		# Danno al giocatore
		if corpo.is_in_group("player") and corpo.has_method("take_damage"):
			# Applica danno solo se il laser è "acceso" in questo istante (gestisce pulsazione)
			if impulsi_per_secondo == 0 or is_laser_on_this_frame():
				if not corpo in nodi_colpiti:
					corpo.take_damage(danno_laser)
					nodi_colpiti.append(corpo)
		
		# Aggiorna lunghezza effettiva per il disegno
		var distanza = origine.distance_to(punto_impatto)
		disegna_con_impatto(distanza, punto_impatto)
	else:
		nodi_colpiti.clear()   # nessun ostacolo, reset colpiti
		disegna_libero()


# Verifica se in questo frame il laser è nella fase "on" (per pulsazione)
func is_laser_on_this_frame() -> bool:
	var ciclo = fmod(tempo_laser * impulsi_per_secondo, 1.0)
	return ciclo < 0.5   # metà tempo acceso, metà spento


# ========= DISEGNO DEL LASER =========
var distanza_effettiva: float = 0.0
var punto_colpo: Vector2 = Vector2.ZERO
var ha_colpito: bool = false


func disegna_con_impatto(distanza: float, punto: Vector2) -> void:
	distanza_effettiva = distanza
	punto_colpo = punto
	ha_colpito = true


func disegna_libero() -> void:
	distanza_effettiva = lunghezza_massima
	punto_colpo = Vector2.ZERO
	ha_colpito = false


func _draw() -> void:
	if not laser_attivo:
		return
	
	# Se il laser pulsa, saltiamo i frame "off"
	if impulsi_per_secondo > 0 and not is_laser_on_this_frame():
		return
	
	var origine_locale = Vector2.ZERO
	var fine_locale = direzione * distanza_effettiva
	var spessore_effettivo = spessore_base + sin(tempo_laser * 15.0) * 1.5   # vibrazione spessore
	
	# 1. Alone esterno (bagliore diffuso)
	var colore_alone_anim = colore_alone
	colore_alone_anim.a = colore_alone.a + sin(tempo_laser * 8.0) * 0.15
	draw_line(origine_locale, fine_locale, colore_alone_anim, spessore_effettivo * 4.0)
	
	# 2. Alone intermedio
	var colore_alone2 = colore_nucleo
	colore_alone2.a = 0.3
	draw_line(origine_locale, fine_locale, colore_alone2, spessore_effettivo * 2.0)
	
	# 3. Nucleo del laser (bianco/rosso brillante)
	draw_line(origine_locale, fine_locale, Color.WHITE, spessore_effettivo * 0.6)
	draw_line(origine_locale, fine_locale, colore_nucleo, spessore_effettivo)
	
	# 4. Scintille lungo il raggio
	var n_scintille = int(distanza_effettiva / 30.0)
	for i in range(n_scintille):
		var t = float(i) / n_scintille
		var fase = tempo_laser * 12.0 + i * 1.7
		var offset_x = sin(fase) * 5.0
		var offset_y = cos(fase) * 5.0
		
		# Calcola posizione lungo il raggio
		var pos_base = origine_locale + direzione * distanza_effettiva * t
		var perpendicolare = Vector2(-direzione.y, direzione.x)
		var pos = pos_base + perpendicolare * offset_x + direzione * offset_y * 0.3
		
		var colore_scintilla = Color(1.0, 0.8, 0.2, 0.9) if i % 3 == 0 else Color.WHITE
		colore_scintilla.a = 0.7 + sin(tempo_laser * 10.0 + i) * 0.3
		draw_circle(pos, 1.5, colore_scintilla)
	
	# 5. Origine del laser (punto di emissione)
	var intensita_origine = 2.0 + sin(tempo_laser * 10.0) * 0.8
	draw_circle(origine_locale, 8.0, Color(1.0, 1.0, 0.6, 0.4))
	draw_circle(origine_locale, 4.0, Color.WHITE * intensita_origine)
	draw_circle(origine_locale, 2.0, colore_nucleo * 1.5)
	
	# 6. Particelle che fluiscono dall'origine
	var n_flusso = 8
	for i in range(n_flusso):
		var fase_flusso = fmod(tempo_laser * 3.0 + float(i) / n_flusso, 1.0)
		var pos_particella = origine_locale + direzione * (20.0 + fase_flusso * distanza_effettiva * 0.5)
		var offset = Vector2(randf() - 0.5, randf() - 0.5) * 6.0 * (1.0 - fase_flusso)
		var col_particella = Color(1.0, 0.6, 0.2, 0.6 * (1.0 - fase_flusso))
		draw_circle(pos_particella + offset, 1.0 + (1.0 - fase_flusso) * 2.0, col_particella)
	
	# 7. Impatto (se colpisce qualcosa)
	if ha_colpito:
		var punto_impatto_locale = punto_colpo - global_position
		disegna_effetto_impatto(punto_impatto_locale)


func disegna_effetto_impatto(punto: Vector2) -> void:
	# Cerchio di impatto in espansione virtuale (dimensione fissa con pulsazione)
	var raggio_impatto = 15.0 + sin(tempo_laser * 20.0) * 5.0
	
	# Bagliore
	draw_circle(punto, raggio_impatto * 1.5, Color(1.0, 1.0, 0.5, 0.3))
	# Corona esterna
	draw_arc(punto, raggio_impatto, 0, TAU, 32, Color(1.0, 0.6, 0.0, 0.8), 2.5)
	# Punto caldo
	draw_circle(punto, 6.0, Color.WHITE)
	draw_circle(punto, 3.0, Color(1.0, 0.8, 0.0))
	
	# Scintille d'impatto
	var n_scintille_impatto = 10
	for i in range(n_scintille_impatto):
		var angolo = i * TAU / n_scintille_impatto + tempo_laser * 4.0
		var distanza = raggio_impatto * (0.6 + sin(tempo_laser * 15.0 + i) * 0.4)
		var pos_scintilla = punto + Vector2(cos(angolo), sin(angolo)) * distanza
		var col_scintilla = Color(1.0, 0.9, 0.1, 1.0)
		draw_circle(pos_scintilla, 2.0, col_scintilla)
		# Piccola scia
		var inizio_scia = punto + Vector2(cos(angolo), sin(angolo)) * distanza * 0.5
		draw_line(inizio_scia, pos_scintilla, col_scintilla, 1.0)


# ========= METODI DI CONTROLLO =========
func imposta_direzione(angolo_rad: float) -> void:
	"""Imposta la direzione del laser in radianti."""
	direzione = Vector2(cos(angolo_rad), sin(angolo_rad))

func ruota_laser(velocita_rad: float, delta: float) -> void:
	"""Ruota il laser continuamente (da chiamare in _process)."""
	imposta_direzione(direzione.angle() + velocita_rad * delta)
