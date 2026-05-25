extends Node2D

@export var fire_tick_damage := 2.0
@export var fire_tick_rate := 1.0

@export var burn_damage := 2.0
@export var burn_duration := 4.0

var touching_bodies := []

var active := true

var owner_player = null

func _ready():

	$Lifetime.start()
	$DamageTick.start()


func _on_damage_tick_timeout():

	if !active:
		return

	for body in touching_bodies:

		if is_instance_valid(body):
			body.take_damage(null, fire_tick_damage)


func _on_lifetime_timeout():

	active = false

	# Apply burn to everyone still inside
	for body in touching_bodies:

		if is_instance_valid(body):
			_apply_burn(body)

	touching_bodies.clear()

	# stop particles
	$flames.emitting = false

	# wait for particles to fade
	await get_tree().create_timer(1.0).timeout

	queue_free()


func _apply_burn(body):

	body.burns.append({
		"damage": burn_damage,
		"time_left": burn_duration
	})

	body.start_burn_timer()


func _on_body_exited(body: Node2D) -> void:
	if body in touching_bodies:
		touching_bodies.erase(body)

		_apply_burn(body)


func _on_body_entered(body: Node2D) -> void:
	if body == owner_player:
		return

	if !body.has_method("take_damage"):
		return

	if body in touching_bodies:
		return

	touching_bodies.append(body)
