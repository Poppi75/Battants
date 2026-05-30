extends CharacterBody2D

@export var max_speed: float = 300.0
@export var accel_time: float = 0.04
@export var min_speed_to_explode: float = 30.0
@export var max_lifetime: float = 1.8
@export var fire_scene: PackedScene
@onready var flying_sound: AudioStreamPlayer2D = $flying_sound

@export var max_angular_speed: float = 10.0
@export var decel: float = 900.0
@export var min_speed: float = 20.0

@export var max_travel_distance: float = 900.0
@export var distance_drag: float = 1.2

var direction: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var accel_rate: float
var traveled_distance: float = 0.0

var owner_player: Player = null

func _ready() -> void:
	flying_sound.play()

	if accel_time <= 0.0:
		accel_time = 0.01
	accel_rate = max_speed / accel_time

	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = max_lifetime
	add_child(timer)
	timer.timeout.connect(_on_lifetime_timeout)
	timer.start()

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return

	traveled_distance += velocity.length() * delta

	var dist_ratio: float = clamp(traveled_distance / max_travel_distance, 0.0, 1.0)
	var drag: float = lerp(1.0, 1.0 - distance_drag, dist_ratio)
	current_speed *= max(drag, 0.0)

	current_speed = min(current_speed + accel_rate * delta, max_speed)
	current_speed = max(current_speed - decel * delta, 0.0)

	if current_speed < min_speed:
		current_speed = 0.0

	var speed_ratio := 0.0
	if max_speed > 0.0:
		speed_ratio = current_speed / max_speed

	var angular_speed := max_angular_speed * speed_ratio
	rotation -= angular_speed * delta

	velocity = direction * current_speed
	move_and_slide()

	if get_slide_collision_count() > 0:
		explode()
		return

	if current_speed <= min_speed_to_explode:
		explode()

func explode() -> void:

	if fire_scene:
		var fire: Node2D = fire_scene.instantiate()
		fire.global_position = global_position
		if owner_player:
			fire.owner_player = owner_player
		get_tree().current_scene.add_child(fire)

	queue_free()

func _on_lifetime_timeout() -> void:
	explode()
