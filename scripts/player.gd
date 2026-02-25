extends CharacterBody2D
class_name Player

# =========================
# SIGNALS
# =========================
signal died(player: Player)

# =========================
# STATS
# =========================
@export var max_health: int = 100
var health: int
var _damage_update_seq: int = 0
var stunned = null

@onready var health_bar: TextureProgressBar = $UI/health
@onready var damageTaken_bar: TextureProgressBar = $UI/damagetaken

# Optional: damage numbers
@export var damage_number_scene: PackedScene

# =========================
# ITEM SCENES
# =========================
@export_category("Item Scenes")

@export var melee_items: Array[PackedScene]
@export var ranged_items: Array[PackedScene]
@export var ability_items: Array[PackedScene]
@export var utility_items: Array[PackedScene]

@onready var melee_socket: Node2D = $UI/MeleeSocket
@onready var ranged_socket: Node2D = $UI/RangedSocket
@onready var ability_socket: Node2D = $UI/AbilitySocket
@onready var utility_socket: Node2D = $UI/UtilitySocket
@onready var currently_equipped = $UI/RangedSocket
@onready var damage_sound: AudioStreamPlayer2D = $damage_sound

# =========================
# MOVEMENT
# =========================
@export var speed: float = 200.0
@export var turn_speed: float = 8.0
@export var orientation_offset: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var stunTimer: Timer = $stunTimer
@onready var stunSound: AudioStreamPlayer2D = $stunSound
@onready var stun_effect: AnimatedSprite2D = $stun_effect

var equipped_slot := "ranged"
var _facing_angle: float = 0.0
@onready var current_highlight = $UI/slots/ranged/highlight
@onready var ranged_icon = $"UI/slots/ranged/pyssykkä"
@onready var ability_icon = $UI/slots/ability/ability
@onready var melee_icon = $UI/slots/melee/melee
@onready var utility_icon = $UI/slots/utility/utility
@onready var base_ranged_icon = load("res://assets/item_slot_art/ranged_slot_icon.png")
@onready var base_ability_icon = load("res://assets/item_slot_art/ability_slot_icon.png")
@onready var base_melee_icon = load("res://assets/item_slot_art/melee_slot_icon.png")
@onready var base_utility_icon = load("res://assets/item_slot_art/utility_slot_icon.png")
@onready var ui: Node2D = $UI

# Flash tween state
var _flash_tween: Tween
var _default_modulate: Color = Color(1, 1, 1, 1)

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
var can_move := false

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
# ITEM SELECTION
# =========================
const ITEM_SELECTION_DEADZONE := 0.5  # Minimum stick/mouse distance to register selection
var last_selection_direction: Vector2 = Vector2.ZERO


# =========================
# READY
# =========================
func _ready() -> void:
	anim.play("p" + str(player_number) + "_idle")
	stunned = false

	_default_modulate = anim.modulate

	health = max_health

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

	if damageTaken_bar:
		damageTaken_bar.max_value = max_health
		damageTaken_bar.value = health

	randomize()
	can_move = false


# =========================
# PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	if not can_move:
		return
	_read_input()

	if shoot_held:
		_attack()

	velocity = move_input * speed

	if move_input != Vector2.ZERO:
		var target_angle := Vector2.UP.angle_to(move_input) + orientation_offset
		_facing_angle = lerp_angle(_facing_angle, target_angle, turn_speed * delta)

		rotation = _facing_angle
		ui.global_rotation = 0.0

		if anim.animation != "p" + str(player_number) + "_walk":
			anim.play("p" + str(player_number) + "_walk")
	else:
		if anim.animation != "p" + str(player_number) + "_idle":
			anim.play("p" + str(player_number) + "_idle")

	if $UI/slots.visible == true \
	and not Input.is_joy_button_pressed(device_id, JOY_BUTTON_RIGHT_SHOULDER) \
	and not Input.is_action_pressed("item_slot"):
		$UI/slots.visible = false

	move_and_slide()


# =========================
# INPUT
# =========================
func _read_input() -> void:
	if device_id == -1:
		move_input = Input.get_vector("left", "right", "up", "down")
		shoot_held = Input.is_action_pressed("attack")

		if Input.is_action_pressed("item_slot"):
			$UI/slots.visible = true
			_handle_item_selection_mouse()

		var cam := get_viewport().get_camera_2d()
		var world_mouse := cam.get_global_mouse_position() if cam else get_global_mouse_position()
		var dir := world_mouse - global_position
		if dir != Vector2.ZERO:
			aim_direction = dir.normalized()
		return

	move_input = _get_move_for_device(device_id)
	aim_direction = _get_aim_for_device(device_id)
	shoot_held = _get_shoot_for_device(device_id)

	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_RIGHT_SHOULDER):
		$UI/slots.visible = true
		current_highlight.visible = true
		_handle_item_selection_gamepad(device_id)


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
# ITEM SELECTION
# =========================
func _handle_item_selection_gamepad(pad: int) -> void:
	var stick := Vector2(
		Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
	)

	if stick.length() >= ITEM_SELECTION_DEADZONE:
		_select_item_by_direction(stick.normalized())


