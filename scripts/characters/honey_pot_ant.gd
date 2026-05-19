extends Player

var can_take_damage = true
@onready var hp_freeze: Timer = $hp_freeze
var can_freeze = true
@export var freeze_activation = 10

func take_damage(attacker: Node2D, damage: float, is_headshot: bool = false) -> void:
	if can_take_damage == true:

		if health <= 0:
			return

		if "can_extra_dmg" in attacker and attacker.can_extra_dmg == true:
			damage = damage * 1.35

		if "can_extra_dmg" in attacker:
			attacker.can_extra_dmg = false
			attacker.extra_dmg_timer.start()

		health -= damage
		
		if "damage_dealt" in attacker:
			attacker.damage_dealt += damage
			if attacker.damage_dealt >= 25:
				burn()
				attacker.damage_dealt = 0.0

		if health <= freeze_activation and can_freeze:
			health += freeze_activation - health
			last_stand()

		damage_sound_play()

		_spawn_damage_number(damage, is_headshot, false)

		update_health_bars()
		_flash_on_damage()

		if health <= 0:
			die()
	else:
		return

func last_stand() -> void:
	can_take_damage = false
	can_freeze = false
	hp_freeze.start()


func _on_timer_timeout() -> void:
	can_take_damage = true
