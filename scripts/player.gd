extends CharacterBody2D
class_name Player

@export_category("Item Scenes")

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
@export var orientation_offset: float = 0.0  # If your sprite faces a different default direction

@export var controls: Resource

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var _facing_angle: float = 0.0  # Track the visual/collision facing separately from the body

func _ready() -> void:
	randomize()

func pickup() -> void:
	var item_type: String = _pick_random_item_type()
	if item_type == "":
		return

	match item_type:
		"melee":
			_equip_item(melee_items, melee_socket)
		"ranged":
			_equip_item(ranged_items, ranged_socket)
		"ability":
			_equip_item(ability_items, ability_socket)
		"utility":
			_equip_item(utility_items, utility_socket)

# -------------------------------------------------
# Internal helpers
# -------------------------------------------------

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

func _equip_item(item_list: Array[PackedScene], socket: Node2D) -> void:
	if item_list.is_empty():
		return

	# Remove existing item(s)
	for child: Node in socket.get_children():
		child.queue_free()

	# Instantiate and attach new item
	var scene: PackedScene = item_list.pick_random()
	var item: Node = scene.instantiate()

	socket.add_child(item)

	# Normalize transform
	if item is Node2D:
		item.position = Vector2.ZERO
		item.rotation = 0.0
		item.scale = Vector2.ONE

# -------------------------------------------------
# Movement
# -------------------------------------------------

func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector(
		controls.left,
		controls.right,
		controls.up,
		controls.down
	)

	velocity = input_dir * speed

	if input_dir != Vector2.ZERO:
		# Compute desired facing (0 at UP, increasing clockwise), then smooth it
		var target_angle: float = Vector2.UP.angle_to(input_dir) + orientation_offset
		_facing_angle = lerp_angle(_facing_angle, target_angle, turn_speed * delta)

		# Rotate ONLY the visual and collision children, not the CharacterBody2D
		anim.rotation = _facing_angle
		col_shape.rotation = _facing_angle
		melee_socket.rotation = _facing_angle
		# ranged_socket.rotation = _facing_angle
		ability_socket.rotation = _facing_angle
		utility_socket.rotation = _facing_angle

		if anim.animation != "walk":
			anim.play("walk")
	else:
		if anim.animation != "idle":
			anim.play("idle")

	move_and_slide()
