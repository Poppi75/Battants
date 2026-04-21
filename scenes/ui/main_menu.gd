extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/options.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_online_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/LanLobby.tscn")
