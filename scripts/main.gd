extends Node2D

const PlayerScene := preload("res://scenes/characters/player.tscn")

@export_category("UI / Camera")
@export var camera_path: NodePath  # drag your Camera2D node here in the editor if not at ./Camera2D

@onready var spawn_points := [
	$Spawns/Spawn1,
	$Spawns/Spawn2,
	$Spawns/Spawn3,
	$Spawns/Spawn4,
]

# Will be assigned in _ready() after we locate the camera
var winner: Label
var countdown_label: Label

var players: Array[Player] = []

var player_number := 1
var player_count := 0
var maps = Global.maps

var match_started := false

func _ready() -> void:
	# --- Find Camera2D node robustly ---
	var cam: Node = null

	# Preferred: explicit path set in Inspector
	if camera_path != NodePath(""):
		cam = get_node_or_null(camera_path)

	# Fallback: old layout (Camera2D is a direct child of the map)
	if cam == null:
		cam = get_node_or_null("Camera2D")

	if cam == null:
		push_warning("Camera2D not found. Set 'camera_path' in the inspector or add a child node named 'Camera2D'.")
	else:
		# These match your camera scene: Camera2D/win_text and Camera2D/CountdownLabel
		winner = cam.get_node_or_null("win_text")
		countdown_label = cam.get_node_or_null("CountdownLabel")

		if winner:
			winner.visible = false
		if countdown_label:
			countdown_label.visible = false

	# --- Spawn players ---
	var bindings: Array = Global.player_bindings

	for i in range(bindings.size()):
		var data: Dictionary = bindings[i]
		var device_id: int = data["device"]

		var player: Player = PlayerScene.instantiate()
		player.device_id = device_id
		player.player_index = i
		player.player_number = player_number
		player_number += 1

		# Freeze everyone until countdown ends
		player.can_move = false

		if i < spawn_points.size():
			player.position = spawn_points[i].position

		player.died.connect(_on_player_died)

		add_child(player)
		players.append(player)

	player_count = players.size()

	# --- Shared match countdown ---
	await _start_match_countdown(3)
	match_started = true

	# Enable movement for all players still alive
	for p in players:
		if is_instance_valid(p):
			p.can_move = true


func _start_match_countdown(seconds: int) -> void:
	if countdown_label:
		countdown_label.visible = true

	for t in range(seconds, 0, -1):
		if countdown_label:
			countdown_label.text = str(t)
		await get_tree().create_timer(1.0).timeout

	if countdown_label:
		countdown_label.text = "FIGHT!"
	await get_tree().create_timer(0.6).timeout

	if countdown_label:
		countdown_label.visible = false


func _on_player_died(player: Player) -> void:
	players.erase(player)
	player_count -= 1

	print("Player died. Remaining players:", player_count)

	# Only declare winner if match actually started (optional safety)
	if player_count == 1 and match_started:
		if winner != null and players.size() == 1 and is_instance_valid(players[0]):
			winner.visible = true
			winner.text = "WINNER: P" + str(players[0].player_number)

		await get_tree().create_timer(5.0).timeout
		var chosen: String = maps[randi() % maps.size()]
		get_tree().change_scene_to_file(chosen)
