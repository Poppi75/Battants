extends Area2D

@export var speed: float = 200.0
@export var auto_free_time: float = 1.3  # Optional: bullet despawns after this many seconds. Set to 0 to disable.
@onready var wave: AnimatedSprite2D = $wave

@onready var dink_sound: AudioStreamPlayer2D = $dink_sound

func _physics_process(delta: float) -> void:
	# Move forward based on current rotation (0 rad faces right).
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_life_time_timeout() -> void:
	
	print("[Bullet] Lifetime ended")
	queue_free()



func _on_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("players"):
		var damage_amount := randi_range(8, 32)
		print("[Bullet] Body hit for %d" % damage_amount)
		body.take_damage(damage_amount, false)

	
