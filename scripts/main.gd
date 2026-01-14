extends Node2D

const PlayerScene := preload("res://scenes/characters/player.tscn")

@onready var spawn_points := [
	$Spawns/Spawn1,
	$Spawns/Spawn2,
	$Spawns/Spawn3,
	$Spawns/Spawn4,
]

var players: Array[Player] = []

func _ready() -> void:
	var bindings: Array = Global.player_bindings

	for i in bindings.size():
		var data: Dictionary = bindings[i]
		var device_id: int = data["device"]

		var player: Player = PlayerScene.instantiate()
		player.device_id = device_id

		if i < spawn_points.size():
			player.position = spawn_points[i].position

		add_child(player)
		players.append(player)

func _process(_delta: float) -> void:
	for p in players:
		p.move_input = _get_direction_for_device(p.device_id)
		p.attack_pressed = _get_attack_for_device(p.device_id)

# -------- per-device polling (no _unhandled_input) ----------

func _get_direction_for_device(device_id: int) -> Vector2:
	# Keyboard / mouse: use keyboard-only actions
	if device_id == -1:
		return Input.get_vector("kb_left", "kb_right", "kb_up", "kb_down")

	# Gamepad: read this controller only
	var dir := Vector2.ZERO

	var x := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)

	var deadzone := 0.2
	if abs(x) > deadzone:
		dir.x = x
	if abs(y) > deadzone:
		dir.y = y

	# Optional D-pad
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_LEFT):
		dir.x = -1
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_RIGHT):
		dir.x = 1
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_UP):
		dir.y = -1
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_DOWN):
		dir.y = 1

	if dir.length() > 1.0:
		dir = dir.normalized()

	return dir

func _get_attack_for_device(device_id: int) -> bool:
	if device_id == -1:
		return Input.is_action_just_pressed("kb_attack")

	const GAMEPAD_ATTACK_BUTTON := 0  # adjust if needed
	return Input.is_joy_button_pressed(device_id, GAMEPAD_ATTACK_BUTTON)
