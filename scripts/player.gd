extends CharacterBody2D
class_name Player

@export_category("Item Scenes")

@export var max_health: int = 100
var health
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

# -1 = keyboard, 0+ = gamepad index
var device_id: int = -1

# Input state, set externally
var move_input: Vector2 = Vector2.ZERO
var attack_pressed: bool = false

# Weapon input
var aim_direction: Vector2 = Vector2.RIGHT
var shoot_pressed: bool = false

# ---- NEW: equipped items per slot ----
var equipped := {
	"melee": null,
	"ranged": null,
	"ability": null,
	"utility": null
}

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
	var input_dir := move_input
	
	if attack_pressed:
		_attack()
		attack_pressed = false

	shoot_pressed = false

	velocity = input_dir * speed

	if input_dir != Vector2.ZERO:
		var target_angle := Vector2.UP.angle_to(input_dir) + orientation_offset
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
# PICKUP / EQUIP SYSTEM
# -------------------------

func take_damage(damage: int) -> void:
	print("keignrogireewmfrkgjrepirjgo")
	
	health -= damage
	
	update_health_bars()
	
	if health >= 0:
		die()

func die() -> void:
	print(device_id, "Died")
	# queue_free()							# THIS IS DEATH!!! IF DYING IS EXPECTED UNCOMMENT THIS LINE

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

func _equip_item(
	item_type: String,
	item_list: Array[PackedScene],
	socket: Node2D
) -> void:
	if item_list.is_empty():
		return

	# Remove currently equipped item of this type
	if equipped[item_type]:
		equipped[item_type].queue_free()
		equipped[item_type] = null

	# Spawn new item
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

func _process(_delta: float) -> void:
	if attack_pressed:
		_attack()
		attack_pressed = false

func _attack() -> void:
	print("Player with device", device_id, "attacked")
