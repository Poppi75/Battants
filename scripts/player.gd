extends CharacterBody2D

@export var speed := 400
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var last_facing_angle := 0.0  # radians; 0 = facing up

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed

	if input_direction == Vector2.ZERO:
		# Keep facing the last direction when idle
		anim.rotation = last_facing_angle
		anim.play("idle")
	else:
		# Update facing to movement direction (diagonals = ~45°)
		last_facing_angle = Vector2.UP.angle_to(input_direction)
		anim.rotation = last_facing_angle
		anim.play("walk")

func _physics_process(_delta):
	get_input()
	move_and_slide()
