extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 6.0

@onready var shoot_point: Node2D = $ShootPoint

var owner_player: Player = null

func _process(delta: float) -> void:
	if owner_player == null:
		return

	if owner_player.equipped_slot == "ranged":
		_aim_from_owner(delta)

# -------------------------
# AIM
# -------------------------

func _aim_from_owner(delta: float) -> void:
	var dir := owner_player.aim_direction
	if dir == Vector2.ZERO:
		return

	var target_angle := dir.angle()
	var diff := wrapf(target_angle - rotation, -PI, PI)
	var step = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

# -------------------------
# ATTACK (CALLED BY PLAYER)
# -------------------------

func _shoot() -> void:
	if bullet_scene == null:
		push_warning("Assign a Bullet scene.")
		return

	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = shoot_point.global_position
	bullet.rotation = rotation
