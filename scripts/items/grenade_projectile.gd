extends CharacterBody2D

# =========================
# MOVEMENT TUNING
# =========================
@export var max_speed: float = 320.0
@export var accel_time: float = 0.03
@export var decel: float = 1800.0
@export var min_speed: float = 20.0

@export var bounciness: float = 0.7

# Distance-based slowdown
@export var max_travel_distance: float = 900.0
@export var distance_drag: float = 2.5

# Lifetime
@export var max_lifetime: float = 1.8

# Visual spin
@export var max_angular_speed: float = 14.0

# =========================
# FLASH EFFECT
# =========================
@export var explode_scene: PackedScene
@onready var flying_sound: AudioStreamPlayer2D = $flying_sound

# =========================
# STATE
# =========================
var direction: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var accel_rate: float = 0.0
var traveled_distance: float = 0.0
var exploded: bool = false
var damage_amount = 32

var owner_player: Player = null

# =========================
# READY
# =========================
func _ready() -> void:
	randomize()
	play_sokka_and_flying()
	
	accel_rate = max_speed / max(accel_time, 0.01)

	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = max_lifetime
	add_child(timer)
	timer.timeout.connect(explode)
	timer.start()

# =========================
# PHYSICS
# =========================
func _physics_process(delta: float) -> void:
	if exploded or direction == Vector2.ZERO:
		return

	# Track distance traveled
	traveled_distance += velocity.length() * delta

	# Distance-based drag
	var dist_ratio: float = clamp(traveled_distance / max_travel_distance, 0.0, 1.0)
	var drag: float = lerp(1.0, 1.0 - distance_drag, dist_ratio)
	current_speed *= max(drag, 0.0)

	# Acceleration + deceleration
	current_speed = min(current_speed + accel_rate * delta, max_speed)
	current_speed = max(current_speed - decel * delta, 0.0)

	if current_speed < min_speed:
		current_speed = 0.0

	# Spin slows as speed drops
	var speed_ratio: float = current_speed / max_speed
	rotation -= max_angular_speed * speed_ratio * delta

	velocity = direction * current_speed
	move_and_slide()

	# Bounce off walls (STRICT-TYPED)
	if get_slide_collision_count() > 0:
		var collision: KinematicCollision2D = get_last_slide_collision()
		if collision:
			direction = direction.bounce(collision.get_normal()).normalized()
			current_speed *= bounciness

# =========================
# EXPLOSION
# =========================
func explode() -> void:
	if exploded:
		return

	exploded = true

	if explode_scene:
		var explosion: Node2D = explode_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
		explosion.damage_amount = damage_amount

	queue_free()

func play_sokka_and_flying():
	flying_sound.pitch_scale = randf_range(0.9, 1.1)
	flying_sound.play()
