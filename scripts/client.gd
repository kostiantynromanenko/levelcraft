extends Node2D

@onready var player_scene = preload("res://scenes/characters/player.tscn")
@onready var road_map = $GlobalMap/RoadsLayer
@onready var player_list_window = $PlayerList

var server_ip = "127.0.0.1"
var server_port = 12345

var players = {}

func _ready() -> void:
	connect_to_server()

func connect_to_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(server_ip, server_port)

	if result == OK:
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		print("Connected to server")
	else:
		print("Failed to connect to server")

func _on_peer_connected(peer_id: int) -> void:
	print("Player connected with ID:", peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("Player disconnected with ID:", peer_id)

	if players.has(peer_id):
		players[peer_id].queue_free()
		players.erase(peer_id)

@rpc
func spawn_player(player_id: int) -> void:
	if players.has(player_id):
		return

	print("Spawning player with ID:", player_id)

	var player_instance = player_scene.instance()
	player_instance.player_id = player_id
	player_instance.is_local_player = (player_id == multiplayer.get_unique_id())
	players[player_id] = player_instance

	road_map.add_child(player_instance)

	player_instance.position = Vector2.ZERO

@rpc
func update_position(player_id: int, new_position: Vector2) -> void:
	if players.has(player_id):
		players[player_id].position = new_position
