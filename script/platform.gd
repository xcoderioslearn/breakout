extends CharacterBody2D

@export var speed := 800
var left_wall : StaticBody2D
var right_wall : StaticBody2D
var sprite : Sprite2D

func _ready():
	sprite = get_node("Sprite2D")

func _physics_process(delta):
	if not left_wall or not right_wall or not sprite:
		return
	var input_dir = 0
	if Input.is_action_pressed("ui_left"):
		input_dir -= 1
	if Input.is_action_pressed("ui_right"):
		input_dir += 1
	velocity = Vector2(input_dir * speed, 0)
	move_and_collide(velocity * delta)
	var left_sprite = left_wall.get_node("Sprite2D")
	var right_sprite = right_wall.get_node("Sprite2D")
	var half_width = sprite.texture.get_width() / 2
	position.x = clamp(
		position.x,
		left_sprite.texture.get_width() + half_width,
		right_wall.position.x - right_sprite.texture.get_width() - half_width
	)
