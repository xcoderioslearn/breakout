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

const BRICKS_PER_ROW := 14

var left_wall : StaticBody2D
var right_wall : StaticBody2D
var top_wall : StaticBody2D
var platform : CharacterBody2D
var ball : RigidBody2D
var bricks := []

var score := 0
var total_hits := 0
var red_row_cleared := false
@onready var score_label : Label = $ScoreLabel

func _ready():
	_spawn_walls()
	_spawn_bricks()
	_spawn_platform_and_ball()
	_update_score(0)

func _spawn_walls():
	var viewport_size = get_viewport_rect().size

	top_wall = TOP_WALL.instantiate() as StaticBody2D
	add_child(top_wall)
	var top_sprite = top_wall.get_node("Sprite2D")
	top_wall.position = Vector2(viewport_size.x / 2, top_sprite.texture.get_height() / 2)

	left_wall = SIDE_WALL.instantiate() as StaticBody2D
	add_child(left_wall)
	var left_sprite = left_wall.get_node("Sprite2D")
	left_wall.position = Vector2(
		left_sprite.texture.get_width() / 2,
		(viewport_size.y / 2) + (top_sprite.texture.get_height() / 2)
	)

	right_wall = SIDE_WALL.instantiate() as StaticBody2D
	add_child(right_wall)
	var right_sprite = right_wall.get_node("Sprite2D")
	right_wall.position = Vector2(
		viewport_size.x - right_sprite.texture.get_width() / 2,
		(viewport_size.y / 2) + (top_sprite.texture.get_height() / 2)
	)

func _spawn_bricks():
	var viewport_size = get_viewport_rect().size
	var top_sprite = top_wall.get_node("Sprite2D")
	var top_edge_y = top_wall.position.y + top_sprite.texture.get_height() / 2 + 10
	for row in range(brick_scenes.size()):
		var scene = brick_scenes[row]
		for col in range(BRICKS_PER_ROW):
			var brick = scene.instantiate() as StaticBody2D
			var brick_sprite = brick.get_node("Sprite2D")

			var left_edge = left_wall.get_node("Sprite2D").texture.get_width()
			var right_edge = viewport_size.x - right_wall.get_node("Sprite2D").texture.get_width()
			var available_width = right_edge - left_edge

			var brick_width = brick_sprite.texture.get_width()
			brick.scale.x = available_width / (BRICKS_PER_ROW * brick_width)

			var x_pos = left_edge + (col + 0.5) * (brick_width * brick.scale.x)
			var y_pos = top_edge_y + row * brick_sprite.texture.get_height()
			brick.position = Vector2(x_pos, y_pos)

			brick.set_meta("row_index", row)
			add_child(brick)
			bricks.append(brick)
			brick.add_to_group("bricks")

func _spawn_platform_and_ball():
	var viewport_size = get_viewport_rect().size

	platform = PLATFORM_SCENE.instantiate() as CharacterBody2D
	add_child(platform)
	var plat_sprite = platform.get_node("Sprite2D")
	platform.position = Vector2(
		viewport_size.x / 2,
		viewport_size.y - plat_sprite.texture.get_height() / 2 - 10
	)
	platform.left_wall = left_wall
	platform.right_wall = right_wall

	ball = BALL_SCENE.instantiate() as RigidBody2D
	add_child(ball)
	ball.reset_ball(platform)  # ensures ball starts on platform

	ball.connect("brick_destroyed", Callable(self, "_on_brick_destroyed"))
	ball.connect("ball_lost", Callable(self, "_on_ball_lost"))
	ball.connect("top_wall_hit", Callable(self, "_on_top_wall_hit"))

func _update_score(value: int):
	score = value
	if score_label:
		score_label.text = "Score: %d" % score

func _on_brick_destroyed(row_index: int):
	total_hits += 1
	var points := match row_index:
		5, 4: 1
		3, 2: 3
		1: 5
		0: 7
		_: 0
	_update_score(score + points)

	if total_hits in [4, 12] or row_index <= 1:
		if ball and ball.has_method("increase_speed"):
			ball.increase_speed()

	if row_index == 4:
		var red_remaining := false
		for b in get_tree().get_nodes_in_group("bricks"):
			if b.get_meta("row_index") == 4:
				red_remaining = true
				break
		if not red_remaining:
			red_row_cleared = true

func _on_top_wall_hit():
	if red_row_cleared and platform:
		platform.scale.x *= 0.5
		red_row_cleared = false

func _on_ball_lost():
	_update_score(0)
	total_hits = 0
	red_row_cleared = false
	if platform:
		platform.scale.x = 1.0
	if ball:
		ball.reset_ball(platform)
