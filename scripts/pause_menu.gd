extends CanvasLayer

@onready var resume_button: Button = $Control/VBoxContainer/ResumeButton
@onready var quit_button: Button = $Control/VBoxContainer/QuitButton

func _ready() -> void:
	visible = false
	
	resume_button.pressed.connect(_on_resume_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("unjoin"):
		toggle_pause()


func toggle_pause() -> void:
	visible = not visible
	get_tree().paused = visible


func _on_resume_button_pressed() -> void:
	toggle_pause()


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/lobby.tscn")
