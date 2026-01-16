extends Area2D

@export var damage_amount: int = 35
@export var particle_lifetime: float = 0.6  # match GPUParticles2D.lifetime

var owner_player: Player = null  # set by missile so explosion doesn't hurt owner
var _has_triggered: bool = false

@onready var particles: GPUParticles2D = $ExplosionParticles

func _ready() -> void:
	# Defer damage to avoid flushing query issues
	call_deferred("_do_damage")
	
	# Configure and play particles
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
		call_deferred("queue_free")

func _do_damage() -> void:
	if _has_triggered:
		return
	_has_triggered = true

	var bodies: Array = get_overlapping_bodies()
	for body in bodies:
		if body == owner_player:
			continue
		if body.is_in_group("players"):
			print("[Explosion] Damaging player: ", body.name)
			body.take_damage(damage_amount)

func _on_particles_done() -> void:
	queue_free()
