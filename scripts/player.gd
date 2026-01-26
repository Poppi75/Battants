extends CharacterBody2D
class_name Player

# =========================
# SIGNALS
# =========================
signal died(player: Player)

# =========================
# ITEM SCENES
# =========================
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

# =========================
# MOVEMENT
# =========================
@export var speed: float = 200.0
@export var turn_speed: float = 8.0
@export var orientation_offset: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var equipped_slot := "melee"
var _facing_angle: float = 0.0

# =========================
# PLAYER IDENTITY
# =========================
# -1 = keyboard/mouse, 0+ = gamepad index
var device_id: int = -1
var player_index: int = 0
var player_number: int = 0

# =========================
# INPUT STATE
# =========================
var move_input: Vector2 = Vector2.ZERO
var shoot_held: bool = false
var aim_direction: Vector2 = Vector2.RIGHT

# =========================
# EQUIPPED ITEMS
# =========================
var equipped := {
	"melee": null,
	"ranged": null,
	"ability": null,
	"utility": null
}

# =========================
# CONTROLLER CONFIG
# =========================
const GAMEPAD_LEFT_DEADZONE := 0.20
const GAMEPAD_RIGHT_DEADZONE := 0.25
const TRIGGER_PRESS_THRESHOLD := 0.50


# =========================
# READY
# =========================
func _ready() -> void:
	health = max_health

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

	if damageTaken_bar:
		damageTaken_bar.max_value = max_health
		damageTaken_bar.value = health

	randomize()


# =========================
# PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	_read_input()

	if shoot_held:
		_attack()

	velocity = move_input * speed

	if move_input != Vector2.ZERO:
		var target_angle := Vector2.UP.angle_to(move_input) + orientation_offset
		_facing_angle = lerp_angle(_facing_angle, target_angle, turn_speed * delta)

		anim.rotation = _facing_angle
		col_shape.rotation = _facing_angle
		# melee_socket.rotation = _facing_angle
		# ability_socket.rotation = _facing_angle
		# utility_socket.rotation = _facing_angle

		if anim.animation != "p" + str(player_number) + "_walk":
			anim.play("p" + str(player_number) + "_walk")
	else:
		if anim.animation != "p" + str(player_number) + "_idle":
			anim.play("p" + str(player_number) + "_idle")

	move_and_slide()


# =========================
# INPUT
# =========================
func _read_input() -> void:
	if device_id == -1:
		move_input = Input.get_vector("left", "right", "up", "down")
		shoot_held = Input.is_action_pressed("attack")

		if Input.is_action_just_pressed("melee_slot"):
			equipped_slot = "melee"
		if Input.is_action_just_pressed("ranged_slot"):
			equipped_slot = "ranged"
		if Input.is_action_just_pressed("ability_slot"):
			equipped_slot = "ability"
		if Input.is_action_just_pressed("utility_slot"):
			equipped_slot = "utility"

		var cam := get_viewport().get_camera_2d()
		var world_mouse := cam.get_global_mouse_position() if cam else get_global_mouse_position()
		var dir := world_mouse - global_position
		if dir != Vector2.ZERO:
			aim_direction = dir.normalized()
		return

	move_input = _get_move_for_device(device_id)
	aim_direction = _get_aim_for_device(device_id)
	shoot_held = _get_shoot_for_device(device_id)

	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_B):
		equipped_slot = "melee"
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_A):
		equipped_slot = "ranged"
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_X):
		equipped_slot = "ability"
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_Y):
		equipped_slot = "utility"


func _get_shoot_for_device(pad: int) -> bool:
	var rt := Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT)
	var rt01 := rt
	if rt01 < 0.0:
		rt01 = (rt + 1.0) * 0.5
	rt01 = clamp(rt01, 0.0, 1.0)
	return rt01 > TRIGGER_PRESS_THRESHOLD


func _get_move_for_device(pad: int) -> Vector2:
	var dir := Vector2.ZERO

	var stick := Vector2(
		Input.get_joy_axis(pad, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y)
	)

	if stick.length() >= GAMEPAD_LEFT_DEADZONE:
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


func _get_aim_for_device(pad: int) -> Vector2:
	var v := Vector2(
		Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
	)

	if v.length() < GAMEPAD_RIGHT_DEADZONE:
		return aim_direction

	return v.normalized()


# =========================
# DAMAGE / DEATH
# =========================
func take_damage(damage: int) -> void:
	if health <= 0:
		return

	health -= damage
	update_health_bars()

	if health <= 0:
		die()


func die() -> void:
	print("Player", player_index, "(device", device_id, ") died")

	# 🔔 TELL MAIN WE DIED
	died.emit(self)

	queue_free()


func update_health_bars() -> void:
	if health_bar:
		health_bar.value = health

	_damage_update_seq += 1
	var seq := _damage_update_seq
	await get_tree().create_timer(2.0).timeout
	if seq == _damage_update_seq and damageTaken_bar:
		damageTaken_bar.value = health


# =========================
# PICKUP / EQUIP
# =========================
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

	return available.pick_random() if not available.is_empty() else ""


func _equip_item(item_type: String, item_list: Array[PackedScene], socket: Node2D) -> void:
	if item_list.is_empty():
		return

	if equipped[item_type]:
		equipped[item_type].queue_free()
		equipped[item_type] = null

	var item = item_list.pick_random().instantiate()
	socket.add_child(item)

	if item is Node2D:
		item.position = Vector2.ZERO
		item.rotation = 0.0
		item.scale = Vector2.ONE

	if "owner_player" in item:
		item.owner_player = self

	equipped[item_type] = item


# =========================
# ATTACK
# =========================
func _attack() -> void:
	if equipped["melee"] and equipped["melee"].has_method("attack") and equipped_slot == "melee":
		equipped["melee"].attack()

	if equipped["ranged"] and equipped["ranged"].has_method("_shoot") and equipped_slot == "ranged":
		equipped["ranged"]._shoot()

	if equipped["ability"] and equipped["ability"].has_method("attack") and equipped_slot == "ability":
		equipped["ability"].attack()

	if equipped["utility"] and equipped["utility"].has_method("attack") and equipped_slot == "utility":
		equipped["utility"].attack()
