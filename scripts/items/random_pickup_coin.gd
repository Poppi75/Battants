extends Area2D

@onready var pickup_sound: AudioStreamPlayer2D = $pickup_sound
@onready var sprite_2d_2: Sprite2D = $Sprite2D2

var cant_enter = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and cant_enter == true:
		print("[Pickup Coin] Player body entered")
		cant_enter = false
		
		body.pickup()
		
		sprite_2d_2.visible = false
		
		pickup_sound.play()
		await pickup_sound.finished
		
		queue_free()
