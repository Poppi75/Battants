extends Area2D

@onready var flowers: Sprite2D = $flowers

var applied = false

func apply_flowers(player):
	if applied == false:
		flowers.visible = true
		applied = true
		
		player.flower_heal()
		
	else:
		return
