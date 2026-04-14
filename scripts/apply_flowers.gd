extends Area2D

@onready var flowers: Sprite2D = $flowers
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var applied = false

func apply_flowers(player):
	if applied == false:
		anim.visible = true
		anim.play("puff")
		flowers.visible = true
		applied = true
		
		player.flower_heal()
		
	else:
		return
