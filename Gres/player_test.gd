extends CharacterBody2D

var test_ability: TestAbility

func _ready():
	test_ability = TestAbility.new()
	add_child(test_ability)

func _process(delta):
	var dir = Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if dir != Vector2.ZERO:
		velocity = dir.normalized() * 300
		move_and_slide()

	if Input.is_action_just_pressed("skill_1"):
		test_ability.activate(global_position)
