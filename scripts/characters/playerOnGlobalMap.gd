extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var move_timer: Timer = $MoveTimer
@onready var road_map: TileMapLayer = get_parent().get_node("RoadsLayer")

const SPEED = 200

var astar = AStar2D.new()
var path = []
var current_path_index = 0
var is_moving = false
var can_move = true
var target_position: Vector2

# Multiplayer properties
var player_id = -1  # Unique ID assigned by the server
var is_local_player = false  # True if this instance represents the local player

var entrances_data = preload("res://scripts/map/entrances.gd").new()

func _ready() -> void:
	setup_animation()
	setup_move_timer()
	populate_astar()

func _process(delta: float) -> void:
	if is_local_player:
		handle_input()

	if is_moving:
		if path.size() > 0:
			process_path_movement(delta)
		else:
			process_keyboard_movement(delta)

func _unhandled_input(event: InputEvent) -> void:
	if is_local_player and can_move and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		handle_mouse_click(event.position)

func setup_animation() -> void:
	animated_sprite.play("idle")

func setup_move_timer() -> void:
	move_timer.wait_time = 0.5  # Half a second delay between moves
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
	var current_cell = road_map.local_to_map(position)

	if clicked_cell == current_cell:
		check_for_entrance(clicked_cell)
		return

	if astar.has_point(cell_to_id(clicked_cell)):
		calculate_path(current_cell, clicked_cell)

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
		start_keyboard_movement(target_cell)

		# Notify the server about the new position
		if is_local_player:
			rpc_id(1, "update_player_position", player_id, position)

func populate_astar() -> void:
	var used_cells = road_map.get_used_cells()

	for cell in used_cells:
		var id = cell_to_id(cell)
		astar.add_point(id, cell)

	for cell in used_cells:
		var id = cell_to_id(cell)
		for neighbor_offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
			var neighbor = cell + neighbor_offset
			if neighbor in used_cells:
				var neighbor_id = cell_to_id(neighbor)
				if astar.has_point(neighbor_id):
					astar.connect_points(id, neighbor_id)

func is_valid_move(cell: Vector2i) -> bool:
	return road_map.get_cell_source_id(cell) != -1

func cell_to_id(cell: Vector2i) -> int:
	return cell.x + cell.y * road_map.get_used_rect().size.x

func calculate_path(start_cell: Vector2i, target_cell: Vector2i) -> void:
	path = astar.get_point_path(cell_to_id(start_cell), cell_to_id(target_cell))
	current_path_index = 0
	if path.size() > 0:
		start_path_movement()

func start_path_movement() -> void:
	is_moving = true
	animated_sprite.play("walk")
	move_timer.start()

func process_path_movement(delta: float) -> void:
	if current_path_index < path.size():
		target_position = road_map.map_to_local(path[current_path_index])
		position = position.move_toward(target_position, SPEED * delta)

		if position.distance_to(target_position) < 1:
			position = target_position
			current_path_index += 1

			if current_path_index < path.size():
				var next_position = road_map.map_to_local(path[current_path_index])
				animated_sprite.flip_h = next_position.x < position.x

			move_timer.start()  # Restart timer for delay
			can_move = false

		# Notify the server about path movement
		if is_local_player:
			rpc_id(1, "update_player_position", player_id, position)
	else:
		path.clear()
		is_moving = false
		animated_sprite.play("idle")

func start_keyboard_movement(target_cell: Vector2i) -> void:
	target_position = road_map.map_to_local(target_cell)
	is_moving = true
	can_move = false
	move_timer.start()
	animated_sprite.play("walk")

func process_keyboard_movement(delta: float) -> void:
	position = position.move_toward(target_position, SPEED * delta)

	if position.distance_to(target_position) < 1:
		position = target_position
		is_moving = false
		animated_sprite.play("idle")

		# Notify the server about position after keyboard movement
		if is_local_player:
			rpc_id(1, "update_player_position", player_id, position)

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

@rpc
func update_position(new_position: Vector2) -> void:
	# For remote players, update position directly
	if not is_local_player:
		target_position = new_position
		is_moving = true
