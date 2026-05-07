extends Area2D

@export var charge_time := 4.0      # Tempo di carica prima dell'attivazione
@export var pull_time := 6.0        # Durata dell'attrazione
@export var pull_force := 220.0      # Forza di risucchio
@onready var anim = $AnimationPlayer
@onready var sprite = $Sprite1

var active := false

func _ready():
	# All'inizio la Supernova si “carica”
	sprite.scale = Vector2.ZERO
	anim.play("charge")

	# Dopo charge_time secondi si attiva
	await get_tree().create_timer(charge_time).timeout
	activate()

func activate():
	active = true
	anim.play("active")

	# Dopo pull_time secondi esplode
	await get_tree().create_timer(pull_time).timeout
	explode()

func _physics_process(delta):
	if not active:
		return

	# Cicla tutti i player presenti nella scena
	for body in get_tree().get_nodes_in_group("player"):
		if not body or not body.is_inside_tree():
			continue

		# Calcola direzione verso il centro della Supernova
		var dir = (global_position - body.global_position).normalized()

		# Applica un’attrazione costante
		body.global_position += dir * pull_force * delta

		# Opzionale: se vuoi che l’attrazione aumenti vicino al centro
		# puoi moltiplicare la forza per un fattore inversamente proporzionale alla distanza:
		var dist = global_position.distance_to(body.global_position)
		var factor = clamp(1.0 / max(dist, 50.0), 0.2, 3.0)
		body.global_position += dir * pull_force * factor * delta

func explode():
	active = false
	GlobalTweens.explode_and_free(self, 1.0)

	# Attendi fine animazione e distruggi il nodo
	await anim.animation_finished
	queue_free()
