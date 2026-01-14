extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 6.0 # radians per second; higher = faster turn

@onready var shoot_point: Node2D = $ShootPoint

var owner_player: Player = null  # set this when equipping the weapon

func _process(delta: float) -> void:
	if owner_player == null:
		return

	_aim_from_owner(delta)
	_handle_shooting_from_owner()

func _aim_from_owner(delta: float) -> void:
	var dir: Vector2 = owner_player.aim_direction
	if dir == Vector2.ZERO:
		return

	var target_angle: float = dir.angle()
	# Shortest angular difference in [-PI, PI]
	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	# Step toward target, limited by rotation_speed
	var step: float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

	# Optionally, position this weapon on the player
	# global_position = owner_player.global_position

func _handle_shooting_from_owner() -> void:
	if owner_player.shoot_pressed:
		_shoot()

func _shoot() -> void:
	if bullet_scene == null:
		push_warning("Assign a Bullet scene to 'bullet_scene' in the Inspector.")
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = shoot_point.global_position
	bullet.rotation = rotation
