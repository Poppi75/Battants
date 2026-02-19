extends Area2D


func _on_shield_time_timeout() -> void:
	queue_free()
