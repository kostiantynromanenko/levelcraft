extends Node2D

@onready var player_scene = preload("res://client/scenes/characters/player.tscn")
@onready var roads_layer = $"../RoadsLayer"

var players = {}

func notify_of_position(player_id: int, updated_position: Vector2) -> void: 
	rpc_id(1, "update_player_position", player_id, updated_position)

@rpc("authority", "call_remote", "reliable")
func spawn_player(player_id: int) -> void:
	if players.has(player_id):
		return

	print("Spawning player with ID:", player_id)

	var player_instance = player_scene.instantiate()
	player_instance.name = "Player_" + str(player_id)
	player_instance.visible = true
	player_instance.player_id = player_id
	player_instance.position = Vector2(72, 376)
	player_instance.is_local_player = (player_id == multiplayer.get_unique_id())
	players[player_id] = player_instance

	add_child(player_instance)

@rpc("authority", "call_remote", "reliable")
func update_position(player_id: int, new_position: Vector2) -> void:
	if players.has(player_id):
		players[player_id].position = new_position

@rpc("authority", "call_remote", "reliable")
func remove_player(player_id: int) -> void:
	if players.has(player_id):
		players[player_id].queue_free()
		players.erase(player_id)
		print("Removed player with ID:", player_id)

@rpc
func update_player_position(_player_id: int, _position: Vector2) -> void:
	pass
