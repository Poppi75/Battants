extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 3.0 # radians per second; higher = faster turn
@export var cooldown_time:  float = 0.1 # seconds between shots

@onready var shoot_point: Node2D = $ShootPoint
@onready var shoot_cooldown: Timer = $shootCooldown
@onready var ak_47_anim: AnimatedSprite2D = $ak47_animation
@onready var ak_47_anim_skin1: AnimatedSprite2D = $ak47_animation_starskin

var owner_player: Player = null  # set this when equipping the weapon
var can_shoot: bool = true

func _ready() -> void:
	# Configure the timer
	shoot_cooldown.wait_time = cooldown_time
	shoot_cooldown.one_shot = true
	shoot_cooldown.timeout.connect(_on_shoot_cooldown_timeout)

func _process(delta: float) -> void:
	if owner_player == null:
		return

	_aim_from_owner(delta)

func _aim_from_owner(delta:  float) -> void:
	var dir: Vector2 = owner_player.aim_direction
	if dir == Vector2.ZERO: 
		return

	var target_angle: float = dir.angle()
	ak_47_anim.flip_v = (dir.x < 0)
	# Shortest angular difference in [-PI, PI]
	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	# Step toward target, limited by rotation_speed
	var step:  float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

func _shoot() -> void:
	
	if bullet_scene == null:
		push_warning("Assign a Bullet scene to 'bullet_scene' in the Inspector.")
		return
		
	if can_shoot:
		ak_47_anim.play("shoot")
		
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = shoot_point.global_position
		bullet.rotation = rotation
		
		# Start cooldown
		can_shoot = false
		shoot_cooldown.start()

func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true
