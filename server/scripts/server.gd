extends Node

@onready var player_manager = $GlobalMap/PlayerManager

var port = 12345

func _ready() -> void:
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port)

	if result == OK:
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		print("Server started on port: ", port)
	else:
		print("Failed to start server")
		get_tree().quit()

func _on_peer_connected(peer_id: int) -> void:
	print("Player connected:", peer_id)

	player_manager.notify_on_player_spawn(peer_id)

	for id in player_manager.connected_players.keys():
		if id != peer_id:
			player_manager.notify_peer_on_player_spawn(peer_id, id)
			player_manager.notify_on_update_position(peer_id, id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("Player disconnected:", peer_id)
	player_manager.notify_on_player_remove(peer_id)
