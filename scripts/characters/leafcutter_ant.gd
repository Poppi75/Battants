extends Player

@onready var bodyslam: Area2D = $bodyslam
@onready var ability_cooldown: Timer = $AbilityCooldown
@export var ability_damage: float = 30.0
@export var stun_duration: float = 4.0
var visible_res = 0

@export var slam_effect: PackedScene

@onready var res_indicators = [
	$UI/Res_icons/Shield,
	$UI/Res_icons/Shield2,
	$UI/Res_icons/Shield3
]


func _on_passive_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body != self:
		res_indicators[visible_res].visible = true
		resistance += 0.3
		visible_res += 1
	else:
		return


func _on_passive_body_exited(body: Node2D) -> void:
	if body.is_in_group("players") and body != self:
		visible_res -= 1
		resistance -= 0.3
		res_indicators[visible_res].visible = false
	else:
		return

func _attack() -> void:
	super._attack()
	if equipped_slot == "class_ability" and !stunned and can_ability:
		active_ability_use = true
		if slam_effect != null:
			var effect = slam_effect.instantiate()
			get_tree().current_scene.add_child(effect)
			effect.global_position = global_position
		var bodies = bodyslam.get_overlapping_bodies()
		for body in bodies:
			if body != self:
				if body.is_in_group("players"):
					body.take_damage(self, ability_damage, false)
					body.ability_stun(stun_duration, 0.4)

				if body.is_in_group("map_props"):
					body.take_damage(ability_damage)

		can_ability = false
		active_ability_use = false
		ability_cooldown.start()


func _on_ability_cooldown_timeout() -> void:
	can_ability = true
