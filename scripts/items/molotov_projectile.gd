extends CharacterBody2D

@export var max_speed: float = 300.0      # top speed
@export var accel_time: float = 0.04      # how fast it ramps up
@export var decel: float = 2600.0         # how quickly it slows
@export var min_speed_to_explode: float = 30.0
@export var max_lifetime: float = 2.0     # safety timeout
@export var fire_scene: PackedScene       # set in editor to MolotovFireArea.tscn

var direction: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var accel_rate: float
var owner_player: Player = null

func _ready() -> void:
	if accel_time <= 0.0:
		accel_time = 0.01
	accel_rate = max_speed / accel_time

	# Optional safety timer
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = max_lifetime
	add_child(timer)
	timer.timeout.connect(_on_lifetime_timeout)
	timer.start()

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return

	# 1) accelerate up to max_speed
	if current_speed < max_speed:
		current_speed += accel_rate * delta
		if current_speed > max_speed:
			current_speed = max_speed

	# 2) apply deceleration every frame
	current_speed -= decel * delta
	if current_speed < 0.0:
		current_speed = 0.0

	# 3) move in straight line
	velocity = direction * current_speed
	move_and_slide()

	# 4) if hit something, explode immediately
	if get_slide_collision_count() > 0:
		explode()
		return

	# 5) when basically stopped, explode
	if current_speed <= min_speed_to_explode:
		explode()

func explode() -> void:
	if fire_scene:
		var fire := fire_scene.instantiate()
		fire.global_position = global_position
		get_tree().current_scene.add_child(fire)
	queue_free()

func _on_lifetime_timeout() -> void:
	explode()
