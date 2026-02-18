extends CharacterBody2D

@export var speed: float = 120.0

@onready var ray_l: RayCast2D = $ray_L
@onready var ray_r: RayCast2D = $ray_R

var dir := 1.0 # +1 = along local +X, -1 = along local -X

func _physics_process(delta: float) -> void:
	# Flip based on the ray on the side we're moving toward.
	if dir > 0.0 and ray_r.is_colliding():
		dir = -1.0
	elif dir < 0.0 and ray_l.is_colliding():
		dir = 1.0

	# Local +X in world space (respects rotation)
	var axis_x: Vector2 = global_transform.x.normalized()
	var motion: Vector2 = axis_x * (dir * speed * delta)

	# Test the move; if blocked, flip direction and don't get "pushed" by the blocker.
	var hit := move_and_collide(motion, true) # test_only = true
	if hit:
		dir *= -1.0
		return

	# Apply the move for real.
	move_and_collide(motion, false)
