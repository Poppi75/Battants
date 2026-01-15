extends CharacterBody2D
class_name Player

@export_category("Item Scenes")

@export var max_health: int = 100
var health: int
var _damage_update_seq: int = 0

@onready var health_bar: TextureProgressBar = $health
@onready var damageTaken_bar: TextureProgressBar = $damagetaken

@export var melee_items: Array[PackedScene]
@export var ranged_items: Array[PackedScene]
@export var ability_items: Array[PackedScene]
@export var utility_items: Array[PackedScene]

@onready var melee_socket: Node2D = $MeleeSocket
@onready var ranged_socket: Node2D = $RangedSocket
@onready var ability_socket: Node2D = $AbilitySocket
@onready var utility_socket: Node2D = $UtilitySocket

@export var speed: float = 200.0
@export var turn_speed: float = 8.0
@export var orientation_offset: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var _facing_angle: float = 0.0

# -1 = keyboard/mouse, 0+ = gamepad index
var device_id: int = -1
var player_index: int = 0

# Input state
var move_input: Vector2 = Vector2.ZERO
var shoot_held: bool = false

# Weapon input
var aim_direction: Vector2 = Vector2.RIGHT

# ---- Equipped items per slot ----
var equipped := {
	"melee": null,
	"ranged": null,
	"ability": null,
	"utility": null
}

# -------- Controller config --------
const GAMEPAD_LEFT_DEADZONE := 0.20
const GAMEPAD_RIGHT_DEADZONE := 0.25

# Preferred: trigger axis held
const TRIGGER_PRESS_THRESHOLD := 0.50

# Fallback (easy/robust): right bumper
const GAMEPAD_SHOOT_BUTTON := JOY_BUTTON_RIGHT_SHOULDER

func _ready() -> void:
	health = max_health

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

	if damageTaken_bar:
		damageTaken_bar.max_value = max_health
		damageTaken_bar.value = health

	randomize()

func _physics_process(delta: float) -> void:
	_read_input()

	# Held-to-attack (like Input.is_action_pressed)
	if shoot_held:
		_attack()

	velocity = move_input * speed

	if move_input != Vector2.ZERO:
		var target_angle := Vector2.UP.angle_to(move_input) + orientation_offset
		_facing_angle = lerp_angle(_facing_angle, target_angle, turn_speed * delta)

		anim.rotation = _facing_angle
		col_shape.rotation = _facing_angle
		melee_socket.rotation = _facing_angle
		ability_socket.rotation = _facing_angle
		utility_socket.rotation = _facing_angle

		if anim.animation != "walk":
			anim.play("walk")
	else:
		if anim.animation != "idle":
			anim.play("idle")

	move_and_slide()

# -------------------------
# INPUT
# -------------------------

func _read_input() -> void:
	if device_id == -1:
		move_input = Input.get_vector("left", "right", "up", "down")
		shoot_held = Input.is_action_pressed("attack")

		# Aim from player to mouse
		var cam := get_viewport().get_camera_2d()
		var world_mouse := cam.get_global_mouse_position() if cam != null else get_global_mouse_position()
		var dir := world_mouse - global_position
		if dir != Vector2.ZERO:
			aim_direction = dir.normalized()
		return

	# Gamepad
	move_input = _get_move_for_device(device_id)
	aim_direction = _get_aim_for_device(device_id)
	shoot_held = _get_shoot_for_device(device_id)

func _get_shoot_for_device(pad: int) -> bool:
	# Preferred: right trigger axis
	# Many controllers report trigger as [-1..1] (released=-1, pressed=1) OR [0..1].
	# We'll handle both by clamping/remapping and also provide a bumper fallback.

	var rt := Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT)

	# If it's already [0..1], clamp keeps it.
	# If it's [-1..1], remap to [0..1].
	var rt01 := rt
	if rt01 < 0.0:
		rt01 = (rt + 1.0) * 0.5
	rt01 = clamp(rt01, 0.0, 1.0)

	var trigger_down := rt01 > TRIGGER_PRESS_THRESHOLD

	# Fallback: right bumper (works on basically everything)
	var bumper_down := Input.is_joy_button_pressed(pad, GAMEPAD_SHOOT_BUTTON)

	return trigger_down or bumper_down

func _get_move_for_device(pad: int) -> Vector2:
	var dir := Vector2.ZERO

	# Left stick
	var x := Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)
	var stick := Vector2(x, y)
	if stick.length() >= GAMEPAD_LEFT_DEADZONE:
		dir += stick

	# D-pad (adds on top; if both used, it’ll normalize)
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_LEFT):
		dir.x -= 1.0
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_RIGHT):
		dir.x += 1.0
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_UP):
		dir.y -= 1.0
	if Input.is_joy_button_pressed(pad, JOY_BUTTON_DPAD_DOWN):
		dir.y += 1.0

	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir

func _get_aim_for_device(pad: int) -> Vector2:
	# Right stick aim (keep previous if inside deadzone)
	var x := Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X)
	var y := Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
	var v := Vector2(x, y)

	if v.length() < GAMEPAD_RIGHT_DEADZONE:
		return aim_direction

	return v.normalized()

# -------------------------
# PICKUP / EQUIP SYSTEM
# -------------------------

func take_damage(damage: int) -> void:
	health -= damage
	update_health_bars()
	if health <= 0:
		die()

func die() -> void:
	print("Player", player_index, "(device", device_id, ") died")
	queue_free()

func update_health_bars() -> void:
	if health_bar:
		health_bar.value = health

	_damage_update_seq += 1
	var seq: int = _damage_update_seq
	await get_tree().create_timer(2.0).timeout
	if seq == _damage_update_seq and damageTaken_bar:
		damageTaken_bar.value = health

func pickup() -> void:
	var item_type := _pick_random_item_type()
	if item_type == "":
		return

	match item_type:
		"melee":
			_equip_item("melee", melee_items, melee_socket)
		"ranged":
			_equip_item("ranged", ranged_items, ranged_socket)
		"ability":
			_equip_item("ability", ability_items, ability_socket)
		"utility":
			_equip_item("utility", utility_items, utility_socket)

func _pick_random_item_type() -> String:
	var available: Array[String] = []

	if not melee_items.is_empty():
		available.append("melee")
	if not ranged_items.is_empty():
		available.append("ranged")
	if not ability_items.is_empty():
		available.append("ability")
	if not utility_items.is_empty():
		available.append("utility")

	if available.is_empty():
		return ""
	return available.pick_random()

func _equip_item(item_type: String, item_list: Array[PackedScene], socket: Node2D) -> void:
	if item_list.is_empty():
		return

	if equipped[item_type]:
		equipped[item_type].queue_free()
		equipped[item_type] = null

	var scene: PackedScene = item_list.pick_random() as PackedScene
	var item := scene.instantiate()
	socket.add_child(item)

	if item is Node2D:
		item.position = Vector2.ZERO
		item.rotation = 0.0
		item.scale = Vector2.ONE

	if "owner_player" in item:
		item.owner_player = self

	equipped[item_type] = item

# -------------------------
# ATTACK
# -------------------------

func _attack() -> void:
	if equipped["melee"] and equipped["melee"].has_method("attack"):
		equipped["melee"].attack()

	if equipped["ranged"].has_method("_shoot"):
		equipped["ranged"]._shoot()

	if equipped["ability"] and equipped["ability"].has_method("attack"):
		equipped["ability"].attack()

	if equipped["utility"] and equipped["utility"].has_method("attack"):
		equipped["utility"].attack()
