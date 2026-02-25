extends Node2D

@export var bullet_scene: PackedScene
@export var rotation_speed: float = 2.0

@onready var shoot_point: Node2D = $ShootPoint
@onready var shootCooldown: Timer = $shootCooldown
@onready var icon = load("res://assets/weapons/minigun.png")
@onready var testi_kapula: Sprite2D = $TestiKapula
@onready var shoot_sound: AudioStreamPlayer2D = $shoot_sound

var canShoot = null

var owner_player: Player = null

var total_ammo = 75

func _ready() -> void:
	randomize()
	canShoot = true

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
	testi_kapula.flip_v = (dir.x < 0)
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
	
	if canShoot == false:
		return
	
	shoot_sound_play()
	var cam := get_tree().get_first_node_in_group("main_camera") as Camera2D
	if cam.has_method("add_shake"):
		cam.add_shake(0.25)
	
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = shoot_point.global_position
	bullet.rotation = rotation
	canShoot = false
	total_ammo -= 1
	if total_ammo <= 0:
		owner_player.ranged_icon.texture = owner_player.base_ranged_icon
		
		await shoot_sound.finished
		
		queue_free()
		
	shootCooldown.start()
	

func _on_shoot_cooldown_timeout() -> void:
	canShoot = true

func shoot_sound_play():
	shoot_sound.pitch_scale = randf_range(0.95, 1.05)
	shoot_sound.play()
