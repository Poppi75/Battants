extends Control

const MAX_PLAYERS := 4
const MIN_PLAYERS := 2

var joined_devices: Array[int] = []      # device ids (-1 for KBM)
var player_scene: PackedScene = preload("res://scenes/characters/player.tscn")

var players_joined = 0
func _ready() -> void:
	randomize()
	
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

var mouse_texture = preload("res://assets/ui art/ui_mouse.png")
var controller_texture = preload("res://assets/ui art/ui_controller.png")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("join"):
		var device_id = _get_event_device_id(event)
		if device_id == null:
			return

		# Prevent multiple joins from KBM (-1)
		if joined_devices.has(device_id):
			return
		if joined_devices.size() >= MAX_PLAYERS:
			return

		_add_device(device_id)
		
	if event.is_action_pressed("unjoin"):
		var device_id = _get_event_device_id(event)
		if device_id == null:
			return
			
		if joined_devices.has(device_id):
			_remove_device(device_id)

func _get_event_device_id(event: InputEvent):
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		return -1
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device
	return null

func _add_device(device_id: int) -> void:
	joined_devices.append(device_id)
	print("Player joined with device:", device_id)
	players_joined += 1
	update_players_joined()
	
func _remove_device(device_id: int) -> void:
	joined_devices.erase(device_id)
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
	for i in range(joined_devices.size()):
		players[i].visible = true
		controls[i].visible = true
		if joined_devices[i] != -1:
			controls[i].texture = controller_texture
		else:
			controls[i].texture = mouse_texture
	

func _start_match() -> void:
	if joined_devices.size() < MIN_PLAYERS:
		print("Need at least", MIN_PLAYERS, "players")
		return

	var bindings: Array = []
	for device_id in joined_devices:
		bindings.append({ "device": device_id })

	Global.player_bindings = bindings

	var maps: Array[String] = [
		"res://scenes/maps/dev_test_map_test.tscn",
	]
	var chosen: String = maps[randi() % maps.size()]
	get_tree().change_scene_to_file(chosen)

func _on_settings_button_pressed() -> void:
	_start_match()
