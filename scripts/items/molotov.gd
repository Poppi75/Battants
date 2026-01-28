extends Node2D

@export var molotov_projectile_scene: PackedScene
@export var rotation_speed: float = 12.0 # radians per second; higher = faster turn

@onready var shoot_point: Node2D = $ShootPoint

var owner_player: Player = null
var has_been_used: bool = false

func _ready() -> void:
	if owner_player == null and owner is Player:
		owner_player = owner

func _process(delta: float) -> void:
	if owner_player == null:
		return

	if owner_player.equipped_slot == "utility":
		_aim_from_owner(delta)

func _aim_from_owner(delta: float) -> void:
	var dir: Vector2 = owner_player.aim_direction
	if dir == Vector2.ZERO:
		return

	var target_angle: float = dir.angle()

	# If you have a sprite, you can flip it here like your AK:
	# $AnimatedSprite2D.flip_v = (dir.x < 0)

	# Shortest angular difference in [-PI, PI]
	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	# Step toward target, limited by rotation_speed
	var step: float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

func _shoot() -> void:
	if has_been_used:
		return
	if owner_player == null:
		return
	if molotov_projectile_scene == null:
		push_warning("Assign a Molotov projectile scene to 'molotov_projectile_scene' in the Inspector.")
		return

	# 1) Spawn projectile at ShootPoint
	var projectile := molotov_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = shoot_point.global_position
	projectile.rotation = rotation

	# 2) Set direction/owner directly (no has_variable needed)
	projectile.direction = Vector2.RIGHT.rotated(projectile.rotation).normalized()
	projectile.owner_player = owner_player

	# 3) Mark as used and consume (one-time use)
	has_been_used = true
	_consume()
	

func attack() -> void:
	# So Player._attack() works with this utility
	_shoot()

func _consume() -> void:
	if owner_player != null and owner_player.equipped["utility"] == self:
		owner_player.equipped["utility"] = null

	queue_free()
