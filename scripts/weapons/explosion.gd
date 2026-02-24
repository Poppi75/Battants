extends Area2D

@export var damage_amount: int = 0
@export var explosion_duration: float = 0.1
@export var particle_lifetime: float = 0.6

# Tracks bodies we've already damaged so we never double-hit the same target
var _damaged: Dictionary = {}

@onready var particles: GPUParticles2D = $ExplosionParticles
@onready var explosion: AudioStreamPlayer2D = $explosion

func _ready() -> void:
	explosion.play()

	monitoring = true
	set_deferred("monitorable", true)

	# Damage anything already overlapping on first physics frame
	await get_tree().physics_frame
	_do_initial_overlap_damage()

	# Timer to end the explosion area damage phase
	var damage_timer := Timer.new()
	damage_timer.wait_time = explosion_duration
	damage_timer.one_shot = true
	add_child(damage_timer)
	damage_timer.timeout.connect(_end_damage_phase)
	damage_timer.start()

	_start_particles()

func _do_initial_overlap_damage() -> void:
	var bodies := get_overlapping_bodies()
	print("[Explosion] initial overlapping bodies: ", bodies.size())
	for body in bodies:
		_apply_damage(body)

func _on_body_entered(body: Node2D) -> void:
	_apply_damage(body)

func _apply_damage(body: Node2D) -> void:
	# Prevent double damage from initial overlap + body_entered
	if _damaged.has(body):
		return
	_damaged[body] = true

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
