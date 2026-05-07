extends Node

var mouse_scene := preload("res://Gres/Scenes/UI/mouse.tscn")
var mouse_instance: Node = null

func _ready():
	_spawn_mouse()
	get_tree().connect("node_added", Callable(self, "_on_node_added"))
	call_deferred("_attach_mouse")


func _spawn_mouse():
	# Ricrea l'istanza se non esiste o è stata freed
	if mouse_instance == null or not is_instance_valid(mouse_instance):
		mouse_instance = mouse_scene.instantiate()


func _on_node_added(node: Node):
	if node == get_tree().get_current_scene():
		call_deferred("_attach_mouse")


func _attach_mouse():
	_spawn_mouse()

	var root = get_tree().get_current_scene()
	if root == null:
		return

	# Se il mouse è già nel posto giusto, evita duplicati
	if mouse_instance.get_parent() == root:
		return

	# Se ha un vecchio parent, prima staccalo
	if is_instance_valid(mouse_instance.get_parent()):
		mouse_instance.get_parent().remove_child(mouse_instance)

	# Aggancia
	root.add_child(mouse_instance)
