extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 7.0 # faster turning
@export var cooldown_time:  float = 0.6 # example: quicker fire rate

# Rotational recoil settings (STRONGER)
@export var recoil_angle: float = 0.35                # base radians (~20°)
@export var recoil_out_duration: float = 0.06         # time to kick
@export var recoil_return_duration: float = 0.10      # time to return
@export var recoil_random_min: float = 0.8            # 80% of base
@export var recoil_random_max: float = 1.3            # 130% of base

@onready var shoot_point: Node2D = $ShootPoint
@onready var shoot_cooldown: Timer = $shootCooldown
@onready var Deagle: Sprite2D = $DeagleSprite
@onready var icon = load("res://assets/weapons/deagle.png")
@onready var shoot_sound: AudioStreamPlayer2D = $shoot_sound

var owner_player: Player = null  # set this when equipping the weapon
var can_shoot: bool = true
var original_ammo = 7
var total_ammo: int = 7

# Internal recoil state
var _base_rotation: float
var _recoil_angle_tween: Tween
var _pending_free_on_recoil_end: bool = false


func _ready() -> void:
	randomize()

	_base_rotation = rotation

	shoot_cooldown.wait_time = cooldown_time
	shoot_cooldown.one_shot = true
	shoot_cooldown.timeout.connect(_on_shoot_cooldown_timeout)


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
	Deagle.flip_v = (dir.x < 0)

	var diff: float = wrapf(target_angle - rotation, -PI, PI)
	var step: float = clamp(diff, -rotation_speed * delta, rotation_speed * delta)
	rotation += step

	_base_rotation = rotation


func _shoot() -> void:
	if bullet_scene == null:
		push_warning("Assign a Bullet scene to 'bullet_scene' in the Inspector.")
		return
		
	if can_shoot:
		var bullet = bullet_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		
		shoot_sound_play()
		_apply_recoil()  # barrel kick
		var cam := get_tree().get_first_node_in_group("main_camera") as Camera2D
		if cam.has_method("add_shake"):
			cam.add_shake(0.4)

		bullet.global_position = shoot_point.global_position
		bullet.rotation = rotation
		bullet.owner_player = owner_player
		
		can_shoot = false
		total_ammo -= 1
		owner_player.update_bullet_count()

		# Hide icon immediately when empty, but don't delete the gun
		# until recoil animation on the last shot has finished.
		if total_ammo <= 0:
			if owner_player and owner_player.ranged_icon:
				owner_player.ranged_icon.texture = owner_player.base_ranged_icon
			_pending_free_on_recoil_end = true

		shoot_cooldown.start()


func _apply_recoil() -> void:
	# Kill any existing tween so recoil feels snappy if you shoot fast
	if _recoil_angle_tween and _recoil_angle_tween.is_valid():
		_recoil_angle_tween.kill()
		rotation = _base_rotation

	# Random amount of recoil this shot
	var recoil_mul: float = randf_range(recoil_random_min, recoil_random_max)
	var this_recoil_angle: float = recoil_angle * recoil_mul

	# Consistent "backwards" kick based on current angle
	var sign_dir: float = sign(cos(rotation))
	if sign_dir == 0.0:
		sign_dir = 1.0

	var target_recoil_rot: float = _base_rotation - this_recoil_angle * sign_dir
	# If it feels backwards visually, flip sign:
	# var target_recoil_rot: float = _base_rotation + this_recoil_angle * sign_dir

	_recoil_angle_tween = create_tween()

	_recoil_angle_tween.tween_property(
		self,
		"rotation",
		target_recoil_rot,
		recoil_out_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_recoil_angle_tween.tween_property(
		self,
		"rotation",
		_base_rotation,
		recoil_return_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# When the recoil tween finishes, if this was the last shot, free the gun
	_recoil_angle_tween.finished.connect(_on_recoil_finished)


func _on_recoil_finished() -> void:
	if _pending_free_on_recoil_end:
		queue_free()


func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true
	

func shoot_sound_play() -> void:
	shoot_sound.pitch_scale = randf_range(0.95, 1.05)
	shoot_sound.play()
