extends Node2D

var owner_player = null
var damage = 5
var timer_can_attack = true
var can_attack = false
@onready var area_2d: Area2D = $Area2D
@onready var bite_cooldown: Timer = $BiteCooldown

func attack() -> void:
	if can_attack and timer_can_attack == true:
		for overlapped_body in area_2d.get_overlapping_bodies():
			if overlapped_body.is_in_group("players") and overlapped_body != owner_player:
				overlapped_body.take_damage(damage, false)
			timer_can_attack = false
			bite_cooldown.start()
	else:
		return

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body != owner_player:
		can_attack = true


func _on_bite_cooldown_timeout() -> void:
	timer_can_attack = true
