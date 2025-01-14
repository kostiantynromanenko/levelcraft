extends Node

func _ready() -> void:
	if OS.has_feature("headless"):
		print("Running in server mode")
		start_server()
	else:
		print("Running in client mode")
		start_client()

func start_server() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/server.tscn")

func start_client() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/client.tscn")
