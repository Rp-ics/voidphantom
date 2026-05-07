# SkillNode.gd
extends Area2D
class_name SkillNode

@export var skill_id: String
@export var connected_nodes: Array = [] # lista di skill_id dei figli
@onready var sprite = $star

func _ready():
	update_state()

func update_state():
	if skill_id in GlobalSkills.unlocked_skills:
		sprite.modulate = Color(0.8, 1, 0.8) # verde unlock
	elif _is_unlockedable():
		sprite.modulate = Color(1, 1, 0.6) # giallo pronto
	else:
		sprite.modulate = Color(0.5, 0.5, 0.5) # grigio locked

func _is_unlockedable() -> bool:
	for parent_id in connected_nodes:
		if parent_id in GlobalSkills.unlocked_skills:
			return true
	return false

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and _is_unlockedable():
		GlobalSkills.unlock_skill(skill_id)
		update_state()
		for child in connected_nodes:
			var node = get_node("../"+child)
			if node:
				node.update_state()
