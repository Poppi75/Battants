extends Node2D
class_name PlayerController

@onready var device_id: int

@export var trigger_press_threshold := 0.2
@export var gamepad_left_deadzone := 0.2
@export var gamepad_right_deadzone := 0.25
@export var item_selection_mouse_accum_px := 60.0 # pixels of accumulated mouse movement required
@export var item_selection_mouse_decay := 0.85    # 0..1, higher = less decay

# Selection deadzones
@export var item_selection_deadzone_gamepad := 0.6
@export var item_selection_deadzone_mouse_px := 30.0

# Minimum angle change (degrees) required before emitting a new item_select_direction.
@export var item_selection_min_change_deg := 12.0

# ===== Outputs (Player reads these) =====
var move: Vector2 = Vector2.ZERO
var aim: Vector2 = Vector2.RIGHT
var shoot_held: bool = false
var pickup_just_pressed: bool = false

var slot_wheel_open: bool = false
var item_select_direction: Vector2 = Vector2.ZERO  # only non-zero when changed enough

var flower_just_pressed: bool = false

# ===== Internal state =====
var _prev_pickup_pressed: bool = false

# Selection filtering state
var _has_last_selection_angle: bool = false
var _last_selection_angle: float = 0.0
var _wheel_was_open: bool = false
var _prev_mouse_pos: Vector2 = Vector2.ZERO
var _mouse_accum: Vector2 = Vector2.ZERO


func update(player_global_pos: Vector2) -> void:
	pickup_just_pressed = false
	flower_just_pressed = false
	item_select_direction = Vector2.ZERO

	if device_id == -1:
		_read_keyboard_mouse(player_global_pos)
	else:
		_read_gamepad(player_global_pos)

	# Reset selection filter when the wheel closes, so next open selects immediately.
	if not slot_wheel_open:
		_wheel_was_open = false
		_has_last_selection_angle = false


func _read_keyboard_mouse(player_global_pos: Vector2) -> void:
	move = Input.get_vector("left", "right", "up", "down")
	shoot_held = Input.is_action_pressed("attack")
	pickup_just_pressed = Input.is_action_just_pressed("pickup")

	slot_wheel_open = Input.is_action_pressed("item_slot")

	var mouse := get_viewport().get_mouse_position()

	# Wheel just opened: reset accumulators so first flick selects immediately.
	if slot_wheel_open and not _wheel_was_open:
		_wheel_was_open = true
		_has_last_selection_angle = false
		_prev_mouse_pos = mouse
		_mouse_accum = Vector2.ZERO

	if slot_wheel_open:
		var delta := mouse - _prev_mouse_pos
		_prev_mouse_pos = mouse

		# Accumulate movement (optionally decay so old movement doesn't dominate)
		_mouse_accum = (_mouse_accum * item_selection_mouse_decay) + delta

		if _mouse_accum.length() >= item_selection_mouse_accum_px:
			item_select_direction = _filter_selection_direction_by_angle(_mouse_accum)
	else:
		_prev_mouse_pos = mouse

	if Input.is_action_just_pressed("flooverer"):
		flower_just_pressed = true

	aim = _mouse_aim_direction(player_global_pos, aim)


func _read_gamepad(_player_global_pos: Vector2) -> void:
	move = _get_move_for_device(device_id)
	aim = _get_aim_for_device(device_id, aim)
	shoot_held = _get_shoot_for_device(device_id)

	slot_wheel_open = Input.is_joy_button_pressed(device_id, JOY_BUTTON_RIGHT_SHOULDER)

	# Wheel just opened: force first direction to pass through
	if slot_wheel_open and not _wheel_was_open:
		_wheel_was_open = true
		_has_last_selection_angle = false

	if slot_wheel_open:
		var stick := Vector2(
			Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
		)
		if stick.length() >= item_selection_deadzone_gamepad:
			item_select_direction = _filter_selection_direction_by_angle(stick)

	var pickup_pressed := Input.is_joy_button_pressed(device_id, JOY_BUTTON_LEFT_SHOULDER)
	pickup_just_pressed = pickup_pressed and not _prev_pickup_pressed
	_prev_pickup_pressed = pickup_pressed

	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_A):
		flower_just_pressed = true


# ===== helpers =====
func _filter_selection_direction_by_angle(dir: Vector2) -> Vector2:
	var angle: float = rad_to_deg(atan2(dir.y, dir.x))
	if angle < 0.0:
		angle += 360.0

	# First time (or just opened): always accept immediately.
	if not _has_last_selection_angle:
		_has_last_selection_angle = true
		_last_selection_angle = angle
		return dir.normalized()

	# Smallest angular distance (wrap-around aware).
	var delta: float = abs(angle - _last_selection_angle)
	delta = min(delta, 360.0 - delta)

	if delta < item_selection_min_change_deg:
		return Vector2.ZERO

	_last_selection_angle = angle
	return dir.normalized()


func _mouse_aim_direction(player_global_pos: Vector2, fallback_aim: Vector2) -> Vector2:
	var cam := get_viewport().get_camera_2d()
	var world_mouse := cam.get_global_mouse_position() if cam else get_global_mouse_position()
	var dir := world_mouse - player_global_pos
	return dir.normalized() if dir != Vector2.ZERO else fallback_aim


func _get_shoot_for_device(pad: int) -> bool:
	var rt := Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT)
	var rt01 := rt
	if rt01 < 0.0:
		rt01 = (rt + 1.0) * 0.5
	rt01 = clamp(rt01, 0.0, 1.0)
	return rt01 > trigger_press_threshold


func _get_move_for_device(pad: int) -> Vector2:
	var dir := Vector2.ZERO
	var stick := Vector2(
		Input.get_joy_axis(pad, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)
	)

	if stick.length() >= gamepad_left_deadzone:
		dir += stick

	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_LEFT):
		dir.x -= 1
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_RIGHT):
		dir.x += 1
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_UP):
		dir.y -= 1
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_DOWN):
		dir.y += 1

	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir

func _get_aim_for_device(pad: int, fallback_aim: Vector2) -> Vector2:
	var v := Vector2(
		Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
	)
	if v.length() < gamepad_right_deadzone:
		return fallback_aim
	return v.normalized()
