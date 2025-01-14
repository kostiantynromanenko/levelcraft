extends Control

@onready var player_list_container = $VBoxContainer

func update_player_list(player_list: Array) -> void:
	for child in player_list_container.get_children():
		player_list_container.remove_child(child)
		child.queue_free()

	for player_id in player_list:
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 8)
		label.text = "Player " + str(player_id)
		player_list_container.add_child(label)
