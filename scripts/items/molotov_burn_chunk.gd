extends Area2D

@export var settle_time := 0.45
@export var settle_speed := 220.0

# Repulsion weights (relative importance)
@export var repel_strength_fire := 4.0
@export var repel_strength_wall := 2.5
@export var repel_strength_other := 0.5

# Extra multiplier after averaging (higher = spreads faster, but stable)
@export var spread_boost := 1.0

# Movement limits
@export var max_push_per_frame := 35.0

# Set this true if you ONLY want to block against nodes in group "wall".
@export var only_block_group_wall := true

# Keep away from surfaces a bit (tile corners usually need > 0.5)
@export var skin := 2.0

# Query tuning
@export var max_query_results := 16

# Push out of small overlaps (tile corners / spawn overlap)
@export var depenetrate_steps := 4
@export var depenetrate_step_dist := 2.0

var _settle_left := 0.0


func _ready() -> void:
	_settle_left = settle_time


func _physics_process(delta: float) -> void:
	if _settle_left <= 0.0:
		return
	_settle_left -= delta

	var overlappers: Array = []
	overlappers.append_array(get_overlapping_bodies())
	overlappers.append_array(get_overlapping_areas())

	var sum := Vector2.ZERO
	var contrib := 0

	for o in overlappers:
		if o == self or o == null:
			continue

		var away = global_position - o.global_position
		if away.length_squared() < 0.0001:
			away = Vector2.RIGHT.rotated(randf() * TAU)

		var dir = away.normalized()

		var w := repel_strength_other
		if o.is_in_group("fire"):
			w = repel_strength_fire
		elif o.is_in_group("wall"):
			w = repel_strength_wall

		sum += dir * w
		contrib += 1

	if contrib == 0 or sum.length_squared() < 0.000001:
		return

	# KEY: average, don't let more neighbors = launch velocity
	var avg := sum / float(contrib)

	# Convert into motion this frame
	var desired := avg * (settle_speed * spread_boost) * delta
	desired = desired.limit_length(max_push_per_frame)

	_move_with_wall_block(desired)


func _move_with_wall_block(motion: Vector2) -> void:
	if motion == Vector2.ZERO:
		return

	var shape_node := _find_collision_shape()
	if shape_node == null or shape_node.shape == null:
		global_position += motion
		return

	var space := get_world_2d().direct_space_state

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.transform = Transform2D(global_rotation, global_position)
	params.exclude = [self]
	params.motion = motion

	var cast: PackedFloat32Array = space.cast_motion(params)
	var safe_t := 1.0
	if cast.size() > 0:
		safe_t = cast[0]

	if safe_t < 1.0 and only_block_group_wall:
		var impact_pos := global_position + motion * safe_t

		params.transform = Transform2D(global_rotation, impact_pos)
		params.motion = Vector2.ZERO

		var overlaps := space.intersect_shape(params, max_query_results)
		var hit_wall := false
		for h in overlaps:
			var col = h.get("collider")
			if col != null and col.is_in_group("wall"):
				hit_wall = true
				break

		if not hit_wall:
			global_position += motion
			return

	var safe_motion := motion * safe_t
	if safe_motion.length() > skin:
		safe_motion -= safe_motion.normalized() * skin

	global_position += safe_motion
	_depenetrate_from_walls()


func _depenetrate_from_walls() -> void:
	var shape_node := _find_collision_shape()
	if shape_node == null or shape_node.shape == null:
		return

	var space := get_world_2d().direct_space_state

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.exclude = [self]
	params.motion = Vector2.ZERO

	for _i in depenetrate_steps:
		params.transform = Transform2D(global_rotation, global_position)

		var hits := space.intersect_shape(params, max_query_results)
		if hits.is_empty():
			return

		var push := Vector2.ZERO
		var any_wall := false

		for h in hits:
			var col = h.get("collider")
			if col == null:
				continue
			if only_block_group_wall and not col.is_in_group("wall"):
				continue

			any_wall = true
			var n: Vector2 = h.get("normal", Vector2.ZERO)
			if n != Vector2.ZERO:
				push += n

		if not any_wall:
			return

		if push.length_squared() < 0.0001:
			push = Vector2.RIGHT

		global_position += push.normalized() * depenetrate_step_dist


func _find_collision_shape() -> CollisionShape2D:
	for c in get_children():
		if c is CollisionShape2D:
			return c
	return null
