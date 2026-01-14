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
@export var orientation_offset: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var _facing_angle: float = 0.0

# -1 = keyboard, 0+ = gamepad index
var device_id: int = -1

# Input state, set externally
var move_input: Vector2 = Vector2.ZERO
var attack_pressed: bool = false

func _ready() -> void:
	randomize()

func _physics_process(delta: float) -> void:
	var input_dir := move_input

	velocity = input_dir * speed

	if input_dir != Vector2.ZERO:
		var target_angle: float = Vector2.UP.angle_to(input_dir) + orientation_offset
		_facing_angle = lerp_angle(_facing_angle, target_angle, turn_speed * delta)

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

func _process(_delta: float) -> void:
	if attack_pressed:
		_attack()
		attack_pressed = false  # consume

func _attack() -> void:
	print("Player with device", device_id, "attacked")

# (your pickup / item code stays as you had it)
