extends Camera2D

## CONFIG ##

@export var min_zoom: Vector2 = Vector2(1.5, 1.5)   # Smallest zoom value (closest view)
@export var max_zoom: Vector2 = Vector2(2.5, 2.5)   # Largest zoom value (farthest view)

# Distance at which we should be fully at one extreme
@export var distance_for_max_zoom: float = 1200.0

@export var padding: float = 2000.0                  # Extra space around players (for centering box)
@export var move_speed: float = 7.0                 # Camera follow speed
@export var zoom_speed: float = 7.0                 # Zoom adjust speed

@export var debug_log: bool = false                 # Enable to see what's happening


func _process(delta: float) -> void:
	var players: Array[CharacterBody2D] = _get_players()
	if players.is_empty():
		if debug_log:
			print("Camera2D: No CharacterBody2D players found in the scene.")
		return

	# --- Center the camera around players using bounding box ---
	var rect: Rect2 = _get_players_rect(players)
	var target_pos: Vector2 = rect.get_center()
	global_position = global_position.lerp(target_pos, move_speed * delta)

	# --- Zoom based on how far apart players are (max pair distance) ---
	var max_dist: float = _get_max_player_distance(players)

	# t = 0 when players are on top of each other, 1 when at or beyond distance_for_max_zoom
	var t: float = 0.0
	if distance_for_max_zoom > 0.0:
		t = clamp(max_dist / distance_for_max_zoom, 0.0, 1.0)

	# REVERSED: when t=0 (close) → max_zoom ; when t=1 (far) → min_zoom
	var desired_zoom: Vector2 = max_zoom.lerp(min_zoom, t)

	# Smooth zoom
	zoom = zoom.lerp(desired_zoom, zoom_speed * delta)

	if debug_log:
		print("Camera2D: players=", players.size(),
			  " max_dist=", max_dist,
			  " t=", t,
			  " desired_zoom=", desired_zoom,
			  " zoom=", zoom)


## Helpers ##

func _get_players() -> Array[CharacterBody2D]:
	var root: Node = get_tree().current_scene
	if root == null:
		root = get_tree().root

	var players: Array[CharacterBody2D] = []
	_collect_character_bodies(root, players)
	return players


func _collect_character_bodies(node: Node, out_array: Array[CharacterBody2D]) -> void:
	if node is CharacterBody2D:
		out_array.append(node as CharacterBody2D)

	for child in node.get_children():
		if child is Node:
			_collect_character_bodies(child as Node, out_array)


func _get_players_rect(players: Array[CharacterBody2D]) -> Rect2:
	var first_pos: Vector2 = players[0].global_position
	var min_x: float = first_pos.x
	var max_x: float = first_pos.x
	var min_y: float = first_pos.y
	var max_y: float = first_pos.y

	for i in range(1, players.size()):
		var p: Vector2 = players[i].global_position
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var pos: Vector2 = Vector2(min_x, min_y)
	var size: Vector2 = Vector2(max_x - min_x, max_y - min_y)

	if size.x < 1.0:
		size.x = 1.0
	if size.y < 1.0:
		size.y = 1.0

	return Rect2(pos, size)


func _get_max_player_distance(players: Array[CharacterBody2D]) -> float:
	var max_dist: float = 0.0
	var count: int = players.size()
	if count < 2:
		return 0.0

	for i in range(count):
		var pi: Vector2 = players[i].global_position
		for j in range(i + 1, count):
			var pj: Vector2 = players[j].global_position
			var d: float = pi.distance_to(pj)
			if d > max_dist:
				max_dist = d

	return max_dist
