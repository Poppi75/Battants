extends Node2D

const PlayerScene := preload("res://scenes/characters/leafcutter_ant.tscn")


# =====================================================
# CAMERA / UI
# =====================================================
@export_category("UI / Camera")
@export var camera_path: NodePath

var camera: Camera2D
var winner: Label
var countdown_label: Label


# =====================================================
# SPAWNING
# =====================================================
@onready var spawn_points := [
	$Spawns/Spawn1,
	$Spawns/Spawn2,
	$Spawns/Spawn3,
	$Spawns/Spawn4,
]

var players: Array[Player] = []

var player_number := 1
var player_count := 0
var match_started := false
var maps = Global.maps


# =====================================================
# READY
# =====================================================
func _ready() -> void:
	randomize()

	_locate_camera()
	_spawn_players()

	player_count = players.size()

	# Shared match countdown
	await _start_match_countdown(3)
	match_started = true

	# Enable movement
	for p in players:
		if is_instance_valid(p):
			p.can_move = true


# =====================================================
# CAMERA SETUP
# =====================================================
func _locate_camera() -> void:
	if camera_path != NodePath(""):
		camera = get_node_or_null(camera_path)

	if camera == null:
		camera = get_node_or_null("Camera2D")

	if camera == null:
		push_warning("Camera2D not found. Set 'camera_path' in inspector.")
		return

	winner = camera.get_node_or_null("CanvasLayer/win_text")
	countdown_label = camera.get_node_or_null("CanvasLayer/CountdownLabel")

	if winner:
		winner.visible = false

	if countdown_label:
		countdown_label.visible = false


# =====================================================
# PLAYER SPAWNING
# =====================================================
func _spawn_players() -> void:
	var bindings: Array = Global.player_bindings

	for i in range(bindings.size()):
		var data: Dictionary = bindings[i]
		var device_id: int = data["device"]

		var player: Player = PlayerScene.instantiate()
		player.device_id = device_id
		player.player_index = i
		player.player_number = player_number
		player_number += 1

		player.can_move = false

		if i < spawn_points.size():
			player.position = spawn_points[i].position

		player.died.connect(_on_player_died)

		add_child(player)
		players.append(player)

		# Register player to upgraded camera
		if camera and camera.has_method("register_player"):
			camera.register_player(player)


# =====================================================
# COUNTDOWN
# =====================================================
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


# =====================================================
# PLAYER DEATH HANDLING
# =====================================================
func _on_player_died(player: Player) -> void:
	if not match_started:
		return

	players.erase(player)
	player_count = players.size()

	print("Player died. Remaining players:", player_count)

	# Only continue if exactly 1 remains
	if player_count == 1:
		_declare_winner(players[0])


# =====================================================
# WINNER LOGIC
# =====================================================
func _declare_winner(p: Player) -> void:
	if not is_instance_valid(p):
		return

	match_started = false

	if winner:
		winner.visible = true
		winner.text = "WINNER: P" + str(p.player_number)

	# Update global win counter safely
	var index := p.player_number - 1
	if index >= 0 and index < Global.playerwins.size():
		Global.playerwins[index] += 1
		print("Player", p.player_number, "wins:", Global.playerwins[index])

	await get_tree().create_timer(5.0).timeout
	_load_random_map()


# =====================================================
# MAP ROTATION
# =====================================================
func _load_random_map() -> void:
	if maps.is_empty():
		push_warning("No maps available in Global.maps")
		return

	var chosen: String = maps[randi() % maps.size()]

	# Store for loading screen
	Global.set_next_map(chosen)

	# Go through loading screen instead of direct change
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
