extends Area2D

@export var speed: float = 800.0
@export var auto_free_time: float = 2.0
var owner_player = null

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_life_time_timeout() -> void:
	print("[Bullet] Lifetime ended")
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body != owner_player:
		if body.is_in_group("players"):
			var damage_amount := randi_range(25, 45)
			print("[Bullet] Hit a player with damage %d" % damage_amount)
			body.take_damage(damage_amount)

		print("[Bullet] Destroyed")
		queue_free()
