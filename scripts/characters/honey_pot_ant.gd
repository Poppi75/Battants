extends Player

var can_take_damage = true
@onready var hp_freeze: Timer = $hp_freeze
var can_freeze = true
@export var freeze_activation = 10
@export var crossbow: PackedScene


func _ready() -> void:
	super._ready()
	var item = crossbow.instantiate()
	class_ability_socket.add_child(item)

	if item is Node2D:
		item.position = Vector2.ZERO
		item.rotation = 0.0
		item.scale = Vector2.ONE

	item.owner_player = self

	equipped["class_ability"] = item


func take_damage(attacker: Node2D, damage: float, is_headshot: bool = false) -> void:
	if can_take_damage == true:

		if health <= 0:
			return

		if attacker != null:
			if "can_extra_dmg" in attacker and attacker.can_extra_dmg == true:
				damage = damage + 20
				attacker.can_extra_dmg = false
				attacker.extra_dmg_timer.start()
				attacker.animate_cloak(attacker.cloak_progress < 0.5, 0.6)
				attacker._visible = true

			damage = damage - damage * resistance
			damage = round(damage * 100) / 100
			health -= damage

			if "damage_dealt" in attacker:
				attacker.damage_dealt += damage
				if attacker.damage_dealt >= 25:
					for i in range(int(attacker.damage_dealt / 25)):
						burns.append({
							"damage": 2.0,
							"time_left": 4.0
						})
					start_burn_timer()
					attacker.damage_dealt = 0.0

		else:
			damage = damage - damage * resistance
			damage = round(damage * 100) / 100
			health -= damage

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
