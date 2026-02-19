extends Area2D

@export var speed: float = 800.0
@export var auto_free_time: float = 2.0

# Hardcoded headshot damage range
@export var headshot_damage: int = 100

var owner_player = null
@onready var dink_sound: AudioStreamPlayer2D = $Dink_sound


func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta


func _on_life_time_timeout() -> void:
	print("[Bullet] Lifetime ended")
	queue_free()


# =========================
# BODY HIT
# =========================
func _on_body_entered(body: Node2D) -> void:
	if body == owner_player:
		return

	if body.is_in_group("players"):
		var damage_amount := randi_range(25, 45)  # ← your existing random damage
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
		
	# Prevent self-hit
	if area.get_parent() == owner_player:
		return

	# Detect head
	if area.name == "HeadshotArea":
		var player := area.get_parent()

		if player.is_in_group("players"):
			var damage_amount := headshot_damage
			play_dink_sound()

			print("[Bullet] HEADSHOT for %d" % damage_amount)
			player.take_damage(damage_amount, true)

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
