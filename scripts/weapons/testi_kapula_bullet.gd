extends Area2D

@export var speed: float = 800.0
@export var auto_free_time: float = 3.0  # Optional: bullet despawns after this many seconds. Set to 0 to disable.


func _physics_process(delta: float) -> void:
	# Move forward based on current rotation (0 rad faces right).
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta



func _on_life_time_timeout() -> void:
	queue_free()
