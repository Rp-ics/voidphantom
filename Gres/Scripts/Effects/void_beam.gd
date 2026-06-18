extends Node2D
class_name VoidBeam

## Velocità di rotazione (rad/s) – impostata dal boss
var rotation_speed: float = 0.0

## Danno inflitto al giocatore (al secondo)
@export var damage_per_second: float = 20.0

## Durata totale del raggio (secondi)
@export var lifetime: float = 5.0

## Lunghezza del raggio in pixel (modifica anche i punti del Line2D)
@export var beam_length: float = 400.0

# Riferimenti ai nodi
@onready var beam_line: Line2D = $BeamLine
@onready var area: Area2D = $HitArea
@onready var timer: Timer = $LifetimeTimer

# Per animazioni continue
var _pulse_time: float = 0.0
var _base_width: float = 6.0
var _target_alpha: float = 0.7
var _tween: Tween

func _ready() -> void:
	# Imposta i punti del Line2D in base alla lunghezza
	beam_line.points = PackedVector2Array([Vector2.ZERO, Vector2(0, -beam_length)])
	beam_line.width = _base_width
	
	# Avvia il timer di autodistruzione
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_start_fade_out)
	timer.start()
	
	# Animazione iniziale: fade-in (larghezza e alpha)
	_tween = create_tween()
	_tween.set_parallel(true)
	# Il raggio parte da larghezza 0 e si allarga
	beam_line.width = 0.0
	beam_line.default_color.a = 0.0
	_tween.tween_property(beam_line, "width", _base_width, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(beam_line, "default_color:a", 0.8, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Dopo il fade-in, la proprietà alpha rimane a 0.8, ma useremo un valore target variabile per le pulsazioni.

func _process(delta: float) -> void:
	# Rotazione
	rotation += rotation_speed * delta
	
	# Pulsazione continua della larghezza (effetto "energia instabile")
	_pulse_time += delta * 4.0  # velocità pulsazione
	var width_variation = sin(_pulse_time) * 2.0
	beam_line.width = _base_width + width_variation
	
	# Colore dinamico: variare leggermente la tonalità
	var color = beam_line.default_color
	color.r = 0.4 + sin(_pulse_time * 0.7) * 0.1
	color.b = 0.6 + cos(_pulse_time * 0.5) * 0.2
	beam_line.default_color = color
	
	# Danno al giocatore
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			Global.player_hp -= damage_per_second * delta
			Global.hurt = true

# Funzione chiamata quando il timer scade: dissolvenza in uscita
func _start_fade_out() -> void:
	# Ferma eventuali tween attivi
	if _tween: _tween.kill()
	
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(beam_line, "width", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(beam_line, "default_color:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _tween.finished
	queue_free()
