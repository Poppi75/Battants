extends Control

@onready var controller_input_map: TextureRect = $controller_input_map
@onready var keyboard_input_map: TextureRect = $keyboard_input_map


func _on_settings_button_pressed() -> void:
	keyboard_input_map.visible = false
	
	controller_input_map.visible = true


func _on_quit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_online_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/LanLobby.tscn")


func _on_local_button_pressed() -> void:
	keyboard_input_map.visible = true
	
	controller_input_map.visible = false
