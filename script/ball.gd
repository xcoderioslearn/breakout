extends CharacterBody2D

@export var speed := 600

var platform : Sprite2D
var left_wall : Sprite2D
var right_wall : Sprite2D
var top_wall : Sprite2D

var launched := false

func _ready():
	add_to_group("ball")
	if platform:
		_set_position_on_platform()

func _physics_process(delta):
	if not platform or not left_wall or not right_wall or not top_wall:
		return

	var ball_sprite = get_node("Sprite2D") as Sprite2D

	if not launched:
		_set_position_on_platform()
		if Input.is_action_just_pressed("ui_select"):
			launched = true
			velocity = Vector2(0, -speed)
	else:
		move_and_slide()
		_bounce_off_walls_and_platform(ball_sprite)

func _set_position_on_platform():
	var ball_sprite = get_node("Sprite2D") as Sprite2D
	position = Vector2(
		platform.position.x + platform.texture.get_width()/2 - ball_sprite.texture.get_width()/2,
		platform.position.y - ball_sprite.texture.get_height()
	)

func _bounce_off_walls_and_platform(ball_sprite):
	var viewport_size = get_viewport_rect().size

	# Left/right walls
	if position.x < left_wall.texture.get_width():
		position.x = left_wall.texture.get_width()
		velocity.x = -velocity.x
	elif position.x + ball_sprite.texture.get_width() > viewport_size.x - right_wall.texture.get_width():
		position.x = viewport_size.x - right_wall.texture.get_width() - ball_sprite.texture.get_width()
		velocity.x = -velocity.x

	# Top wall
	if position.y < top_wall.texture.get_height():
		position.y = top_wall.texture.get_height()
		velocity.y = -velocity.y

	# Platform
	var plat_rect = Rect2(platform.position, platform.texture.get_size())
	var ball_rect = Rect2(position, ball_sprite.texture.get_size())
	if plat_rect.intersects(ball_rect) and velocity.y > 0:
		velocity.y = -abs(velocity.y)
		var hit_pos = (position.x + ball_sprite.texture.get_width()/2) - platform.position.x
		var rel = (hit_pos / platform.texture.get_width()) - 0.5
		velocity.x = rel * speed * 2

func on_brick_hit():
	velocity.y = -velocity.y
