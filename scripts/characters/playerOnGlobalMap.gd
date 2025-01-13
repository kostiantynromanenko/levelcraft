extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var move_timer: Timer = $MoveTimer
@onready var road_map: TileMapLayer = get_parent().get_node("RoadsLayer")

const SPEED = 200

var astar = AStar2D.new()
var target_position: Vector2
var is_moving = false
var can_move = true

var entrances_data = preload("res://scripts/map/entrances.gd").new()

func _ready() -> void:
	setup_animation()
	setup_move_timer()

func _process(delta: float) -> void:
	if is_moving:
		process_movement(delta)
	else:
		handle_input()

func _unhandled_input(event: InputEvent) -> void:
	if can_move and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		handle_mouse_click(event.position)

func setup_animation() -> void:
	animated_sprite.play("idle")

func setup_move_timer() -> void:
	move_timer.wait_time = 1.0
	move_timer.one_shot = true

func handle_input() -> void:
	if not can_move:
		return

	handle_keyboard_input()
	handle_manual_entrance_check()

func handle_keyboard_input() -> void:
	var direction = get_direction_from_input()
	if direction != Vector2i.ZERO:
		attempt_move_with_keys(direction)

func handle_manual_entrance_check() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		check_for_entrance(road_map.local_to_map(position))

func handle_mouse_click(mouse_position: Vector2) -> void:
	var local_position = road_map.to_local(mouse_position)
	var clicked_cell = road_map.local_to_map(local_position)

	if check_for_entrance(clicked_cell):
		return

	if is_valid_move(clicked_cell):
		start_movement(clicked_cell)

func get_direction_from_input() -> Vector2i:
	var direction = Vector2i.ZERO

	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	elif Input.is_action_pressed("ui_down"):
		direction.y += 1
	elif Input.is_action_pressed("ui_left"):
		animated_sprite.flip_h = true
		direction.x -= 1
	elif Input.is_action_pressed("ui_right"):
		animated_sprite.flip_h = false
		direction.x += 1

	return direction

func attempt_move_with_keys(direction: Vector2i) -> void:
	var current_cell = road_map.local_to_map(position)
	var target_cell = current_cell + direction

	if is_valid_move(target_cell):
		start_movement(target_cell)

func is_valid_move(cell: Vector2i) -> bool:
	return road_map.get_cell_source_id(cell) != -1

func start_movement(target_cell: Vector2i) -> void:
	target_position = road_map.map_to_local(target_cell)
	is_moving = true
	can_move = false
	move_timer.start()
	animated_sprite.play("walk")
	print("Starting movement to:", target_cell)

func process_movement(delta: float) -> void:
	position = position.move_toward(target_position, SPEED * delta)

	if position.distance_to(target_position) < 1:
		position = target_position
		is_moving = false
		animated_sprite.play("idle")
		print("Movement completed")

func check_for_entrance(cell: Vector2i) -> bool:
	if cell in entrances_data.entrances:
		handle_entrance(entrances_data.entrances[cell])
		return true
	return false

func handle_entrance(destination_scene: String) -> void:
	print("Entering location:", destination_scene)
	get_tree().change_scene_to_file(destination_scene)

func _on_move_timer_timeout() -> void:
	can_move = true
	print("Timer expired, movement unlocked")
