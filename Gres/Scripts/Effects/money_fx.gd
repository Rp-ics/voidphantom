extends Node2D
# export vars
@export var speed: float = 100.0 # velocità di movimento
@export var pause_time: float = 0.5 # pausa tra un punto e l'ltro
@export var waypoints: Array[Marker2D] # lista dei punti da dove a dove deve andare

var current_index: int = 0 # index attuale
var is_moving: bool = true # controllo movimento
var player: CharacterBody2D = null # chi deve trasportare (puoi mettere anche più di un nodo)

func _ready() -> void:
	
	if waypoints.size() > 0:
		# posizionare la piattaforma nel primo punto
		global_position = waypoints[0].global_position 
	
func _process(delta: float) -> void:
	# Se è in pausa o ci sono meno di 2 punti, non fare nulla
	if not is_moving or waypoints.size() < 2:
		return
	
	var target_position = waypoints[current_index].global_position
	var direction = (target_position - global_position).normalized()
	var movement = direction * speed * delta
	
	# Agevolare il movimento per renderlo fluido
	var distance = global_position.distance_to(target_position)
	var eased_speed = speed * (distance / 40.0) # slow down as it get closer
	
	if distance <= speed * delta:
		# si allineano perfettamente con il nodo (il punto)
		global_position = target_position
		_next_waypoint() # si muove al prossimo nodo (punto)
	else:
		global_position += movement * eased_speed / speed # smooth movement
	
	# se il giocatore si trova sopra la piattaforma, lo sposta con essa
	if player:
		player.global_position += movement * eased_speed / speed
	
func _next_waypoint():
	is_moving = false # stoppa il movimento
	await get_tree().create_timer(pause_time).timeout # attende
	# muovi verso il prossimo punto
	current_index = (current_index + 1) % waypoints.size()
	is_moving = true # può muoversi
	


func _on_platform_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		
	
func _on_platform_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
