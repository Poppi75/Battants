extends Node2D

@onready var label: Label = $Label

var float_speed := 40
var lifetime := 0.8
var velocity := Vector2.ZERO

func setup(damage: int, is_crit: bool = false):
	# Set text
	label.text = str(damage)

	# Color logic
	if is_crit:
		label.modulate = Color(1.0, 0.85, 0.2) # GOLD
		label.scale = Vector2(1.4, 1.4)
	else:
		label.modulate = Color(1, 0.2, 0.2) # RED

	# Random float direction
	velocity = Vector2(
		randf_range(-20, 20),
		- float_speed
	)

func _process(delta):
	position += velocity * delta

	lifetime -= delta
	if lifetime <= 0:
		queue_free()
