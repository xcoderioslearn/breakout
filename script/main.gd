extends Node2D
# Paddle
const SCREEN_SIZE := Vector2(1920, 1080)
const PADDLE_HEIGHT := 14.0
const PADDLE_WIDTH := 350
const PADDLE_SPEED := 2000
const PADDLE_SHRINK_FACTOR := 0.8
const BALL_RADIUS := 30.0

const BRICK_ROWS := 8
const BRICK_COLS := 14
const BRICK_WIDTH := SCREEN_SIZE.x / BRICK_COLS
const BRICK_MARGIN := Vector2(0, 40)
const BRICK_HEIGHT := 20.0

const COLOR_ORDER := [Color8(255, 230, 102), Color8(137, 209, 126), Color8(255, 180, 102), Color8(255, 102, 102)]
const COLOR_POINTS := [7, 5, 3, 1]

const HIT_SPEED_STEPS := [4, 12]
const BASE_BALL_SPEED := 1000.0
const SPEED_MULTIPLIER := 1.05
const MAX_BALL_SPEED := 1500.0

var paddle_pos := Vector2(SCREEN_SIZE.x / 2.0, SCREEN_SIZE.y - 40)
var paddle_width := PADDLE_WIDTH
var ball_pos := Vector2(SCREEN_SIZE.x / 2.0, SCREEN_SIZE.y - 100)
var ball_vel := Vector2(0, 0)
var ball_speed := BASE_BALL_SPEED
var ball_in_play := false
var lives := 5
var score := 0
var current_screen := 1
var max_screens := 2
var bricks := []
var hit_count := 0
var paddle_shrunk := false
var orange_row_y := 0.0
var red_row_y := 0.0

var brick_scale := 1.0
var brick_cols := BRICK_COLS

var lbl_score
var lbl_lives
var lbl_notify

func _ready():
	get_viewport().size = SCREEN_SIZE
	randomize()
	_create_labels()
	_reset_round(true)
	set_physics_process(true)
	queue_redraw()

func _create_labels():
	lbl_score = Label.new()
	lbl_score.position = Vector2(30, 800)
	lbl_score.add_theme_font_size_override("font_size", 90)
	lbl_score.add_theme_color_override("font_color", Color8(255, 255, 255))
	add_child(lbl_score)

	lbl_lives = Label.new()
	lbl_lives.position = Vector2(1592, 800)
	lbl_lives.add_theme_font_size_override("font_size", 90)
	lbl_lives.add_theme_color_override("font_color", Color8(255, 255, 255))
	add_child(lbl_lives)

	lbl_notify = Label.new()
	lbl_notify.position = Vector2(SCREEN_SIZE.x/2 - 220 , SCREEN_SIZE.y/2 )
	lbl_notify.add_theme_font_size_override("font_size", 32)
	lbl_notify.add_theme_color_override("font_color", Color8(255, 255, 0))
	lbl_notify.visible = false
	lbl_notify.modulate.a = 0.0
	set_process(true)
	add_child(lbl_notify)

func _reset_round(full_reset: bool=false):
	if full_reset:
		lives = 5
		score = 0
		current_screen = 1
		brick_scale = 1.0
		brick_cols = BRICK_COLS
	paddle_width = PADDLE_WIDTH
	paddle_shrunk = false
	ball_speed = BASE_BALL_SPEED
	hit_count = 0
	_generate_bricks()
	_reset_ball_on_paddle()
	_show_notify("Press SPACE to launch a ball", true)
	queue_redraw()

func _generate_bricks():
	bricks.clear()
	orange_row_y = 0.0
	red_row_y = 0.0
	var scaled_width = BRICK_WIDTH * brick_scale
	var scaled_height = BRICK_HEIGHT * brick_scale
	for r in range(BRICK_ROWS):
		var color_group = int(r / 2)
		for c in range(brick_cols):
			var x = c * scaled_width
			var y = BRICK_MARGIN.y + r * (scaled_height + 4)
			var rect = Rect2(x, y, scaled_width, scaled_height)
			bricks.append({"rect":rect, "color_index":color_group, "alive":true})
			if color_group == 2:
				if orange_row_y != 0.0:
					orange_row_y = min(orange_row_y, y)
				else:
					orange_row_y = y
			if color_group == 3:
				if red_row_y != 0.0:
					red_row_y = min(red_row_y, y)
				else:
					red_row_y = y

