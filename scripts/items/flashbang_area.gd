extends Area2D

@onready var FlashParticles: GPUParticles2D = $FlashParticles
@onready var explode_sound: AudioStreamPlayer2D = $explode_sound

var owner_player: Player = null

func _ready() -> void:
	explode_sound.play()
	
	FlashParticles.emitting = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.apply_stun()
		set_deferred("monitoring", false)


func _on_lifetime_timer_timeout() -> void:
	queue_free()
