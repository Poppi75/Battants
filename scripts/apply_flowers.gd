extends Area2D

@onready var flowers: Sprite2D = $flowers

var player_in_area: Node = null
var can_apply = false
var applied = false

func apply_flowers():
	if can_apply == true and applied == false:
		flowers.visible = true
		applied = true
		
		player_in_area.flower_heal()
		
		
	else:
		return


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		can_apply = true
		
		if player_in_area == null:
			player_in_area = body

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		can_apply = false
		player_in_area = null
