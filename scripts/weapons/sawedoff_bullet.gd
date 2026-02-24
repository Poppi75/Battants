extends Area2D

@export var speed: float = 550.0
@export var auto_free_time: float = 0.42 # pellets despawn fast

@export var headshot_damage: int = 7
@onready var dink_sound: AudioStreamPlayer2D = $dink_sound
var owner_player = null

# Optional: extra variation so pellets don't form a perfect arc
@export var speed_variance: float = 120.0 # 0 = disabled

var _life_left: float = 0.0
var _travel_speed: float = 0.0

func _ready() -> void:
	_life_left = auto_free_time
	_travel_speed = speed

	if speed_variance > 0.0:
		_travel_speed = max(0.0, speed + randf_range(-speed_variance, speed_variance))

func _physics_process(delta: float) -> void:
	# Lifetime countdown (no Timer node required)
	if auto_free_time > 0.0:
		_life_left -= delta
		if _life_left <= 0.0:
			queue_free()
			return

	# Move forward based on current rotation (0 rad faces right).
	global_position += Vector2.RIGHT.rotated(rotation) * _travel_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		var damage_amount := randi_range(3, 6)
		body.take_damage(damage_amount, false)

	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("shield"):
		queue_free()
	
	if area.name == "HeadshotArea":
		var player := area.get_parent()

		if player.is_in_group("players") and player != owner_player:
			var damage = headshot_damage
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
