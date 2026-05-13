extends CharacterBody2D
class_name Player

# =========================
# SIGNALS
# =========================
signal died(player: Player)

# =========================
# STATS
# =========================
@export var max_health: float = 100
var health: float
var _damage_update_seq: float = 0
var stunned = null
var resistance = 0.0

@onready var health_bar: TextureProgressBar = $UI/health
@onready var extra_health: TextureProgressBar = $UI/extra_health
@onready var damageTaken_bar: TextureProgressBar = $UI/damagetaken
@onready var damage_number_scene = preload("res://scenes/ui/damage_number.tscn")
@onready var pickup_popup_scene = preload("res://scenes/ui/pickup_popup.tscn")
@onready var grave_scene = preload("res://scenes/characters/grave.tscn")


@onready var ranged_socket: Node2D = $UI/RangedSocket
@onready var ability_socket: Node2D = $UI/AbilitySocket
@onready var utility_socket: Node2D = $UI/UtilitySocket
@onready var class_ability_socket: Node2D = $UI/ClassAbilitySocket
@onready var currently_equipped = $UI/RangedSocket
@onready var damage_sound: AudioStreamPlayer2D = $damage_sound

# =========================
# MOVEMENT
# =========================
@export var speed: float = 200.0
@export var turn_speed: float = 8.0
@export var orientation_offset: float = 0.0
@onready var controller: PlayerController = $PlayerController

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D
@onready var stunTimer: Timer = $stunTimer
@onready var stunSound: AudioStreamPlayer2D = $stunSound
@onready var stun_effect: AnimatedSprite2D = $stun_effect
@onready var checker: Area2D = $checker

var equipped_slot := "ranged"
var _facing_angle: float = 0.0
@onready var current_highlight = $UI/slots/ranged/highlight
@onready var ranged_icon = $"UI/slots/ranged/pyssykkä"
@onready var ability_icon = $UI/slots/ability/ability
@onready var utility_icon = $UI/slots/utility/utility
@onready var base_ranged_icon = load("res://assets/item_slot_art/ranged_slot_icon.png")
@onready var base_ability_icon = load("res://assets/item_slot_art/ability_slot_icon.png")
@onready var base_utility_icon = load("res://assets/item_slot_art/utility_slot_icon.png")
@onready var ui: Node2D = $UI
@onready var controller_pickup_label = $UI/controller_pickup
@onready var pc_pickup_label = $UI/pc_pickup
@onready var bullet_count: Label = $UI/slots/ranged/bullet_count
@onready var bullet_count_icon: TextureRect = $UI/slots/ranged/bullet_count_icon

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
var prev_pickup_pressed := false
var pickup_just_pressed: bool = false

# =========================
# EQUIPPED ITEMS
# =========================
var equipped := {
	"ranged": null,
	"ability": null,
	"utility": null,
	"class_ability": null
}

# =========================
# CONTROLLER CONFIG
# =========================
const GAMEPAD_LEFT_DEADZONE := 0.20
const GAMEPAD_RIGHT_DEADZONE := 0.25
const TRIGGER_PRESS_THRESHOLD := 0.10

# =========================
# ITEM SELECTION
# =========================
const ITEM_SELECTION_DEADZONE := 0.5  # Minimum stick/mouse distance to register selection
var last_selection_direction: Vector2 = Vector2.ZERO
var _pickup_overlap_count: int = 0

# =========================
# READY
# =========================
func _ready() -> void:
	stunTimer.timeout.connect(_on_stun_timer_timeout)
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

	if $UI/slots.visible == true and device_id == -1 and not Input.is_action_pressed("item_slot"):
		$UI/slots.visible = false
	
	elif $UI/slots.visible == true and device_id != -1 and not Input.is_joy_button_pressed(device_id, JOY_BUTTON_RIGHT_SHOULDER):
		$UI/slots.visible = false

	move_and_slide()


# =========================
# INPUT
# =========================
func _read_input() -> void:
	controller.update(global_position)

	move_input = controller.move
	aim_direction = controller.aim
	shoot_held = controller.shoot_held
	pickup_just_pressed = controller.pickup_just_pressed

	$UI/slots.visible = controller.slot_wheel_open
	current_highlight.visible = controller.slot_wheel_open

	if controller.item_select_direction != Vector2.ZERO:
		_select_item_by_direction(controller.item_select_direction)

	if controller.flower_just_pressed:
		flowering()

# =========================
# ITEM SELECTION
# =========================
func _select_item_by_direction(direction: Vector2) -> void:

	# Calculate angle in degrees (0 = right, 90 = up, 180 = left, 270 = down)
	var angle := rad_to_deg(atan2(direction.y, direction.x))

	# Normalize to 0-360
	if angle < 0:
		angle += 360

	var new_slot := equipped_slot


	if angle >= 45 and angle < 135:
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

	elif angle >= 315 or angle < 45:
		currently_equipped.visible = false
		current_highlight.visible = false
		$UI/slots/class_ability/highlight.visible = true
		class_ability_socket.visible = true
		new_slot = "class_ability"
		current_highlight = $UI/slots/class_ability/highlight
		currently_equipped = class_ability_socket

	if new_slot != equipped_slot:
		equipped_slot = new_slot


