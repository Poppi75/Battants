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
		p.attack_pressed = _get_melee_for_device(p.device_id)
		p.aim_direction = _get_aim_for_device(p)
		p.shoot_pressed = _get_shoot_for_device(p.device_id)

# ---------------- Per-device polling ----------------

func _get_direction_for_device(device_id: int) -> Vector2:
	if device_id == -1:
		return Input.get_vector("kb_left", "kb_right", "kb_up", "kb_down")

	var dir := Vector2.ZERO
	var x := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	var deadzone := 0.2

	if abs(x) > deadzone:
		dir.x = x
	if abs(y) > deadzone:
		dir.y = y

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

func _get_melee_for_device(device_id: int) -> bool:
	if device_id == -1:
		return Input.is_action_just_pressed("kb_attack")

	const GAMEPAD_MELEE_BUTTON := 10
	return Input.is_joy_button_pressed(device_id, GAMEPAD_MELEE_BUTTON)

func _get_aim_for_device(player: Player) -> Vector2:
	var device_id := player.device_id

	if device_id == -1:
		# Aim from player to mouse
		var world_mouse := get_viewport().get_camera_2d().get_global_mouse_position() \
			if get_viewport().get_camera_2d() != null \
			else player.get_global_mouse_position()
		var dir := world_mouse - player.global_position
		return dir.normalized() if dir != Vector2.ZERO else player.aim_direction

	# ---------- Gamepad right stick with vector deadzone ----------
	var x := Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X)
	var y := Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
	var v := Vector2(x, y)

	var deadzone := 0.25  # tweak this if needed

	# If stick is near center, keep previous aim (no snap)
	if v.length() < deadzone:
		return player.aim_direction

	return v.normalized()

func _get_shoot_for_device(device_id: int) -> bool:
	if device_id == -1:
		return Input.is_action_pressed("kb_attack")

	const GAMEPAD_SHOOT_BUTTON := 10 # e.g. right bumper or whatever you prefer
	return Input.is_joy_button_pressed(device_id, GAMEPAD_SHOOT_BUTTON)
