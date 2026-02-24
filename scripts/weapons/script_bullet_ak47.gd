extends Area2D

@export var speed: float = 800.0
@export var auto_free_time: float = 3.0  # Optional: bullet despawns after this many seconds. Set to 0 to disable.

@export var headshot_damage: int = 25
@onready var dink_sound: AudioStreamPlayer2D = $dink_sound

func _physics_process(delta: float) -> void:
	# Move forward based on current rotation (0 rad faces right).
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_life_time_timeout() -> void:
	
	print("[Bullet] Lifetime ended")
	queue_free()



func _on_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("players"):
		var damage_amount := randi_range(6, 13)
		print("[Bullet] Body hit for %d" % damage_amount)
		body.take_damage(damage_amount, false)

	print("[Bullet] Destroyed")
	queue_free()

# =========================
# HEADSHOT HIT
# =========================
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("shield"):
		queue_free()
	# Detect head
	if area.name == "HeadshotArea":
		var player := area.get_parent()

		if player.is_in_group("players"):
			var damage := headshot_damage
			play_dink_sound()

			print("[Bullet] HEADSHOT for %d" % damage)
			player.take_damage(damage, true)

			queue_free()  # Bullet can die immediately
			
func play_dink_sound() -> void:
	var sound_player := AudioStreamPlayer2D.new()
	sound_player.stream = dink_sound.stream
	sound_player.position = global_position
	sound_player.pitch_scale = randf_range(0.95, 1.05)
	sound_player.autoplay = false

	# Add to scene root so it's independent of the bullet
	get_tree().current_scene.add_child(sound_player)

	# Play and free when done
	sound_player.play()
	sound_player.finished.connect(Callable(sound_player, "queue_free"))
