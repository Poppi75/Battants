extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 3.0 # radians per second; higher = faster turn

@export var pellets_per_shot: int = 19
@export var spread_degrees: float = 45.0 # total cone width in degrees

@onready var shoot_point: Node2D = $ShootPoint
@onready var shoot_cooldown: Timer = $shootCooldown
@onready var shotgunAnim: AnimatedSprite2D = $sawedoff_anim
@onready var shoot_sound: AudioStreamPlayer2D = $shootSound
@onready var icon = load("res://assets/weapons/sawed_off.png")

var owner_player: Player = null  # set this when equipping the weapon

var canShoot = null

var original_ammo = 7
var total_ammo = 7

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
	
	shoot_sound.pitch_scale = randf_range(0.95, 1.05)
	shoot_sound.play()
	var cam := get_tree().get_first_node_in_group("main_camera") as Camera2D
	if cam.has_method("add_shake"):
		cam.add_shake(0.6)
		
	shotgunAnim.play("shoot")

	var half_spread_rad := deg_to_rad(spread_degrees) * 0.5
	for i in range(pellets_per_shot):
		var pellet = bullet_scene.instantiate()
		pellet.owner_player = owner_player
		get_tree().current_scene.add_child(pellet)
		pellet.global_position = shoot_point.global_position
		pellet.rotation = rotation + randf_range(-half_spread_rad, half_spread_rad)
	
	total_ammo -= 1
	owner_player.update_bullet_count()
	if total_ammo <= 0:
		await shoot_sound.finished
		owner_player.ranged_icon.texture = owner_player.base_ranged_icon
		queue_free()
	
	shoot_cooldown.start()


func _on_shoot_cooldown_timeout() -> void:
	canShoot = true
