extends CharacterBody2D

@export var health = 50
@export var damage_amount = 40

@export var explosion_scene: PackedScene

func take_damage(amount: float) -> void:
	if health <= 0:
		return

	health -= amount

	if health <= 0:
		explode()


func explode() -> void:
	await get_tree().physics_frame
	if explosion_scene:
		var explosion: Node2D = explosion_scene.instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.add_child(explosion)
		explosion.damage_amount = damage_amount

	queue_free()
