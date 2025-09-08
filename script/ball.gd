extends RigidBody2D

@export var speed := 600

var platform : CharacterBody2D
var launched := false

signal brick_destroyed(row_index: int)
signal ball_lost
signal top_wall_hit

func _ready():
	sleeping = true
	gravity_scale = 0.0
	contact_monitor = true
	max_contacts_reported = 1
	add_to_group("ball")
	body_entered.connect(_on_body_entered)

func _physics_process(_delta):
	if not launched:
		_set_position_on_platform()
		if Input.is_action_just_pressed("ui_select"):
			launched = true
			sleeping = false
			linear_velocity = Vector2(0, -speed)

	_check_ball_out_of_bounds()

func _set_position_on_platform():
	if platform:
		var ball_sprite = get_node("Sprite2D")
		var plat_sprite = platform.get_node("Sprite2D")
		position = Vector2(
			platform.position.x,
			platform.position.y - plat_sprite.texture.get_height()/2 - ball_sprite.texture.get_height()/2
		)

func _check_ball_out_of_bounds():
	var viewport_size = get_viewport_rect().size
	if position.y > viewport_size.y:
		emit_signal("ball_lost")

func reset_ball(plat: CharacterBody2D):
	platform = plat
	launched = false
	sleeping = true
	linear_velocity = Vector2.ZERO
	_set_position_on_platform()

func increase_speed():
	speed += 100
	if launched:
		linear_velocity = linear_velocity.normalized() * speed

func _on_body_entered(body: Node):
	if body.is_in_group("bricks"):
		var row_index = body.get_meta("row_index") if body.has_meta("row_index") else 0
		body.queue_free()
		emit_signal("brick_destroyed", row_index)

	if body == platform:
		var plat_sprite = platform.get_node("Sprite2D")
		var hit_pos = (position.x - platform.position.x) / (plat_sprite.texture.get_width()/2)
		linear_velocity.x = hit_pos * speed
		linear_velocity = linear_velocity.normalized() * speed

	if body.name == "TopWall":
		emit_signal("top_wall_hit")
