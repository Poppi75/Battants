extends Area2D

@export var move_speed := 140.0
@export var separation_strength := 500.0
@export var desired_spacing := 18.0
@export var damping := 4.0

@export var wall_push_strength := 120.0
@export var wall_check_distance := 12.0

# Collision layer used by walls
@export var collision_mask_walls := 1

var velocity: Vector2


func _ready():

	add_to_group("fire_chunk")

	monitoring = true
	monitorable = true

	# Initial explosion burst
	velocity = Vector2.RIGHT.rotated(randf() * TAU) \
		* randf_range(move_speed * 0.4, move_speed)



func _physics_process(delta):

	var push := Vector2.ZERO

	# =========================================================
	# SEPARATE FROM OTHER FIRE CHUNKS
	# =========================================================

	for area in get_overlapping_areas():

		if area == self:
			continue

		if not area.is_in_group("fire_chunk"):
			continue

		var dir = global_position - area.global_position
		var dist = dir.length()

		if dist <= 0.001:
			continue

		# Push away if too close
		if dist < desired_spacing:

			var strength = (desired_spacing - dist) / desired_spacing

			push += dir.normalized() * strength

			# Immediate overlap correction
			var correction: Vector2 = dir.normalized() * (desired_spacing - dist) * 0.505

			global_position += correction


	velocity += push * separation_strength * delta


	# =========================================================
	# WALL AVOIDANCE
	# =========================================================

	if velocity.length() > 0.01:

		var space_state = get_world_2d().direct_space_state

		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + velocity.normalized() * wall_check_distance
		)

		query.exclude = [self]
		query.collision_mask = collision_mask_walls

		var result = space_state.intersect_ray(query)

		if not result.is_empty():

			var normal: Vector2 = result.normal

			# Push away from wall
			velocity += normal * wall_push_strength * delta

			# Slide along wall
			velocity = velocity.slide(normal)


	# =========================================================
	# NATURAL SLOWDOWN
	# =========================================================

	velocity = velocity.lerp(Vector2.ZERO, damping * delta)


	# =========================================================
	# SAFE MOVEMENT
	# =========================================================

	try_move(velocity * delta)



func try_move(motion: Vector2):

	if motion.length() <= 0.001:
		return

	var space_state = get_world_2d().direct_space_state

	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + motion
	)

	query.exclude = [self]
	query.collision_mask = collision_mask_walls

	var result = space_state.intersect_ray(query)

	if result.is_empty():

		# No collision
		global_position += motion

	else:

		# Slide along wall
		var normal: Vector2 = result.normal

		var slide_motion = motion.slide(normal)

		global_position += slide_motion * 0.8
