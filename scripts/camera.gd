extends Camera2D

# =====================================================
# ZOOM SETTINGS
# =====================================================
@export var zoom_out: float = 3.0
@export var zoom_in: float = 1.5
@export var padding: float = 200.0

@export var move_speed: float = 7.0
@export var zoom_speed: float = 7.0
@export var zoom_deadzone: float = 0.05

# =====================================================
# SHAKE SETTINGS
# =====================================================
@export var shake_decay: float = 4.0
@export var max_shake_offset_px: float = 40.0
@export var max_shake_rotation_deg: float = 4.0
@export var shake_noise_speed: float = 20.0

# =====================================================
# INTERNAL
# =====================================================
var players: Array[Player] = []

var _target_position: Vector2
var _target_zoom: Vector2

var _shake_trauma: float = 0.0
var _shake_time: float = 0.0

var _noise := FastNoiseLite.new()

@onready var p_wins = [
	$CanvasLayer/player1wins,
	$CanvasLayer/player2wins,
	$CanvasLayer/player3wins,
	$CanvasLayer/player4wins
]

# =====================================================
# READY
# =====================================================
func _ready() -> void:
	randomize()

	_target_position = global_position
	_target_zoom = zoom

	# Smooth cinematic shake
	_noise.seed = randi()
	_noise.frequency = 10.0


# =====================================================
# PLAYER REGISTRATION (NEW SYSTEM)
# =====================================================
func register_player(p: Player) -> void:
	if players.has(p):
		return

	players.append(p)
	p.died.connect(_on_player_died)
	for i in range(players.size()):
		p_wins[i].visible = true

func _on_player_died(p: Player) -> void:
	players.erase(p)


# =====================================================
# PUBLIC SHAKE CALL
# =====================================================
func add_shake(strength: float) -> void:
	_shake_trauma = clamp(_shake_trauma + strength, 0.0, 1.0)


# =====================================================
# PHYSICS (LOGIC + APPLY SMOOTHING HERE)
# =====================================================
func _physics_process(delta: float) -> void:
	# Filter to valid players (prevents invalid refs causing jumps)
	var valid_players: Array[Player] = []
	for p in players:
		if is_instance_valid(p):
			valid_players.append(p)

	if valid_players.is_empty():
		return

	var rect := _get_players_rect(valid_players)

	rect.position -= Vector2(padding, padding)
	rect.size += Vector2(padding, padding) * 2.0

	# --- Position ---
	var rect_center := rect.get_center()
	var avg_center := _get_average_position(valid_players)

	# Soft bias to reduce jitter
	_target_position = rect_center.lerp(avg_center, 0.3)

	# --- Zoom ---
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zx: float = rect.size.x / viewport_size.x
	var zy: float = rect.size.y / viewport_size.y
	var z_needed: float = max(zx, zy)

	var z_raw: float = 1.0 / max(z_needed, 0.0001)

	var z_min: float = min(zoom_in, zoom_out)
	var z_max: float = max(zoom_in, zoom_out)
	var z: float = clamp(z_raw, z_min, z_max)

	# Zoom deadzone to prevent micro flicker
	if abs(z - _target_zoom.x) < zoom_deadzone:
		z = _target_zoom.x

	_target_zoom = Vector2(z, z)

	# --- Apply smoothing on fixed timestep (prevents render/physics jitter) ---
	var pos_weight := 1.0 - exp(-move_speed * delta)
	global_position = global_position.lerp(_target_position, pos_weight)

	var zoom_weight := 1.0 - exp(-zoom_speed * delta)
	zoom = zoom.lerp(_target_zoom, zoom_weight)

	# Shake decay + visuals
	_shake_trauma = max(_shake_trauma - shake_decay * delta, 0.0)
	_update_shake_visual(delta)

	for i in range(min(p_wins.size(), Global.playerwins.size())):
		p_wins[i].text = str(Global.playerwins[i])


# =====================================================
# SMOOTH NOISE SHAKE
# =====================================================
func _update_shake_visual(delta: float) -> void:
	_shake_time += delta

	if _shake_trauma <= 0.0:
		offset = Vector2.ZERO
		rotation = 0.0
		return

	var t := _shake_trauma * _shake_trauma

	var nx = _noise.get_noise_1d(_shake_time * shake_noise_speed)
	var ny = _noise.get_noise_1d((_shake_time + 1000.0) * shake_noise_speed)

	offset = Vector2(nx, ny) * max_shake_offset_px * t

	if max_shake_rotation_deg > 0.0:
		var nr = _noise.get_noise_1d((_shake_time + 2000.0) * shake_noise_speed)
		rotation = deg_to_rad(max_shake_rotation_deg) * t * nr
	else:
		rotation = 0.0


# =====================================================
# HELPERS (VALID PLAYERS ONLY)
# =====================================================
func _get_average_position(valid_players: Array[Player]) -> Vector2:
	var sum := Vector2.ZERO
	for p in valid_players:
		sum += p.global_position
	return sum / float(valid_players.size())


func _get_players_rect(valid_players: Array[Player]) -> Rect2:
	var rect := Rect2(valid_players[0].global_position, Vector2.ZERO)

	for i in range(1, valid_players.size()):
		rect = rect.expand(valid_players[i].global_position)

	rect.size.x = max(rect.size.x, 1.0)
	rect.size.y = max(rect.size.y, 1.0)

	return rect
