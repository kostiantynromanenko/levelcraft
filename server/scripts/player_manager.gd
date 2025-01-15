extends Node

var connected_players = {}

func notify_on_player_spawn(player_id: int) -> void:
	connected_players[player_id] = Vector2.ZERO
	rpc("spawn_player", player_id)
	
func notify_peer_on_player_spawn(peer_id: int, player_id: int) -> void:
	rpc_id(peer_id, "spawn_player", player_id)
	
func notify_on_player_remove(player_id: int) -> void:
	connected_players.erase(player_id)
	rpc("remove_player", player_id)
	
func notify_on_update_position(peer_id: int, player_id: int) -> void:
	rpc_id(peer_id, "update_position", player_id, connected_players[player_id])

@rpc("any_peer", "call_remote", "reliable")
func update_player_position(player_id: int, position: Vector2) -> void:
	if connected_players.has(player_id):
		connected_players[player_id] = position
		rpc("update_position", player_id, position)

@rpc
func spawn_player(_player_id: int) -> void:
	pass

@rpc
func remove_player(_player_id: int) -> void:
	pass

@rpc
func update_position(_player_id: int, _new_position: Vector2) -> void:
	pass
