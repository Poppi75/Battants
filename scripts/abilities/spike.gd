extends Area2D

@export var speed := 800.0
@export var auto_free_time := 3.0
@export var damage := 0.15

var owner_player: Node2D
var target: Node2D

var direction := Vector2.ZERO
var launched := false

func _ready() -> void:
	await get_tree().create_timer(auto_free_time).timeout
	queue_free()

func _physics_process(delta: float) -> void:

	if !launched:

		if is_instance_valid(target):

			var dir = (
				target.global_position - global_position
			).normalized()

			global_rotation = dir.angle() + deg_to_rad(90)

		return

	global_position += direction * speed * delta

func launch():

	if !is_instance_valid(target):
		queue_free()
		return

	var old_global = global_position

	reparent(get_tree().current_scene)

	global_position = old_global

	direction = (
		target.global_position - global_position
	).normalized()

	global_rotation = direction.angle() + deg_to_rad(90)

	launched = true

func _on_body_entered(body: Node2D) -> void:

	if body != owner_player:
		if body.is_in_group("players"):

			body.take_damage(
				owner_player,
				body.health * damage,
				false
			)

		queue_free()


func _on_life_time_timeout() -> void:
	queue_free()
