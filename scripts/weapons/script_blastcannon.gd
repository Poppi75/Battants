extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 3.3 # radians per second; higher = faster turn
@export var cooldown_time:  float = 3.0 # seconds between shots

@onready var shoot_point: Node2D = $ShootPoint
@onready var shoot_cooldown: Timer = $shootCooldown
@onready var cannon_animation: AnimatedSprite2D = $cannon_animation
@onready var icon = load("res://assets/weapons/only_cannon.png")
@onready var shoot_sound: AudioStreamPlayer2D = $shoot_sound

var owner_player: Player = null  # set this when equipping the weapon
var can_shoot: bool = true

var original_ammo = 6
var total_ammo = 6

func _ready() -> void:
	randomize()
	
	# Configure the timer
	shoot_cooldown.wait_time = cooldown_time
	shoot_cooldown.one_shot = true
	shoot_cooldown.timeout.connect(_on_shoot_cooldown_timeout)

func _process(delta: float) -> void:
	if owner_player == null:
		return
		
	if owner_player.equipped_slot == "ranged":
		_aim_from_owner(delta)

func _aim_from_owner(delta:  float) -> void:
	var dir: Vector2 = owner_player.aim_direction
	if dir == Vector2.ZERO: 
		return

	var target_angle: float = dir.angle()
	cannon_animation.flip_v = (dir.x < 0)
	# Shortest angular difference in [-PI, PI]
	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	# Step toward target, limited by rotation_speed
	var step:  float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

func _shoot() -> void:
	if bullet_scene == null:
		push_warning("Assign a Bullet scene to 'bullet_scene' in the Inspector.")
		return
		
	if not can_shoot:
		return
	
	can_shoot = false  # lock immediately to prevent spam
	
	# 🔹 CHARGE FIRST
	cannon_animation.play("charge")
	await cannon_animation.animation_finished
	
	# 🔹 THEN SHOOT
	cannon_animation.play("shoot")
	
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	shoot_sound_play()
	
	var cam := get_tree().get_first_node_in_group("main_camera") as Camera2D
	if cam.has_method("add_shake"):
		cam.add_shake(0.3)
	
	bullet.global_position = shoot_point.global_position
	bullet.rotation = rotation
	
	total_ammo -= 1
	owner_player.update_bullet_count()
	
	if total_ammo <= 0:
		await shoot_sound.finished
		owner_player.ranged_icon.texture = owner_player.base_ranged_icon
		queue_free()
		return
	
	# 🔹 COOLDOWN AFTER SHOT
	shoot_cooldown.start()

func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true
	
func shoot_sound_play():
	shoot_sound.pitch_scale = randf_range(0.95, 1.05)
	shoot_sound.play()
