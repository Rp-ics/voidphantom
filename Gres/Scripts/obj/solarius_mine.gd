extends Area2D

# ========= Parametri esportati =========

# Aspetto in idle
@export var raggio_mina: float = 22.0                # dimensione visiva della mina
@export var colore_corpo: Color = Color(0.2, 0.2, 0.25)  # metallo scuro
@export var colore_piastra: Color = Color(0.35, 0.32, 0.3)
@export var colore_led: Color = Color.RED
@export var velocita_rotazione: float = 1.5           # rotazione punte

# Esplosione (come prima)
@export var raggio_massimo: float = 100.0
@export var durata: float = 0.6
@export var colore_esplosione: Color = Color.ORANGE
@export var danno: int = 1

# ========= Stato interno =========
var esplodendo: bool = false
var tempo_trascorso: float = 0.0       # contatore per esplosione
var raggio_corrente: float = 0.0
var alpha_corrente: float = 1.0
var idle_time: float = 0.0            # contatore per animazione idle

var tween: Tween


func _ready() -> void:
	monitoring = true
	queue_redraw()   # disegna il frame iniziale


func _process(delta: float) -> void:
	if esplodendo:
		tempo_trascorso += delta
		queue_redraw()
	else:
		idle_time += delta
		queue_redraw()   # animazione idle continua


# Rilevamento giocatore
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not esplodendo:
		blow_draw()


func _on_body_exited(body: Node2D) -> void:
	pass  # ignorato in questo design


# Avvia l'esplosione
func blow_draw() -> void:
	esplodendo = true
	monitoring = false
	tempo_trascorso = 0.0

	# Danno
	var corpi = get_overlapping_bodies()
	for corpo in corpi:
		if corpo.is_in_group("player") and corpo.has_method("take_damage"):
			corpo.take_damage(danno)

	# Animazione con Tween
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_method(set_raggio, 0.0, raggio_massimo, durata)
	tween.tween_method(set_alpha, 1.0, 0.0, durata)
	tween.chain().tween_callback(queue_free)


func set_raggio(valore: float) -> void:
	raggio_corrente = valore
	queue_redraw()

func set_alpha(valore: float) -> void:
	alpha_corrente = valore
	queue_redraw()


# ========= DISEGNO =========
func _draw() -> void:
	if esplodendo:
		draw_explosion()
	else:
		draw_mine_idle()


