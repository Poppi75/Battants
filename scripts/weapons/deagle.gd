extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 5.0 # radians per second; higher = faster turn
@export var cooldown_time:  float = 1.5 # seconds between shots

@onready var shoot_point: Node2D = $ShootPoint
@onready var shoot_cooldown: Timer = $shootCooldown
@onready var Deagle: Sprite2D = $DeagleSprite
@onready var icon = load("res://assets/weapons/deagle.png")

var owner_player: Player = null  # set this when equipping the weapon
var can_shoot: bool = true

var total_ammo = 7

func _ready() -> void:
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
	Deagle.flip_v = (dir.x < 0)
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
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		bullet.global_position = shoot_point.global_position
		bullet.rotation = rotation
		bullet.owner_player = owner_player
		
		# Start cooldown
		can_shoot = false
		total_ammo -= 1
		if total_ammo <= 0:
			owner_player.ranged_icon.texture = null
			queue_free()
		
		shoot_cooldown.start()

func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true
