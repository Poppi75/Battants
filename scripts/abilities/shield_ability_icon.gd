extends Area2D

@export var rotation_speed: float = 20.0 # radians/sec
@export var rotation_offset: float = 0.0 # radians (tweak so art faces correctly)
@export var forward_distance: float = 24.0 # how far in front of the player the shield sits

@onready var icon = load("res://assets/ability_art/shield_icon.png")
@onready var shield_icon: Sprite2D = $shield_icon
@onready var shield_collision: CollisionShape2D = $shield_collision
@onready var shield_sprite: Sprite2D = $shield_sprite
@onready var shield_time: Timer = $shield_time

var owner_player: Player = null
var _active: bool = false

# Track our own angle around the player so we never "teleport" through the center
var _orbit_angle: float = 0.0

func _ready() -> void:
	shield_sprite.visible = false

	shield_collision.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	shield_time.one_shot = true
	if not shield_time.timeout.is_connected(_on_shield_time_timeout):
		shield_time.timeout.connect(_on_shield_time_timeout)

func _process(delta: float) -> void:
	if owner_player == null:
		return

	# If not active, do nothing
	if not _active:
		return

	# If ability slot not selected, freeze rotation AND keep current position (don't jump)
	if owner_player.equipped_slot != "ability":
		return

	_update_orbit_and_rotation(delta)

func _update_orbit_and_rotation(delta: float) -> void:
	var aim_dir: Vector2 = owner_player.aim_direction
	if aim_dir == Vector2.ZERO:
		return

	# Target orbit angle based on aim, with optional offset
	var target_orbit_angle: float = aim_dir.angle() + rotation_offset

	# Smoothly move orbit angle toward target (shortest path)
	var diff: float = wrapf(target_orbit_angle - _orbit_angle, -PI, PI)
	var step: float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	_orbit_angle += step

	# Position is ALWAYS at a fixed radius from player center (never on top)
	var offset: Vector2 = Vector2.RIGHT.rotated(_orbit_angle) * forward_distance
	global_position = owner_player.global_position + offset

	# Make the shield face outward (same as orbit direction)
	shield_sprite.rotation = _orbit_angle
	shield_collision.rotation = _orbit_angle

func attack() -> void:
	if _active:
		return
	if owner_player == null or owner_player.ability_icon == null:
		push_warning("owner_player or owner_player.ability_icon is missing.")
		return

	_active = true

	reparent(owner_player, true)

	# Initialize orbit angle to current aim so it starts in front immediately
	if owner_player.aim_direction != Vector2.ZERO:
		_orbit_angle = owner_player.aim_direction.angle() + rotation_offset

	# Snap once so it doesn't start at (0,0) relative
	var offset: Vector2 = Vector2.RIGHT.rotated(_orbit_angle) * forward_distance
	global_position = owner_player.global_position + offset
	shield_sprite.rotation = _orbit_angle
	shield_collision.rotation = _orbit_angle

	shield_sprite.visible = true
	shield_icon.visible = false

	shield_collision.set_deferred("disabled", false)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

	shield_time.start()

func _on_shield_time_timeout() -> void:
	if owner_player != null:
		owner_player.ability_icon.texture = owner_player.base_ability_icon
		if owner_player.equipped.has("ability") and owner_player.equipped["ability"] == self:
			owner_player.equipped["ability"] = null

	queue_free()