# ---------------------------- ANIMAZIONE IDLE ----------------------------
func draw_mine_idle() -> void:
	var t = idle_time

	# 1. Ombra esterna (cerchio sfocato, simulato con più cerchi concentrici)
	for i in range(3):
		var r = raggio_mina + 4.0 + i * 2.5
		var col = Color(0, 0, 0, 0.15 - i * 0.04)
		draw_circle(Vector2.ZERO, r, col)

	# 2. Corpo principale (metallo scuro con bordo più chiaro)
	draw_circle(Vector2.ZERO, raggio_mina, colore_corpo)
	draw_arc(Vector2.ZERO, raggio_mina, 0, TAU, 32, colore_corpo.lightened(0.15), 2.0)

	# 3. Scanalature radiali (ruotano per sembrare un meccanismo a orologeria)
	var n_scanalature = 16
	var base_rot = t * 0.3          # rotazione lenta
	for i in range(n_scanalature):
		var angolo = base_rot + i * TAU / n_scanalature
		var lunghezza = raggio_mina * 0.85
		var start = Vector2(cos(angolo), sin(angolo)) * raggio_mina * 0.35
		var end = start + Vector2(cos(angolo), sin(angolo)) * (lunghezza - raggio_mina * 0.35)
		var spessore = 1.2 if i % 2 == 0 else 0.7
		draw_line(start, end, colore_corpo.lightened(0.2), spessore)

	# 4. Punte / denti (6 punte che ruotano più velocemente)
	var n_denti = 6
	var rot_denti = t * velocita_rotazione
	for i in range(n_denti):
		var angolo = rot_denti + i * TAU / n_denti
		var base_interna = raggio_mina * 0.85
		var punta_esterna = raggio_mina * 1.35
		var largo_base = deg_to_rad(18)
		# Disegno un triangolo per ogni dente
		var p1 = Vector2(cos(angolo - largo_base), sin(angolo - largo_base)) * base_interna
		var p2 = Vector2(cos(angolo + largo_base), sin(angolo + largo_base)) * base_interna
		var p_tip = Vector2(cos(angolo), sin(angolo)) * punta_esterna
		var col_dente = Color(0.3, 0.28, 0.35)  # grigio metallico
		draw_colored_polygon(PackedVector2Array([p1, p2, p_tip]), col_dente)
		# Bordi chiari per definire i denti
		draw_line(p1, p_tip, Color.WHITE, 0.8)
		draw_line(p2, p_tip, Color.WHITE, 0.8)

	# 5. Piastra a pressione (pulsante 3D)
	var pulsazione = abs(sin(t * 3.0)) * 0.06          # oscillazione leggera
	var raggio_piastra = raggio_mina * 0.45
	# Cerchio base della piastra leggermente deformato
	var fattore_scala = 1.0 + pulsazione
	var r_piastra_anim = raggio_piastra * fattore_scala
	draw_circle(Vector2.ZERO, r_piastra_anim, colore_piastra)

	# Effetto 3D: highlight in alto a sinistra, ombra in basso a destra
	var h_offset = Vector2(-r_piastra_anim * 0.18, -r_piastra_anim * 0.18)
	var s_offset = Vector2(r_piastra_anim * 0.15, r_piastra_anim * 0.15)
	draw_circle(h_offset, r_piastra_anim * 0.5, Color(1, 1, 1, 0.12))   # luce
	draw_circle(s_offset, r_piastra_anim * 0.6, Color(0, 0, 0, 0.25))   # ombra

	# 6. LED lampeggiante
	var led_on = sin(t * 8.0) > 0.0       # lampeggia veloce
	var led_color = colore_led if led_on else colore_led.darkened(0.7)
	led_color.a = 0.9 if led_on else 0.3
	var pos_led = Vector2(raggio_mina * 0.55, -raggio_mina * 0.4)   # in alto a destra
	draw_circle(pos_led, 2.5, led_color)
	# Alone LED
	draw_circle(pos_led, 5.0, Color(1, 0, 0, 0.1) if led_on else Color(1, 0, 0, 0.0))

	# 7. Granuli / bulloni decorativi
	var n_bulloni = 4
	var rot_bull = t * 0.5
	for i in range(n_bulloni):
		var ang = rot_bull + i * TAU / n_bulloni
		var pos = Vector2(cos(ang), sin(ang)) * raggio_mina * 0.75
		draw_circle(pos, 2.0, Color(0.5, 0.5, 0.45))
		draw_circle(pos, 1.2, Color(0.7, 0.7, 0.65))   # riflesso

	# 8. Piccole scintille rotanti intorno alla piastra
	var n_scintille = 6
	var rot_scint = t * 2.0
	for i in range(n_scintille):
		var ang = rot_scint + i * TAU / n_scintille
		var dist = r_piastra_anim * 1.2
		var pos = Vector2(cos(ang), sin(ang)) * dist
		draw_circle(pos, 1.0, Color(1, 0.8, 0.2, 0.7))


# ---------------------------- ANIMAZIONE ESPLOSIONE ----------------------------
func draw_explosion() -> void:
	# Cerchio principale
	var colore = colore_esplosione
	colore.a = alpha_corrente
	draw_circle(Vector2.ZERO, raggio_corrente, colore)

	# Corona più scura
	var colore_bordo = colore_esplosione.darkened(0.5)
	colore_bordo.a = alpha_corrente * 0.7
	draw_arc(Vector2.ZERO, raggio_corrente, 0, TAU, 32, colore_bordo, 3.0)

	# Particelle/schegge rotanti
	var n_particelle = 12
	for i in range(n_particelle):
		var angolo = i * TAU / n_particelle + tempo_trascorso * 5.0
		var distanza = raggio_corrente * 0.9
		var pos = Vector2(cos(angolo), sin(angolo)) * distanza
		var colore_particella = Color.YELLOW
		colore_particella.a = alpha_corrente * 0.8
		draw_circle(pos, 3.0, colore_particella)
		# Scia
		var scia_start = Vector2(cos(angolo - 0.2), sin(angolo - 0.2)) * distanza * 0.8
		draw_line(scia_start, pos, colore_particella, 1.5)
