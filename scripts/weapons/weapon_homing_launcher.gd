extends Node2D

@export var missile_scene: PackedScene
@export var rotation_speed: float = 3.0 # radians per second; higher = faster turn
@export var cooldown_time: float = 9.0  # LONGER cooldown between shots
@export var reload_time: float = 9.0    # how long we stay in "empty" before going back to "missile"

@onready var shoot_point: Node2D = $ShootPoint
@onready var shoot_cooldown: Timer = $shootCooldown
@onready var reload_timer: Timer = $reloadTimer
@onready var launcher_anim: AnimatedSprite2D = $hominglauncher
@onready var icon = load("res://assets/weapons/weapon_hominglauncher.png")

var owner_player: Player = null  # set this when equipping the weapon
var can_shoot: bool = true
var is_reloading: bool = false

var original_ammo = 1
var total_ammo = 1

func _ready() -> void:
	# Shoot cooldown setup
	shoot_cooldown.wait_time = cooldown_time
	shoot_cooldown.one_shot = true

	# Reload timer setup
	reload_timer.wait_time = reload_time
	reload_timer.one_shot = true

	# Start in "missile" (loaded) state
	if launcher_anim:
		launcher_anim.play("missile")
		launcher_anim.animation_finished.connect(_on_launcher_animation_finished)

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
	launcher_anim.flip_v = (dir.x < 0)

	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	var step: float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

func attack() -> void:
	if missile_scene == null:
		push_warning("Assign a Missile scene to 'missile_scene' in the Inspector.")
		return

	# Only allow shooting if not on cooldown and not reloading
	if not can_shoot or is_reloading:
		return

	if launcher_anim:
		launcher_anim.play("shooting")

	var missile = missile_scene.instantiate()
	get_tree().current_scene.add_child(missile)

	missile.global_position = shoot_point.global_position
	missile.rotation = rotation

	# Homing missile needs to know who owns it
	missile.owner_player = owner_player

	# Lock shooting until cooldown ends
	can_shoot = false
	total_ammo -= 1
	owner_player.update_bullet_count()
	if total_ammo <= 0:
		owner_player.ranged_icon.texture = owner_player.base_ranged_icon
		queue_free()
			
	shoot_cooldown.start()

func _on_shoot_cooldown_timeout() -> void:
	# After cooldown, allow shooting again (if not reloading)
	can_shoot = true

func _on_launcher_animation_finished() -> void:
	if launcher_anim.animation == "shooting":
		is_reloading = true
		launcher_anim.play("empty")
		reload_timer.start()

func _on_reload_timer_timeout() -> void:
	is_reloading = false
	if launcher_anim:
		launcher_anim.play("missile")
