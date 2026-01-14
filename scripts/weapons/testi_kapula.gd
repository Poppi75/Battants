extends Node2D

@export var bullet_scene: PackedScene


@onready var shoot_point: Node2D = $ShootPoint


func _process(_delta: float) -> void:
	_aim_at_cursor()
	_handle_shooting()

func _aim_at_cursor() -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position)
	rotation = dir.angle()

func _handle_shooting() -> void:
	if Input.is_action_pressed("p1_attack"):
		_shoot()

func _shoot() -> void:
	if bullet_scene == null:
		push_warning("Assign a Bullet scene to 'bullet_scene' in the Inspector.")
		return

	var bullet = bullet_scene.instantiate()
	# Add to the current scene so global transforms work as expected
	get_tree().current_scene.add_child(bullet)

	# Spawn at the ShootPoint and aim in the current direction
	bullet.global_position = shoot_point.global_position
	bullet.rotation = rotation

	# If your bullet script uses a direction/velocity, you can optionally set it like this:
	# var dir := Vector2.RIGHT.rotated(bullet.rotation)
	# if bullet.has_method("set_direction"):
	#     bullet.set_direction(dir)
	# elif bullet.has_variable("velocity"):
	#     bullet.velocity = dir * (bullet.speed if bullet.has_variable("speed") else 600.0)