# =========================
# DAMAGE / DEATH
# =========================
func take_damage(damage: float, is_headshot: bool = false) -> void:
	if health <= 0:
		return

	damage = damage - damage * resistance
	health -= damage
	damage_sound_play()

	_spawn_damage_number(damage, is_headshot, false)

	update_health_bars()
	_flash_on_damage()

	if health <= 0:
		die()

func damage_sound_play():
	damage_sound.pitch_scale = randf_range(0.95, 1.05)
	damage_sound.play()


func die() -> void:
	call_deferred("_die_deferred")

func _die_deferred() -> void:
	died.emit(self)

	if grave_scene:
		var grave = grave_scene.instantiate()
		grave.global_position = global_position
		get_tree().current_scene.add_child(grave)

	queue_free()

func flower_heal() -> void:
	health += 25
	_spawn_damage_number(25, false, true)
	update_health_bars()
	
func flowering() -> void:
	for overlapped_area in checker.get_overlapping_areas():
		if overlapped_area.has_method("apply_flowers"):
			overlapped_area.call("apply_flowers", self)

func update_health_bars() -> void:
	if health_bar:
		health_bar.value = health
		extra_health.value = health - 100

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
func _spawn_damage_number(amount: float, is_headshot: bool, is_heal: bool) -> void:
	if damage_number_scene == null:
		return

	var num = damage_number_scene.instantiate()
	get_tree().current_scene.add_child(num)

	num.global_position = health_bar.global_position + Vector2(0, -8)

	if num.has_method("setup"):
		num.setup(amount, is_headshot, is_heal)




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
func set_pickup_hint(_visible: bool) -> void:
	if device_id == -1:
		pc_pickup_label.visible = _visible
	else:
		controller_pickup_label.visible = _visible

func _pickup_area_entered() -> void:
	_pickup_overlap_count += 1
	set_pickup_hint(_pickup_overlap_count > 0)

func _pickup_area_exited() -> void:
	_pickup_overlap_count = max(0, _pickup_overlap_count - 1)
	set_pickup_hint(_pickup_overlap_count > 0)
	
func is_pickup_pressed() -> bool:
	return pickup_just_pressed

func pickup(chosen: Dictionary) -> void:
	if chosen.is_empty():
		return

	var item_type: String = chosen["type"]
	var item_scene: PackedScene = chosen["scene"]

	match item_type:
		"ranged":
			_equip_specific_item("ranged", item_scene, ranged_socket)
			update_bullet_count()
		"ability":
			call_deferred("_equip_specific_item", "ability", item_scene, ability_socket)
		"utility":
			_equip_specific_item("utility", item_scene, utility_socket)


func _equip_specific_item(item_type: String, item_scene: PackedScene, socket: Node2D) -> void:
	if item_scene == null:
		return

	# Remove old equipped item in that slot
	if equipped[item_type]:
		equipped[item_type].queue_free()
		equipped[item_type] = null

	# Instance chosen item
	var item = item_scene.instantiate()
	socket.add_child(item)

	# Reset local transform in socket
	if item is Node2D:
		item.position = Vector2.ZERO
		item.rotation = 0.0
		item.scale = Vector2.ONE

	# Give item access to player if it supports it
	if "owner_player" in item:
		item.owner_player = self

	# Store equipped reference
	equipped[item_type] = item

	# Update UI slot icons
	if item_type == "ranged":
		ranged_icon.texture = item.icon
		bullet_count_icon.visible = true

	if item_type == "ability":
		ability_icon.texture = item.icon

	if item_type == "utility":
		utility_icon.texture = item.icon

	# Pickup popup
	var popup_text := "+"

	if "display_name" in item and str(item.display_name) != "":
		popup_text = "+"

	var popup_icon: Texture2D = null
	if "icon" in item:
		popup_icon = item.icon

	_spawn_pickup_popup(popup_text, popup_icon)

func _spawn_pickup_popup(text: String, icon: Texture2D) -> void:
	if pickup_popup_scene == null:
		return

	var popup = pickup_popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)

	# Spawn near player (or above head). Adjust as needed.
	popup.global_position = global_position + Vector2(0, -20)

	if popup.has_method("setup"):
		popup.setup(text, icon)
# =========================
# ATTACK
# =========================
func _attack() -> void:
	if equipped["ranged"] and equipped["ranged"].has_method("_shoot") and equipped_slot == "ranged" and stunned == false:
		equipped["ranged"]._shoot()

	if equipped["ability"] and equipped["ability"].has_method("attack") and equipped_slot == "ability" and stunned == false:
		equipped["ability"].attack()

	if equipped["utility"] and equipped["utility"].has_method("attack") and equipped_slot == "utility" and stunned == false:
		equipped["utility"].attack()

func update_bullet_count() -> void:
	if equipped["ranged"].total_ammo <= 0:
		bullet_count.text = ""
		bullet_count_icon.visible = false
	else:
		bullet_count.text = str(equipped["ranged"].total_ammo) + "/" + str(equipped["ranged"].original_ammo)
