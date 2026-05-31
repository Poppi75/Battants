extends CanvasLayer

@onready var resume_button: Button = $Control/VBoxContainer/ResumeButton
@onready var quit_button: Button = $Control/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	visible = false

	resume_button.pressed.connect(_on_resume_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


func toggle_pause() -> void:
	visible = !visible
	get_tree().paused = visible

	if visible == true:
		$Control/VBoxContainer/ResumeButton.grab_focus()

	else:
		get_viewport().gui_release_focus()


func _on_resume_button_pressed() -> void:
	toggle_pause()


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")