func _reset_ball_on_paddle():
	ball_in_play = false
	ball_pos = paddle_pos - Vector2(0, 36)
	ball_vel = Vector2(0, -1)
	ball_speed = min(BASE_BALL_SPEED, MAX_BALL_SPEED)


func _input(event):
	if not get_tree().paused:  # Only process input when not paused
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_SPACE:
				if not ball_in_play:
					_launch_ball()
			elif event.keycode == KEY_P:
				get_tree().paused = not get_tree().paused
			elif event.keycode == KEY_R:
				_reset_round(true)
				_hide_notify()

func _show_notify(text:String, fade_out:bool=true):
	lbl_notify.text = text
	lbl_notify.visible = true
	lbl_notify.modulate.a = 1.0
	if fade_out:
		var tween = create_tween()
		tween.tween_property(lbl_notify, "modulate:a", 0.0, 2.0).set_delay(2.0)

func _hide_notify():
	lbl_notify.visible = false
	lbl_notify.modulate.a = 0.0

func _launch_ball():
	ball_in_play = true
	var ang = randf_range(-0.6, 0.6)
	ball_vel = Vector2(sin(ang), -abs(cos(ang))).normalized()
	ball_speed = min(BASE_BALL_SPEED, MAX_BALL_SPEED)


func _circle_intersects_rect(center:Vector2, radius:float, rect:Rect2) -> bool:
	var closest = Vector2(clamp(center.x, rect.position.x, rect.position.x + rect.size.x), clamp(center.y, rect.position.y, rect.position.y + rect.size.y))
	return center.distance_to(closest) <= radius

func _circle_rect_collision_response(prev_pos:Vector2, next_pos:Vector2, radius:float, rect:Rect2) -> Vector2:
	var center = next_pos
	var rect_center = rect.position + rect.size * 0.5
	var dx = (center.x - rect_center.x) / (rect.size.x * 0.5)
	var dy = (center.y - rect_center.y) / (rect.size.y * 0.5)
	if abs(dx) > abs(dy):
		return Vector2(1 if dx > 0 else -1, 0)
	else:
		return Vector2(0, 1 if dy > 0 else -1)

# --- Physics ---

