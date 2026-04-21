extends Node2D

var owner_player = null
var damage = 50
var durability = 1
var can_attack = true
var reverse = false
@onready var area_2d: Area2D = $Hitbox
@onready var knife_cooldown: Timer = $KnifeCooldown
@onready var anim: AnimatedSprite2D = $Sprite2D
@onready var icon = load("res://assets/weapons/knife.png")

func _ready() -> void:
	anim.play("Idle")

func attack() -> void:
	if !can_attack:
		return

	can_attack = false


	if !reverse:
		anim.play("Attack")
	else:
		anim.play("Reverse_Attack")
	reverse = !reverse

	for body in area_2d.get_overlapping_bodies():
		if body.is_in_group("players") and body != owner_player:
			durability -= 1
			body.take_damage(damage, false)
	
	
	knife_cooldown.start()
	
	if durability == 0:
		owner_player.melee_icon.texture = owner_player.base_melee_icon
		owner_player.equip_base_melee()
		queue_free()


func _on_knife_cooldown_timeout() -> void:
	can_attack = true


func _on_sprite_2d_animation_finished() -> void:
	if reverse:
		anim.play("Reverse_Idle")
	else:
		anim.play("Idle")
