extends Camera2D

# Godot 4 Camera2D.zoom behavior:
# - Larger zoom values = zoom IN (objects appear bigger)
# - Smaller zoom values = zoom OUT (see more of the world)
@export var zoom_out: float = 3 # farthest view (shows more world)
@export var zoom_in: float = 1.5  # closest view (shows less world)

@export var padding: float = 200.0
@export var move_speed: float = 7.0
@export var zoom_speed: float = 7.0
@export var debug_log: bool = false

func _process(delta: float) -> void:
	var players := _get_players()
	if players.is_empty():
		return

	var rect: Rect2 = _get_players_rect(players)
	rect.position -= Vector2(padding, padding)
	rect.size += Vector2(padding, padding) * 2.0

	# center camera between players
	var target_pos: Vector2 = rect.get_center()
	global_position = global_position.lerp(target_pos, move_speed * delta)

	# compute how much of the viewport the rect would occupy
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zx: float = rect.size.x / viewport_size.x
	var zy: float = rect.size.y / viewport_size.y
	var z_needed: float = max(zx, zy)

	# Invert because Camera2D.zoom is the opposite of "needed fraction":
	# - players far apart => z_needed big => want zoom OUT => smaller Camera2D.zoom
	# - players close     => z_needed small => want zoom IN  => bigger Camera2D.zoom
	var z_raw: float = 1.0 / max(z_needed, 0.0001)

	# clamp expects (min, max); keep it safe even if zoom_in/zoom_out are "flipped"
	var z_min = min(zoom_in, zoom_out)
	var z_max = max(zoom_in, zoom_out)
	var z: float = clamp(z_raw, z_min, z_max)

	var desired_zoom: Vector2 = Vector2(z, z)
	zoom = zoom.lerp(desired_zoom, zoom_speed * delta)

	if debug_log:
		print("z_needed=", z_needed, " z_raw=", z_raw, " z=", z, " rect=", rect.size, " viewport=", viewport_size)

## Helpers ##

func _get_players() -> Array[CharacterBody2D]:
	var root: Node = get_tree().current_scene
	if root == null:
		root = get_tree().root
	
	var players: Array[CharacterBody2D] = []
	_collect_character_bodies(root, players)
	return players

func _collect_character_bodies(node: Node, out_array: Array[CharacterBody2D]) -> void:
	if node is CharacterBody2D and node.is_in_group("players"):
		out_array.append(node as CharacterBody2D)
	for child in node.get_children():
		_collect_character_bodies(child, out_array)

func _get_players_rect(players: Array[CharacterBody2D]) -> Rect2:
	var first_pos := players[0].global_position
	var min_x := first_pos.x
	var max_x := first_pos.x
	var min_y := first_pos.y
	var max_y := first_pos.y

	for i in range(1, players.size()):
		var p := players[i].global_position
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var pos := Vector2(min_x, min_y)
	var size := Vector2(max_x - min_x, max_y - min_y)
	size.x = max(size.x, 1.0)
	size.y = max(size.y, 1.0)
	return Rect2(pos, size)
