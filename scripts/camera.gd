extends Camera2D

# Godot 4 Camera2D.zoom behavior:
# - Larger zoom values = zoom IN (objects appear bigger)
# - Smaller zoom values = zoom OUT (see more of the world)
@export var zoom_out: float = 3.0 # farthest view (shows more world)
@export var zoom_in: float = 1.5  # closest view (shows less world)

@export var padding: float = 200.0
@export var move_speed: float = 7.0
@export var zoom_speed: float = 7.0
@export var debug_log: bool = false

# --- Screen shake settings ---
@export var shake_decay: float = 4.0            # how quickly shake fades (higher = shorter)
@export var max_shake_offset_px: float = 40.0   # maximum positional shake in pixels at full strength
@export var max_shake_rotation_deg: float = 4.0 # optional rotation shake at full strength
@export var shake_noise_speed: float = 35.0     # how "fast" it jitters (used for modulation)

@onready var p_wins = [
	$CanvasLayer/player1wins,
	$CanvasLayer/player2wins,
	$CanvasLayer/player3wins,
	$CanvasLayer/player4wins
]

var _shake_trauma: float = 0.0   # 0..1
var _shake_time: float = 0.0

func _ready() -> void:
	randomize()
	await get_tree().process_frame
	_update_player_ui_visibility()

# Call this from weapons/explosions: camera.add_shake(0.2)
# strength is additive; typical values: 0.05 (small) .. 0.4 (big)
func add_shake(strength: float) -> void:
	_shake_trauma = clamp(_shake_trauma + strength, 0.0, 1.0)
	
func _update_player_ui_visibility() -> void:
	var players := _get_players()
	for i in range(min(players.size(), p_wins.size())):
		p_wins[i].visible = true

func _process(delta: float) -> void:
	p_wins[0].text = "WINS:" + str(Global.playerwins[0])
	p_wins[1].text = "WINS:" + str(Global.playerwins[1])
	p_wins[2].text = "WINS:" + str(Global.playerwins[2])
	p_wins[3].text = "WINS:" + str(Global.playerwins[3])
	var players := _get_players()
	if players.is_empty():
		# also clear shake if no players (optional)
		offset = Vector2.ZERO
		rotation = 0.0
		return

	var rect: Rect2 = _get_players_rect(players)
	rect.position -= Vector2(padding, padding)
	rect.size += Vector2(padding, padding) * 2.0

	# --- Follow (WORLD SPACE) ---
	var target_pos: Vector2 = rect.get_center()
	global_position = global_position.lerp(target_pos, move_speed * delta)

	# --- Zoom (CAMERA ZOOM SPACE) ---
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zx: float = rect.size.x / viewport_size.x
	var zy: float = rect.size.y / viewport_size.y
	var z_needed: float = max(zx, zy)

	# Invert because Camera2D.zoom is the opposite of "needed fraction":
	# - players far apart => z_needed big => want zoom OUT => smaller Camera2D.zoom
	# - players close     => z_needed small => want zoom IN  => bigger Camera2D.zoom
	var z_raw: float = 1.0 / max(z_needed, 0.0001)

	# clamp expects (min, max); keep it safe even if zoom_in/zoom_out are "flipped"
	var z_min: float = min(zoom_in, zoom_out)
	var z_max: float = max(zoom_in, zoom_out)
	var z: float = clamp(z_raw, z_min, z_max)

	var desired_zoom: Vector2 = Vector2(z, z)
	zoom = zoom.lerp(desired_zoom, zoom_speed * delta)

	# --- Shake LAST (SCREEN SPACE via offset/rotation) ---
	_update_shake(delta)

	if debug_log:
		print(
			"z_needed=", z_needed,
			" z_raw=", z_raw,
			" z=", z,
			" rect=", rect.size,
			" viewport=", viewport_size,
			" trauma=", _shake_trauma,
			" offset=", offset,
			" zoom=", zoom
		)

func _update_shake(delta: float) -> void:
	_shake_time += delta

	# decay trauma towards 0
	_shake_trauma = max(_shake_trauma - shake_decay * delta, 0.0)

	if _shake_trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return

	# squared trauma = subtle small shakes, strong big shakes
	var t := _shake_trauma * _shake_trauma

	# Random jitter direction (safe normalize)
	var jitter := Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	)

	var leng := jitter.length()
	if leng < 0.0001:
		jitter = Vector2.RIGHT
	else:
		jitter /= leng

	# Optional modulation to make it feel "faster" without extra rand calls
	var amp_mod := 0.6 + 0.4 * sin(_shake_time * shake_noise_speed)

	# IMPORTANT: offset is in SCREEN PIXELS -> works fine even during zoom changes
	offset = jitter * (max_shake_offset_px * t * amp_mod)

	# Optional rotation shake
	if max_shake_rotation_deg > 0.0:
		var rot_sign := -1.0 if randf() < 0.5 else 1.0
		rotation = deg_to_rad(max_shake_rotation_deg) * t * rot_sign
	else:
		rotation = 0.0

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
