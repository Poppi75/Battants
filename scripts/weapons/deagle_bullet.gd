extends Area2D

@export var speed: float = 800.0
@export var auto_free_time: float = 2.0  # Optional: bullet despawns after this many seconds. Set to 0 to disable.
var owner_player = null
@export var damage_amount: int = 30

func _physics_process(delta: float) -> void:
	# Move forward based on current rotation (0 rad faces right).
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_life_time_timeout() -> void:
	
	print("[Bullet] Lifetime ended")
	queue_free()



func _on_body_entered(body: Node2D) -> void:
	if body != owner_player:
		if body.is_in_group("players"):
			
			print("[Bullet] Hit a player")
			body.take_damage(damage_amount)
		
		print("[Bullet] Destroyed")
		queue_free()
