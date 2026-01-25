extends CharacterBody2D

@export var max_speed: float = 320.0
@export var accel_time: float = 0.03
@export var decel: float = 2800.0
@export var min_speed_to_explode: float = 40.0
@export var max_lifetime: float = 1.8

@export var flash_scene: PackedScene   # FlashbangArea.tscn
@export var max_angular_speed: float = 14.0

var direction: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var accel_rate: float = 0.0
var owner_player: Player = null

var exploded := false   # prevents double-spawn

func _ready() -> void:
	accel_rate = max_speed / max(accel_time, 0.01)

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = max_lifetime
	add_child(timer)
	timer.timeout.connect(explode)
	timer.start()

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO or exploded:
		return

	# Accelerate
	current_speed = min(current_speed + accel_rate * delta, max_speed)
	# Decelerate
	current_speed = max(current_speed - decel * delta, 0.0)

	# Spin visually
	var speed_ratio: float = current_speed / max_speed
	rotation -= max_angular_speed * speed_ratio * delta

	velocity = direction * current_speed
	move_and_slide()

	if get_slide_collision_count() > 0:
		explode()
	elif current_speed <= min_speed_to_explode:
		explode()

func explode() -> void:
	if exploded:
		return
	exploded = true

	if flash_scene:
		var flash := flash_scene.instantiate()
		flash.global_position = global_position
		flash.owner_player = owner_player
		get_tree().current_scene.add_child(flash)

	queue_free()
