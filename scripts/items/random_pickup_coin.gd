extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		print("[Pickup Coin] Player body entered")
		
		body.pickup()
		
		queue_free()
