extends Area2D

@export var pickups: Array[PackedScene]
@export var max_attempts := 20

func _ready():
	await get_tree().process_frame
	randomize()
	$Timer.start()
	
func spawn_coin():
	for i in max_attempts:
		var pos = get_random_point_in_area()
		if is_position_free(pos):
			var coin = pickups.pick_random().instantiate()
			coin.global_position = pos
			get_tree().current_scene.add_child(coin)
			return

func get_random_point_in_area() -> Vector2:
	var shape := $CollisionShape2D.shape as RectangleShape2D
	var extents = shape.extents
	return global_position + Vector2(
		randf_range(-extents.x, extents.x),
		randf_range(-extents.y, extents.y)
	)

func is_position_free(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.exclude = [self]
	query.collide_with_bodies = true
	query.collide_with_areas = true
	return space_state.intersect_point(query).is_empty()


func _on_timer_timeout() -> void:
	spawn_coin()
