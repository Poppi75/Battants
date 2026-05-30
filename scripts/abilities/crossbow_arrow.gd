extends Area2D

@export var speed: float = 800.0
@export var damage: float = 20
var owner_player = null

func _physics_process(delta: float) -> void:
	global_position += Vector2.RIGHT.rotated(rotation) * speed * delta

func _on_life_time_timeout() -> void:
	print("[Bullet] Lifetime ended")
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body != owner_player:
		body.take_damage(owner_player if owner_player else null, damage, false)
		owner_player.heal(damage / 2)
