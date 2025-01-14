extends Node

var connected_players = {}

func _ready() -> void:
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(12345)

	if result == OK:
		multiplayer.network_peer = peer
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		print("Server started on port 12345")
	else:
		print("Failed to start server")
		get_tree().quit()

func _on_peer_connected(peer_id: int) -> void:
	print("Player connected:", peer_id)

	connected_players[peer_id] = Vector2.ZERO

	rpc("spawn_player", peer_id)

	for id in connected_players.keys():
		if id != peer_id:
			rpc_id(peer_id, "spawn_player", id)
			rpc_id(peer_id, "update_position", id, connected_players[id])

func _on_peer_disconnected(peer_id: int) -> void:
	print("Player disconnected:", peer_id)

	connected_players.erase(peer_id)

	rpc("remove_player", peer_id)

@rpc
func update_player_position(player_id: int, position: Vector2) -> void:
	if connected_players.has(player_id):
		connected_players[player_id] = position
		rpc("update_position", player_id, position)
