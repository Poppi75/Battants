extends Node2D

@export var bullet_scene: PackedScene

@onready var shoot_point: Node2D = $ShootPoint

var owner_player: Player = null  # set this when equipping the weapon

func _process(_delta: float) -> void:
	if owner_player == null:
		return

	_aim_from_owner()
	_handle_shooting_from_owner()

func _aim_from_owner() -> void:
	var dir: Vector2 = owner_player.aim_direction
	if dir == Vector2.ZERO:
		return

	# Face where the player is aiming
	rotation = dir.angle()

	# Optionally, position this weapon on the player
	# if it's not already a child of their socket, etc.
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