func _handle_item_selection_mouse() -> void:
	var cam := get_viewport().get_camera_2d()
	var world_mouse := cam.get_global_mouse_position() if cam else get_global_mouse_position()
	var dir := world_mouse - global_position

	if dir.length() >= ITEM_SELECTION_DEADZONE * 50:
		_select_item_by_direction(dir.normalized())


func _select_item_by_direction(direction: Vector2) -> void:
	# Prevent rapid switching - only change if direction has changed significantly
	if direction.distance_to(last_selection_direction) < 0.5:
		return

	last_selection_direction = direction

	# Calculate angle in degrees (0 = right, 90 = up, 180 = left, 270 = down)
	var angle := rad_to_deg(atan2(direction.y, direction.x))

	# Normalize to 0-360
	if angle < 0:
		angle += 360

	var new_slot := equipped_slot

	# Up (315-45): Melee
	# Right (45-135): Utility
	# Down (135-225): Ranged
	# Left (225-315): Ability
	if angle >= 315 or angle < 45:
		currently_equipped.visible = false
		current_highlight.visible = false
		$UI/slots/melee/highlight.visible = true
		melee_socket.visible = true
		new_slot = "melee"
		current_highlight = $UI/slots/melee/highlight
		currently_equipped = melee_socket
	elif angle >= 45 and angle < 135:
		currently_equipped.visible = false
		current_highlight.visible = false
		$UI/slots/utility/highlight.visible = true
		utility_socket.visible = true
		new_slot = "utility"
		current_highlight = $UI/slots/utility/highlight
		currently_equipped = utility_socket
	elif angle >= 135 and angle < 225:
		currently_equipped.visible = false
		current_highlight.visible = false
		$UI/slots/ranged/highlight.visible = true
		ranged_socket.visible = true
		new_slot = "ranged"
		current_highlight = $UI/slots/ranged/highlight
		currently_equipped = ranged_socket
	elif angle >= 225 and angle < 315:
		currently_equipped.visible = false
		current_highlight.visible = false
		$UI/slots/ability/highlight.visible = true
		ability_socket.visible = true
		new_slot = "ability"
		current_highlight = $UI/slots/ability/highlight
		currently_equipped = ability_socket

	if new_slot != equipped_slot:
		equipped_slot = new_slot


# =========================
# DAMAGE / DEATH
# =========================
func take_damage(damage: int, is_headshot: bool = false) -> void:
	if health <= 0:
		return

	health -= damage
	damage_sound_play()

	_spawn_damage_number(damage, is_headshot)

	update_health_bars()
	_flash_on_damage()

	if health <= 0:
		die()

func damage_sound_play():
	damage_sound.pitch_scale = randf_range(0.95, 1.05)
	damage_sound.play()


func die() -> void:
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


# --- Flash when hit ---
func _flash_on_damage() -> void:
	if not anim:
		return

	# Kill previous flash tween so its "return to normal" can't override a new hit
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()

	# Snap to bright white each time we're hit
	anim.modulate = Color(1.7, 1.7, 1.7, 1.0)

	_flash_tween = create_tween()
	_flash_tween.tween_property(
		anim,
		"modulate",
		_default_modulate,
		0.1          # fade-back duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


# --- Optional damage numbers ---
func _spawn_damage_number(amount: int, is_headshot: bool) -> void:
	if damage_number_scene == null:
		return

	var num = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(num)

	num.global_position = health_bar.global_position + Vector2(0, -8)

	if num.has_method("setup"):
		num.setup(amount, is_headshot)




func apply_stun() -> void:
	stunTimer.start()

	# Reset volume before playing
	stunSound.volume_db = 24.0
	stunSound.play()

	var tween := create_tween()
	tween.tween_property(stunSound, "volume_db", -20.0, 5.0)  # fade out
	tween.tween_callback(stunSound.stop)                      # stop after fade

	stunned = true
	stun_effect.visible = true


func _on_stun_timer_timeout() -> void:
	stunned = false
	stun_effect.visible = false


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
			call_deferred("_equip_item", "ability", ability_items, ability_socket)
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
	if item_type == "ranged":
		ranged_icon.texture = item.icon
	if item_type == "melee":
		melee_icon.texture = item.icon
	if item_type == "ability":
		ability_icon.texture = item.icon
	if item_type == "utility":
		utility_icon.texture = item.icon


# =========================
# ATTACK
# =========================
func _attack() -> void:
	if equipped["melee"] and equipped["melee"].has_method("attack") and equipped_slot == "melee" and stunned == false:
		equipped["melee"].attack()

	if equipped["ranged"] and equipped["ranged"].has_method("_shoot") and equipped_slot == "ranged" and stunned == false:
		equipped["ranged"]._shoot()

	if equipped["ability"] and equipped["ability"].has_method("attack") and equipped_slot == "ability" and stunned == false:
		equipped["ability"].attack()

	if equipped["utility"] and equipped["utility"].has_method("attack") and equipped_slot == "utility" and stunned == false:
		equipped["utility"].attack()
