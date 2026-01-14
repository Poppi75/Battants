extends Control

@onready var play_button: BaseButton = $VBoxContainer/PlayButton
@onready var settings_button: BaseButton = $VBoxContainer/SettingsButton
@onready var quit_button: BaseButton = $VBoxContainer/QuitButton

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")

func _on_settings_pressed():
	get_tree().change_scene_to_file("")

func _on_quit_pressed():
	get_tree().quit()
