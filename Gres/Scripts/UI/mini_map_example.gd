extends Control

@export var player_path: NodePath           # reference al player
@export var enemy_group: String = "enemy_ex"   # gruppo nemici

var player: Node2D

func _ready() -> void:
	if player_path != NodePath():
		player = get_node(player_path)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw() # ridisegna ogni frame


func _draw() -> void:
	# --- 1. Cerchio di base ---
	draw_circle(Vector2.ZERO, Global.radar_radius, Color(0, 0, 0, 0.5)) # background semi-trasparente
	draw_arc(Vector2.ZERO, Global.radar_radius, 0, TAU, 64, Color(1, 1, 1, 0.7), 2) # bordo bianco

	# --- 2. Player (centro radar) ---
	draw_circle(Vector2.ZERO, 4, Color(0.2, 0.6, 1)) # azzurro

	# --- 3. Nemici ---
	if not player:
		return

	for enemy in get_tree().get_nodes_in_group(enemy_group):
		if not enemy is Node2D:
			continue

		var relative_pos: Vector2 = (enemy.global_position - player.global_position)
		# converto in spazio radar
		var radar_pos = relative_pos / Global.radar_range * Global.radar_radius

		# clamp se fuori range
		if radar_pos.length() > Global.radar_radius:
			radar_pos = radar_pos.normalized() * Global.radar_radius

		draw_circle(radar_pos, 3, Color(1, 0.2, 0.2)) # rosso
