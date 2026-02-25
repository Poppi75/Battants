extends Area2D

@onready var FlashParticles: GPUParticles2D = $FlashParticles
@onready var explode_sound: AudioStreamPlayer2D = $explode_sound
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var owner_player = null

func _ready() -> void:
	explode_sound.play()
	FlashParticles.emitting = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.apply_stun()

func _on_lifetime_timer_timeout() -> void:
	queue_free()

func _on_collision_timer_timeout() -> void:
	collision_shape_2d.disabled = true
