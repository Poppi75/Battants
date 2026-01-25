extends Area2D

@export var radius: float = 300.0
@export var max_flash_time: float = 2.5
@export var wall_mask: int = 1   # set to your wall layer

var owner_player: Player = null

func _ready() -> void:
	# Ensure overlaps are updated before checking
	await get_tree().physics_frame
	apply_flash()
	queue_free()

func apply_flash() -> void:
	for body in get_overlapping_bodies():
		if not body.has_method("apply_flash"):
			continue

		var target := body as Node2D
		if target == null:
			continue

		var strength: float = compute_flash_strength(target)
		if strength <= 0.0:
			continue

		body.apply_flash(max_flash_time * strength)

func compute_flash_strength(target: Node2D) -> float:
	# Distance falloff
	var dist: float = global_position.distance_to(target.global_position)
	if dist > radius:
		return 0.0

	var distance_mul: float = 1.0 - (dist / radius)

	# Line of sight check
	if not has_line_of_sight(target):
		distance_mul *= 0.2   # partial flash through cover

	# Facing check (optional)
	if target.has_variable("facing_direction"):
		var to_flash: Vector2 = (global_position - target.global_position).normalized()
		var facing: Vector2 = (target.facing_direction as Vector2).normalized()
		var facing_mul: float = max(facing.dot(to_flash), 0.0)
		distance_mul *= facing_mul

	return clamp(distance_mul, 0.0, 1.0)

func has_line_of_sight(target: Node2D) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		target.global_position
	)
	query.exclude = [self, target]
	query.collision_mask = wall_mask

	return space.intersect_ray(query).is_empty()
