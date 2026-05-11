extends Control

const MAX_PLAYERS := 4
const MIN_PLAYERS := 2

var player_scene: PackedScene = preload("res://scenes/characters/player.tscn")

var players_joined = 0
	
@onready var players = [
	$p1_txt,
	$p2_txt,
	$p3_txt,
	$p4_txt
]

@onready var controls = [
	$p1_ctrl,
	$p2_ctrl,
	$p3_ctrl,
	$p4_ctrl
]

#var maps = Global.maps

var mouse_texture = preload("res://assets/ui art/ui_mouse.png")
var controller_texture = preload("res://assets/ui art/ui_controller.png")

func _ready() -> void:
	update_players_joined()
	randomize()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("join"):
		var device_id = _get_event_device_id(event)
		if device_id == null:
			return

		# Prevent multiple joins from KBM (-1)
		if Global.joined_devices.has(device_id):
			return
		if Global.joined_devices.size() >= MAX_PLAYERS:
			return

		_add_device(device_id)
		
	if event.is_action_pressed("unjoin"):
		var device_id = _get_event_device_id(event)
		if device_id == null:
			return
			
		if Global.joined_devices.has(device_id):
			_remove_device(device_id)

func _get_event_device_id(event: InputEvent):
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		return -1
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device
	return null

func _add_device(device_id: int) -> void:
	Global.joined_devices.append(device_id)
	print("Player joined with device:", device_id)
	players_joined += 1
	update_players_joined()
	
func _remove_device(device_id: int) -> void:
	Global.joined_devices.erase(device_id)
	print("player left with device", device_id)
	players_joined -= 1
	players[players_joined].visible = false
	controls[players_joined].visible = false
	update_players_joined()

	# (Optional) If you don’t actually want to spawn players in the lobby, remove this.
	# Spawning only in the match scene is usually cleaner.
	# var p := player_scene.instantiate()
	# add_child(p)
	
func update_players_joined():
	for i in range(Global.joined_devices.size()):
		players[i].visible = true
		controls[i].visible = true
		if Global.joined_devices[i] != -1:
			controls[i].texture = controller_texture
		else:
			controls[i].texture = mouse_texture
	
func _on_start_button_pressed() -> void:
	_start_match()

func _start_match() -> void:
	if Global.joined_devices.size() < MIN_PLAYERS:
		print("Need at least", MIN_PLAYERS, "players")
		return

	var bindings: Array = []
	for device_id in Global.joined_devices:
		bindings.append({ "device": device_id })

	Global.player_bindings = bindings

	# pick random map from Global
	var chosen = Global.pick_random_map()

	# store it for the loading screen
	Global.set_next_map(chosen)

	# go to loading screen instead of the map directly
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
