extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 3.0 # radians per second; higher = faster turn

@export var pellets_per_shot: int = 14
@export var spread_degrees: float = 30.0 # total cone width in degrees

@onready var shoot_point: Node2D = $ShootPoint
@onready var shoot_cooldown: Timer = $shootCooldown
@onready var shotgunAnim: AnimatedSprite2D = $sawedoff_anim

var owner_player: Player = null  # set this when equipping the weapon

var canShoot = null

func _ready() -> void:
	canShoot = true
	randomize()
	shoot_cooldown.one_shot = true
	# NOTE: set shootCooldown.wait_time in the Inspector (no cooldown_time var)

func _process(delta: float) -> void:
	if owner_player == null:
		return

	if owner_player.equipped_slot == "ranged":
		_aim_from_owner(delta)

func _aim_from_owner(delta: float) -> void:
	var dir: Vector2 = owner_player.aim_direction
	if dir == Vector2.ZERO:
		return

	var target_angle: float = dir.angle()
	shotgunAnim.flip_v = (dir.x < 0)

	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	var step: float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

func _shoot() -> void:
	if bullet_scene == null:
		push_warning("Assign a Bullet scene to 'bullet_scene' in the Inspector.")
		return

	if canShoot == false:
		return
	
	canShoot = false
	shoot_cooldown.start()
	
	shotgunAnim.play("shoot")

	var half_spread_rad := deg_to_rad(spread_degrees) * 0.5
	for i in range(pellets_per_shot):
		var pellet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(pellet)
		pellet.global_position = shoot_point.global_position
		pellet.rotation = rotation + randf_range(-half_spread_rad, half_spread_rad)


func _on_shoot_cooldown_timeout() -> void:
	canShoot = true
