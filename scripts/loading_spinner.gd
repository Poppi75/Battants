extends TextureRect

@export var speed := 180.0  # degrees per second

func _process(delta):
	rotation_degrees += speed * delta
