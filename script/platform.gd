extends Sprite2D

@export var speed := 800
var left_wall : Sprite2D
var right_wall : Sprite2D

func _physics_process(delta):
	if not left_wall or not right_wall:
		return

	var input_dir = 0
	if Input.is_action_pressed("ui_left"):
		input_dir -= 1
	if Input.is_action_pressed("ui_right"):
		input_dir += 1

	position.x += input_dir * speed * delta
	position.x = clamp(position.x, left_wall.texture.get_width(), right_wall.position.x - texture.get_width())
