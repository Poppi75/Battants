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

var player_classes = [
	0,
	0,
	0,
	0
]

@onready var controls = [
	$p1_class,
	$p2_class,
	$p3_class,
	$p4_class
]

@onready var class_images = [
	preload("res://assets/weapons/knife.png"),
	preload("res://assets/weapons/deagle.png"),
	preload("res://assets/weapons/sawed_off.png"),
	preload("res://assets/weapons/testikapula.png")
]

func _ready() -> void:
	update_players_joined()

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

	if event.is_action_pressed("class_up"):
		var device_id = _get_event_device_id(event)
		var player = Global.joined_devices.find(device_id)
		if Global.joined_devices.has(device_id):
			player_classes[player] += 1
			if 0 <= player_classes[player] and player_classes[player] <= 3:
				controls[player].texture = class_images[player_classes[player]]
			else:
				player_classes[player] = 0
				controls[player].texture = class_images[player_classes[player]]

	if event.is_action_pressed("class_down"):
		var device_id = _get_event_device_id(event)
		var player = Global.joined_devices.find(device_id)
		if Global.joined_devices.has(device_id):
			player_classes[player] -= 1
			if 0 <= player_classes[player] and player_classes[player] <= 3:
				controls[player].texture = class_images[player_classes[player]]
			else:
				player_classes[player] = 3
				controls[player].texture = class_images[player_classes[player]]

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

func update_players_joined():
	for i in range(Global.joined_devices.size()):
		players[i].visible = true
		controls[i].visible = true
	
func _on_start_button_pressed() -> void:
	_start_match()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _start_match() -> void:
	Global.player_bindings = []
	
	if Global.joined_devices.size() < MIN_PLAYERS:
		print("Need at least", MIN_PLAYERS, "players")
		return

	for device_id in Global.joined_devices:
		Global.player_bindings.append({ "device": device_id })

	var chosen = Global.pick_random_map()

	# store it for the loading screen
	Global.set_next_map(chosen)

	# go to loading screen instead of the map directly
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
