extends Area2D

@export var rotation_speed: float = 20.0 # radians/sec
@export var rotation_offset: float = 0.0 # radians (tweak so art faces correctly)
@export var forward_distance: float = 24.0 # how far in front of the player the shield sits

@onready var icon = load("res://assets/ability_art/shield_icon.png")
@onready var shield_icon: Sprite2D = $shield_icon
@onready var shield_collision: CollisionShape2D = $shield_collision
@onready var shield_sprite: Sprite2D = $shield_sprite
@onready var shield_time: Timer = $shield_time
@onready var activate_sound: AudioStreamPlayer2D = $activate_sound

var owner_player: Player = null
var _active: bool = false

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
	if not _active:
		return
	if owner_player.equipped_slot != "ability":
		return

	_aim_from_owner(delta)

func _aim_from_owner(delta: float) -> void:
	var dir: Vector2 = owner_player.aim_direction
	if dir == Vector2.ZERO:
		return

	# Sawed-off style: smoothly rotate toward aim
	var target_angle: float = dir.angle() + rotation_offset
	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	var step: float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

func attack() -> void:
	if _active:
		return
	if owner_player == null or owner_player.ability_icon == null:
		push_warning("owner_player or owner_player.ability_icon is missing.")
		return

	_active = true

	shield_sprite.visible = true
	shield_icon.visible = false

	shield_collision.set_deferred("disabled", false)
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

	activate_sound.play()
	shield_time.start()

func _on_shield_time_timeout() -> void:
	if owner_player != null:
		owner_player.ability_icon.texture = owner_player.base_ability_icon
		if owner_player.equipped.has("ability") and owner_player.equipped["ability"] == self:
			owner_player.equipped["ability"] = null

	queue_free()
