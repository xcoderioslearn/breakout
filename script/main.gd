extends Node2D

var brick_scenes := [
	preload("res://scenes/color_6_bricks.tscn"),
	preload("res://scenes/color_5_bricks.tscn"),
	preload("res://scenes/color_4_bricks.tscn"),
	preload("res://scenes/color_3_bricks.tscn"),
	preload("res://scenes/color_2_bricks.tscn"),
	preload("res://scenes/color_1_bricks.tscn")
]

const SIDE_WALL := preload("res://scenes/side_wall.tscn")
const TOP_WALL := preload("res://scenes/top_wall.tscn")
const PLATFORM_SCENE := preload("res://scenes/platform.tscn")
const BALL_SCENE := preload("res://scenes/ball.tscn")

const BRICKS_PER_ROW := 18
const BRICK_HEIGHT := 44

var left_wall : Sprite2D
var right_wall : Sprite2D
var top_wall : Sprite2D
var platform : Sprite2D
var ball : CharacterBody2D
var bricks := []

func _ready():
	_spawn_walls()
	_spawn_bricks()
	_spawn_platform_and_ball()

func _spawn_walls():
	var viewport_size = get_viewport_rect().size

	left_wall = SIDE_WALL.instantiate()
	left_wall.position = Vector2(0, 0)
	left_wall.scale.y = viewport_size.y / left_wall.texture.get_height()
	add_child(left_wall)

	right_wall = SIDE_WALL.instantiate()
	right_wall.position = Vector2(viewport_size.x - right_wall.texture.get_width(), 0)
	right_wall.scale.y = viewport_size.y / right_wall.texture.get_height()
	add_child(right_wall)

	top_wall = TOP_WALL.instantiate()
	var top_wall_width = top_wall.texture.get_width()
	top_wall.position = Vector2((viewport_size.x - top_wall_width) / 2, 0)
	add_child(top_wall)

func _spawn_bricks():
	var viewport_size = get_viewport_rect().size
	var y_start = top_wall.texture.get_height() + 20

	for row in range(brick_scenes.size()):
		var scene = brick_scenes[row]
		for col in range(BRICKS_PER_ROW):
			var brick = scene.instantiate()
			var wall_margin_left = left_wall.texture.get_width()
			var wall_margin_right = right_wall.texture.get_width()
			var available_width = viewport_size.x - wall_margin_left - wall_margin_right
			var brick_width_original = brick.texture.get_width()
			var brick_scale_x = available_width / (BRICKS_PER_ROW * brick_width_original)
			brick.scale.x = brick_scale_x

			var x_pos = wall_margin_left + col * (brick_width_original * brick_scale_x)
			var y_pos = y_start + row * BRICK_HEIGHT
			brick.position = Vector2(x_pos, y_pos)

			add_child(brick)
			bricks.append(brick)
			brick.add_to_group("bricks")

func _spawn_platform_and_ball():
	var viewport_size = get_viewport_rect().size

	platform = PLATFORM_SCENE.instantiate() as Sprite2D
	platform.position.x = viewport_size.x / 2 - platform.texture.get_width() / 2
	platform.position.y = viewport_size.y - platform.texture.get_height() - 10
	platform.left_wall = left_wall
	platform.right_wall = right_wall
	add_child(platform)

	ball = BALL_SCENE.instantiate() as CharacterBody2D
	ball.platform = platform
	ball.left_wall = left_wall
	ball.right_wall = right_wall
	ball.top_wall = top_wall
	add_child(ball)
