extends Node2D

@export var grenade_projectile_scene: PackedScene
@export var rotation_speed: float = 12.0

@onready var shoot_point: Node2D = $ShootPoint
@onready var icon = load("res://assets/item_art/he_grenade.png")

var owner_player: Player = null
var has_been_used := false

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
	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	var step: float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

func attack() -> void:
	_shoot()

func _shoot() -> void:
	if has_been_used or owner_player == null:
		return
	if grenade_projectile_scene == null:
		push_warning("Assign a Flashbang projectile scene in the Inspector.")
		return

	var projectile := grenade_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = shoot_point.global_position
	projectile.rotation = rotation
	projectile.direction = Vector2.RIGHT.rotated(rotation).normalized()
	projectile.owner_player = owner_player

	has_been_used = true
	_consume()

func _consume() -> void:
	if owner_player != null and owner_player.equipped["utility"] == self:
		owner_player.equipped["utility"] = null
	owner_player.utility_icon.texture = owner_player.base_utility_icon
	queue_free()
