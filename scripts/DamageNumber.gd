extends Label

@export var float_distance: float = 24.0
@export var duration: float = 0.6

func show_damage(amount: int) -> void:
	text = str(amount)

	# Start a little random offset so multiple numbers don't perfectly overlap
	position += Vector2(randf_range(-4, 4), randf_range(-2, 2))

	var tween := create_tween()
	# Move up
	tween.tween_property(self, "position:y", position.y - float_distance, duration)
	# Fade out
	modulate.a = 1.0
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	# Free when finished
	tween.tween_callback(queue_free)
