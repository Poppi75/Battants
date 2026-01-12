extends CharacterBody2D

@export var speed := 200
@export var turn_speed := 8.0 # radians per second

@export var controls: Resource = null

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var weapon: Node = null

func equip_weapon(w: Node) -> void:
	weapon = w
	if weapon.has_method("equip"):
		weapon.equip(self)

func _physics_process(delta):
	var input_dir = Input.get_vector(controls.left, controls.right, controls.up, controls.down)

	# Movement
	velocity = input_dir * speed

	if input_dir != Vector2.ZERO:
		# Smooth rotation of the whole character
		var target_angle = Vector2.UP.angle_to(input_dir)
		rotation = lerp_angle(rotation, target_angle, turn_speed * delta)

		# Play walk animation
		if anim.animation != "walk":
			anim.play("walk")
	else:
		# Play idle animation
		if anim.animation != "idle":
			anim.play("idle")

	move_and_slide()

	# Attack input
	if controls and weapon != null and Input.is_action_just_pressed(controls.attack):
		if weapon.has_method("fire"):
			weapon.fire(self)
