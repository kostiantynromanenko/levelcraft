extends Node2D

@onready var global_map = $GlobalMap
@onready var player_list_window = $PlayerList
@onready var player_manager = $GlobalMap/PlayerManager

var server_ip = "127.0.0.1"
var server_port = 12345

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

func _on_peer_connected(_peer_id: int) -> void:
	pass

func _on_peer_disconnected(_peer_id: int) -> void:
	pass
