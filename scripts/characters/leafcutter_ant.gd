extends Player

@onready var bodyslam: Area2D = $bodyslam
@onready var ability_cooldown: Timer = $AbilityCooldown
@export var ability_damage: float = 30.0
@export var stun_duration: float = 4.0

func _on_passive_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body != self:
		resistance += 0.3
	else:
		return


func _on_passive_body_exited(body: Node2D) -> void:
	if body.is_in_group("players") and body != self:
		resistance -= 0.3
	else:
		return

func _attack() -> void:
	super._attack()
	if equipped_slot == "class_ability" and !stunned and can_ability:
		active_ability_use = true
		var bodies = bodyslam.get_overlapping_bodies()
		for body in bodies:
			if body != self:
				body.take_damage(self, ability_damage, false)
				body.ability_stun(stun_duration, 0.4)
		can_ability = false
		active_ability_use = false
		ability_cooldown.start()


func _on_ability_cooldown_timeout() -> void:
	can_ability = true
