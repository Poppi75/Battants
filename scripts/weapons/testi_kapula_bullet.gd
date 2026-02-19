extends Area2D

@export var speed: float = 500.0
@export var damage_amount: int = 8

func _physics_process(delta: float) -> void:
	# Move forward based on current rotation (0 rad faces right).
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_life_time_timeout() -> void:
	
	print("[Bullet] Lifetime ended")
	queue_free()



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		
		print("[Bullet] Hit a player")
		body.take_damage(damage_amount)
	
	print("[Bullet] Destroyed")
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("shield"):
		queue_free()
	
	else:
		return
