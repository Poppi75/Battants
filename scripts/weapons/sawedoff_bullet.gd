extends Area2D

@export var speed: float = 550.0
@export var auto_free_time: float = 0.42 # pellets despawn fast

@export var damage_amount: int = 6

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
		body.take_damage(damage_amount)

	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("shield"):
		queue_free()
	
	else:
		return
