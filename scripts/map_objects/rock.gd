extends CharacterBody2D

@export var health = 100

func take_damage(amount: float) -> void:
	if health <= 0:
		return

	health -= amount

	if health <= 0:
		queue_free()
