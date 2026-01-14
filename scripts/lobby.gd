extends Control

const MAX_PLAYERS := 4
const MIN_PLAYERS := 2

var joined_devices: Array = []      # store device ids (ints)
var players: Array = []             # store player nodes

var player_scene: PackedScene = preload("res://scenes/characters/player.tscn")

func _ready() -> void:
	randomize()
	# Show UI text in your scene if you want like "Press join to enter"

func _unhandled_input(event: InputEvent) -> void:
	# 1. Player join
	if event.is_action_pressed("ui_join"):
		var device_id = _get_event_device_id(event)
		if device_id == null:
			return

		if not joined_devices.has(device_id) and joined_devices.size() < MAX_PLAYERS:
			_add_player_for_device(device_id)

# NOTE: no return type annotation here – allows returning int or null
func _get_event_device_id(event: InputEvent):
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		return -1  # treat keyboard/mouse as device -1
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return event.device
	return null

func _add_player_for_device(device_id: int) -> void:
	joined_devices.append(device_id)

	var player := player_scene.instantiate()
	# If you later add a per-player device property, set it here, e.g.:
	# player.device_id = device_id

	players.append(player)

	# Optional: show joined players in the lobby visually
	add_child(player)
	print("Player joined with device:", device_id)

func _start_match() -> void:
	var bindings: Array = []

	# Build bindings from joined_devices so each entry has a "device" key
	for device_id in joined_devices:
		bindings.append({ "device": device_id })

	Global.player_bindings = bindings

	var maps: Array[String] = [
		"res://scenes/maps/dev_test_map_test.tscn",
	]
	var chosen: String = maps[randi() % maps.size()]
	get_tree().change_scene_to_file(chosen)

func _on_start_game_pressed() -> void:
	_start_match()
