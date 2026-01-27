extends Area2D

@export var damage_amount: int = 0
@export var explosion_duration: float = 0.1
@export var particle_lifetime: float = 0.6

var _has_triggered: bool = false
@onready var particles: GPUParticles2D = $ExplosionParticles

func _ready() -> void:
	monitoring = true
	monitorable = true

	# Damage anything already overlapping on first physics frame
	await get_tree().physics_frame
	_do_initial_overlap_damage()

	# Then also damage anything new that enters during the short explosion duration
	body_entered.connect(_on_body_entered)

	# Timer to end the explosion area
	var damage_timer := Timer.new()
	damage_timer.wait_time = explosion_duration
	damage_timer.one_shot = true
	add_child(damage_timer)
	damage_timer.timeout.connect(_end_damage_phase)
	damage_timer.start()

	_start_particles()

func _do_initial_overlap_damage() -> void:
	if _has_triggered:
		return
	_has_triggered = true

	var bodies := get_overlapping_bodies()
	print("[Explosion] initial overlapping bodies: ", bodies.size())
	for body in bodies:
		_apply_damage(body)

func _on_body_entered(body: Node2D) -> void:
	_apply_damage(body)

func _apply_damage(body: Node2D) -> void:
	if body.is_in_group("players"):
		print("[Explosion] Damaging player: ", body.name)
		body.take_damage(damage_amount)

func _end_damage_phase() -> void:
	monitoring = false
	# Let particles finish, node gets freed in _on_particles_done

func _start_particles() -> void:
	if particles:
		particles.one_shot = true
		particles.lifetime = particle_lifetime
		particles.emitting = true

		var t := Timer.new()
		t.wait_time = particle_lifetime
		t.one_shot = true
		add_child(t)
		t.timeout.connect(_on_particles_done)
		t.start()
	else:
		queue_free()

func _on_particles_done() -> void:
	queue_free()
