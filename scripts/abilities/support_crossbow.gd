extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 3.0 # radians per second; higher = faster turn
@export var cooldown_time:  float = 0.1 # seconds between shots

@onready var shoot_point: Node2D = $ShootPoint
@onready var shoot_cooldown: Timer = $shootCooldown
@onready var crossbow_anim: AnimatedSprite2D = $crossbow_anim


var owner_player: Player = null
var can_shoot: bool = true

func _process(delta: float) -> void:
	if owner_player == null:
		return
		
	if owner_player.equipped_slot == "class_ability":
		_aim_from_owner(delta)

func _aim_from_owner(delta:  float) -> void:
	var dir: Vector2 = owner_player.aim_direction
	if dir == Vector2.ZERO: 
		return

	var target_angle: float = dir.angle()
	crossbow_anim.flip_v = (dir.x < 0)
	# Shortest angular difference in [-PI, PI]
	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	# Step toward target, limited by rotation_speed
	var step:  float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

func attack() -> void:
	if bullet_scene == null:
		push_warning("Assign a Bullet scene to 'bullet_scene' in the Inspector.")
		return
		
	if can_shoot:
		crossbow_anim.play("shooting")

		var spread_angles = [-10.0, 0.0, 10.0]

		for angle_deg in spread_angles:
			var bullet = bullet_scene.instantiate()
			get_tree().current_scene.add_child(bullet)

			bullet.global_position = shoot_point.global_position
			bullet.rotation = rotation + deg_to_rad(angle_deg)
			bullet.owner_player = owner_player

		can_shoot = false
		
		shoot_cooldown.start()
		crossbow_anim.play("shot")

func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true
	crossbow_anim.play("loading")
