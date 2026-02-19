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

func _ready() -> void:
	shield_sprite.visible = false

	# Defer these changes to avoid:
	# "Can't change this state while flushing queries. Use call_deferred() or set_deferred()..."
	shield_collision.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	shield_time.one_shot = true
	if not shield_time.timeout.is_connected(_on_shield_time_timeout):
		shield_time.timeout.connect(_on_shield_time_timeout)

func _process(delta: float) -> void:
	if owner_player == null:
		return

	# Freeze rotation/position updates unless the ability slot is currently selected
	if not _active or owner_player.equipped_slot != "ability":
		return

	_update_position_and_rotation(delta)

func _update_position_and_rotation(delta: float) -> void:
	var dir: Vector2 = owner_player.aim_direction
	if dir == Vector2.ZERO:
		return

	# Put the shield in front of the player
	global_position = owner_player.global_position + dir.normalized() * forward_distance

	# Aim shield
	var target_angle: float = dir.angle() + rotation_offset

	var current_angle: float = shield_sprite.rotation
	var diff: float = wrapf(target_angle - current_angle, -PI, PI)
	var step: float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	var new_angle: float = current_angle + step

	shield_sprite.rotation = new_angle
	shield_collision.rotation = new_angle

func attack() -> void:
	if _active:
		return
	if owner_player == null or owner_player.ability_icon == null:
		push_warning("owner_player or owner_player.ability_icon is missing.")
		return

	_active = true

	reparent(owner_player, true)

	shield_sprite.visible = true
	shield_icon.visible = false

	# Defer enabling to avoid flushing-queries error
	shield_collision.set_deferred("disabled", false)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

	shield_time.start()

func _on_shield_time_timeout() -> void:
	if owner_player != null:
		owner_player.ability_icon.texture = null
		if owner_player.equipped.has("ability") and owner_player.equipped["ability"] == self:
			owner_player.equipped["ability"] = null

	queue_free()
