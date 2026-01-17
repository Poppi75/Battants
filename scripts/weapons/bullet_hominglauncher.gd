extends Area2D

@export var speed: float = 400.0
@export var turn_speed: float = 3.0
@export var auto_free_time: float = 3.0
@export var damage_amount: int = 35

@export var explosion_scene: PackedScene  # assign ExplosionAOE.tscn here

var owner_player: Player = null  # set by launcher

func _ready() -> void:
	if auto_free_time > 0.0:
		var timer := Timer.new()
		timer.wait_time = auto_free_time
		timer.one_shot = true
		add_child(timer)
		timer.timeout.connect(_on_life_time_timeout)
		timer.start()

func _physics_process(delta: float) -> void:
	if owner_player != null and owner_player.equipped_slot == "ranged":
		var dir: Vector2 = owner_player.aim_direction
		if dir != Vector2.ZERO:
			var target_angle: float = dir.angle()
			var diff: float = wrapf(target_angle - rotation, -PI, PI)
			var step: float = clamp(diff, -turn_speed * delta, turn_speed * delta)
			rotation += step
	
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_life_time_timeout() -> void:
	print("[HomingMissile] Lifetime ended")
	_explode()

func _on_body_entered(body: Node2D) -> void:
	# Ignore the owner (no self-hit)
	if body == owner_player:
		return

	if body.is_in_group("players"):
		print("[HomingMissile] Hit a player (direct)")
		# Optional: direct-hit bonus
		# body.take_damage(damage_amount)

	print("[HomingMissile] Exploding")
	_explode()

func _explode() -> void:
	# Defer actual explosion spawn to avoid "flushing queries" error
	call_deferred("_explode_now")

func _explode_now() -> void:
	if explosion_scene == null:
		queue_free()
		return

	var explosion = explosion_scene.instantiate()
	get_tree().current_scene.add_child(explosion)

	explosion.global_position = global_position
	explosion.damage_amount = damage_amount
	explosion.owner_player = owner_player

	queue_free()
