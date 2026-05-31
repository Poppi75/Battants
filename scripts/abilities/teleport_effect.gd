extends GPUParticles2D





func _on_life_time_timeout() -> void:
		queue_free()
