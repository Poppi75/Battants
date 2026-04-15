extends Area2D

@export var speed: float = 220.0
@export var auto_free_time: float = 1.3 # Bullet despawns after this many seconds (0 = disabled)

# --- Split settings ---
@export var spread_angle: float = 12.0  # Degrees between bullets
@export var bullet_scene: PackedScene = preload("res://scenes/weapons/bullet_blast_cannon.tscn")
@export var bullet_count: int = 5

# 0 = no split. 1 = split once. 2 = split, and children split once, etc.
@export var splits_remaining: int = 2

# If true, this bullet will be destroyed immediately after it successfully splits once.
@export var destroy_after_first_split: bool = false

@onready var wave: AnimatedSprite2D = $wave
@onready var dink_sound: AudioStreamPlayer2D = $dink_sound

var owner_player: Player = null
var _did_split_this_collision: bool = false # stops multiple splits in one "overlap moment"
var _has_split_once: bool = false           # for destroy_after_first_split option

func _ready() -> void:
	# Splitting is ONLY on collision now (no timed split).
	pass

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func spawn_split_bullets() -> bool:
	# Returns true if it actually spawned children
	if bullet_scene == null:
		push_warning("bullet_scene is NULL")
		return false

	if splits_remaining <= 0:
		return false

	# Consume one split "charge" on THIS bullet; children inherit the remainder.
	splits_remaining -= 1
	_has_split_once = true

	var base_angle := rotation
	var total_spread := deg_to_rad(spread_angle * float(bullet_count - 1))
	var start_angle := base_angle - total_spread / 2.0

	for i in range(bullet_count):
		var new_bullet := bullet_scene.instantiate()
		get_parent().add_child(new_bullet)

		new_bullet.global_position = global_position
		new_bullet.rotation = start_angle + deg_to_rad(spread_angle * float(i))

		# Inherit ownership + remaining splits (THIS is what allows children to split)
		new_bullet.owner_player = owner_player
		new_bullet.splits_remaining = splits_remaining

		# Optional: inherit the same behavior to destroy-after-split
		new_bullet.destroy_after_first_split = destroy_after_first_split

	return true

func _on_life_time_timeout() -> void:
	print("[Bullet] Lifetime ended")
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Ignore hitting the shooter
	if body == owner_player:
		return

	# Damage players
	if body.is_in_group("players"):
		var damage_amount := randi_range(32, 69)
		print("[Bullet] Body hit for %d" % damage_amount)
		body.take_damage(damage_amount, false)

	# Split on collision (once per overlap burst)
	if !_did_split_this_collision and splits_remaining > 0:
		_did_split_this_collision = true

		var did_split := spawn_split_bullets()

		# Optionally destroy this bullet after its first successful split
		if did_split and destroy_after_first_split and _has_split_once:
			queue_free()

func _on_body_exited(_body: Node2D) -> void:
	# Allows splitting again on the next distinct collision
	_did_split_this_collision = false