func _physics_process(delta):
	var move = 0
	if Input.is_action_pressed("ui_left"):
		move -= 1
	if Input.is_action_pressed("ui_right"):
		move += 1
	if move != 0:
		paddle_pos.x = clamp(paddle_pos.x + move * PADDLE_SPEED * delta, paddle_width/2, SCREEN_SIZE.x - paddle_width/2)
		if not ball_in_play:
			ball_pos.x = paddle_pos.x

	if ball_in_play:
		var travel = ball_vel * ball_speed * delta
		var steps = 5 
		var step_travel = travel / steps
		for i in range(steps):
			var next_pos = ball_pos + step_travel
			if next_pos.x - BALL_RADIUS <= 0:
				ball_vel.x = abs(ball_vel.x)
				next_pos.x = BALL_RADIUS
			elif next_pos.x + BALL_RADIUS >= SCREEN_SIZE.x:
				ball_vel.x = -abs(ball_vel.x)
				next_pos.x = SCREEN_SIZE.x - BALL_RADIUS
			if next_pos.y - BALL_RADIUS <= 0:
				ball_vel.y = abs(ball_vel.y)
				next_pos.y = BALL_RADIUS
				if not paddle_shrunk and _red_row_broken():
					paddle_width *= PADDLE_SHRINK_FACTOR
					paddle_shrunk = true
			if next_pos.y + BALL_RADIUS >= paddle_pos.y - PADDLE_HEIGHT/2:
				var paddle_rect = Rect2(Vector2(paddle_pos.x - paddle_width/2, paddle_pos.y - PADDLE_HEIGHT/2), Vector2(paddle_width, PADDLE_HEIGHT))
				if paddle_rect.has_point(Vector2(next_pos.x, paddle_pos.y)) and ball_vel.y > 0:
					var hit_pos = (next_pos.x - paddle_pos.x) / (paddle_width/2)
					var angle = lerp(-PI/3, PI/3, (hit_pos + 1) / 2.0)
					ball_vel = Vector2(sin(angle), -cos(angle)).normalized()
					next_pos.y = paddle_pos.y - PADDLE_HEIGHT/2 - BALL_RADIUS
			if next_pos.y - BALL_RADIUS > SCREEN_SIZE.y:
				_lose_ball()
				return
			for b in bricks.duplicate():
				if not b["alive"]:
					continue
				var r = b["rect"]
				if _circle_intersects_rect(next_pos, BALL_RADIUS, r):
					b["alive"] = false
					var col_idx = b["color_index"]
					score += COLOR_POINTS[col_idx]
					var overlap = _circle_rect_collision_response(ball_pos, next_pos, BALL_RADIUS, r)
					if overlap != Vector2.ZERO:
						ball_vel = (ball_vel + overlap.normalized()).normalized()
					else:
						ball_vel.y *= -1
					hit_count += 1
					if hit_count in HIT_SPEED_STEPS:
						ball_speed = min(ball_speed * SPEED_MULTIPLIER, MAX_BALL_SPEED)
					if col_idx >= 2:
						ball_speed = min(ball_speed * SPEED_MULTIPLIER, MAX_BALL_SPEED)
					# Recalculate next_pos after each collision
					next_pos = ball_pos + ball_vel.normalized() * ball_speed * delta / steps
			ball_pos = next_pos
			if ball_vel.length() == 0:
				ball_vel = Vector2(0, -1)
			if _all_bricks_cleared():
				_screen_cleared()
	_update_ui()
	queue_redraw()

func _lose_ball():
	ball_in_play = false
	lives -= 1
	if lives <= 0:
		_reset_round(true)
	else:
		_reset_ball_on_paddle()
		_show_notify("Press SPACE to launch a ball", true)

func _all_bricks_cleared() -> bool:
	for b in bricks:
		if b["alive"]:
			return false
	return true

func _screen_cleared():
	if current_screen >= max_screens:
		_show_notify("Screen %d cleared. Game over.\nPress R to restart" % current_screen, false)
		ball_in_play = false
	else:
		current_screen += 1
		if current_screen == 2:
			brick_scale = 0.5
			brick_cols = BRICK_COLS * 2
		_generate_bricks()
		_reset_ball_on_paddle()
		paddle_width = PADDLE_WIDTH
		paddle_shrunk = false
		ball_speed = BASE_BALL_SPEED
		hit_count = 0
		_show_notify("Screen cleared! Starting screen %d" % current_screen, true)
		var tween = create_tween()
		tween.tween_callback(func(): _show_notify("Press SPACE to launch a ball", true)).set_delay(2.5)

func _red_row_broken() -> bool:
	for b in bricks:
		if b["alive"] and b["color_index"] == 3:
			return false
	return true

func _update_ui():
	lbl_score.text = "Score: %d" % score
	lbl_lives.text = "Lives: %d" % lives

func _draw():
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color8(12,12,20))
	for b in bricks:
		if not b["alive"]:
			continue
		var r = b["rect"]
		var color_idx = b["color_index"]
		var col = COLOR_ORDER[color_idx]
		draw_rect(r, col)
		draw_rect(Rect2(r.position, r.size), col.darkened(0.15), false, 2)
	var paddle_rect = Rect2(Vector2(paddle_pos.x - paddle_width/2, paddle_pos.y - PADDLE_HEIGHT/2), Vector2(paddle_width, PADDLE_HEIGHT))
	draw_rect(paddle_rect, Color8(200,200,220))
	draw_rect(paddle_rect, Color8(50,50,70), false, 2)
	draw_circle(ball_pos, BALL_RADIUS, Color8(240,240,255))
	draw_circle(ball_pos, BALL_RADIUS, Color8(100,100,130), false, 2)
