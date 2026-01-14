extends Control

@onready var play_button: BaseButton = $VBoxContainer/PlayButton
@onready var settings_button: BaseButton = $VBoxContainer/SettingsButton
@onready var quit_button: BaseButton = $VBoxContainer/QuitButton


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")


func _on_settings_button_pressed() -> void:
	pass


func _on_quit_button_pressed() -> void:
	get_tree().quit()
