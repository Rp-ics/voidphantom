extends Node
class_name EnemySkill

var enemy: BaseEnemy

func _init(_enemy: BaseEnemy) -> void:
	enemy = _enemy

func activate() -> void:
	# Da override nelle skill concrete
	push_warning("activate() non implementata in %s" % get_class())

func deactivate() -> void:
	# Default: si autodistrugge
	queue_free()
