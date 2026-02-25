extends Area2D

@export var speed: float = 400.0
@export var turn_speed: float = 3.0
@export var damage_amount: int = 65

@export var explosion_scene: PackedScene  # assign ExplosionAOE.tscn here
@onready var life_time: Timer = $LifeTime
@onready var fly_sound: AudioStreamPlayer2D = $fly_sound

var owner_player: Player = null  # set by launcher

func _ready() -> void:
	fly_sound.play()
	
	life_time.start()

func _physics_process(delta: float) -> void:
	if owner_player != null:
		if owner_player.device_id >= 0:
			var dir: Vector2 = owner_player.aim_direction
			if dir != Vector2.ZERO:
				var target_angle: float = dir.angle()
				var diff: float = wrapf(target_angle - rotation, -PI, PI)
				var step: float = clamp(diff, -turn_speed * delta, turn_speed * delta)
				rotation += step
		else:
			var mouse_global: Vector2 = owner_player.get_global_mouse_position()
		
		# Direction from missile to mouse
			var dir: Vector2 = (mouse_global - global_position).normalized()
			if dir != Vector2.ZERO:
				var target_angle: float = dir.angle()
				var diff: float = wrapf(target_angle - rotation, -PI, PI)
				var step: float = clamp(diff, -turn_speed * delta, turn_speed * delta)
				rotation += step
	
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta


func _on_life_time_timeout() -> void:
	print("[HomingMissile] Lifetime ended")
	call_deferred("_explode_now")


func _on_body_entered(body: Node2D) -> void:
	# Ignore the owner (no self-hit)
	if body == owner_player:
		return

	print("[HomingMissile] Exploding")
	call_deferred("_explode_now")

func _explode_now() -> void:
	if explosion_scene == null:
		print("no explosion scene :((")
		queue_free()
		return

	var explosion = explosion_scene.instantiate()
	get_tree().current_scene.add_child(explosion)

	explosion.global_position = global_position
	explosion.damage_amount = damage_amount
	var cam := get_tree().get_first_node_in_group("main_camera") as Camera2D
	if cam.has_method("add_shake"):
		cam.add_shake(0.8)

	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if explosion_scene == null:
		queue_free()
		return
	
	if area.name == "HeadshotArea":
		if area.get_parent() != owner_player:

			call_deferred("_explode_now")

	else:
		return
