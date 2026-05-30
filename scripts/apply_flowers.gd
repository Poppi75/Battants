extends Area2D

@onready var flowers: Sprite2D = $flowers
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var heal: float = 25.0

var applied = false

func apply_flowers(player):
	if applied == false:
		anim.visible = true
		anim.play("puff")
		flowers.visible = true
		applied = true
		
		player.heal(heal)
		
	else:
		return
