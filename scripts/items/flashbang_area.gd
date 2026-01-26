extends Area2D

@export var radius: float = 300.0
@export var max_stun_time: float = 2.5
@export var wall_mask: int = 1
@onready var FlashParticles: GPUParticles2D = $FlashParticles

var owner_player: Player = null

func _ready() -> void:
	FlashParticles.emitting = true

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		body.apply_stun()


func _on_lifetime_timer_timeout() -> void:
	queue_free()
