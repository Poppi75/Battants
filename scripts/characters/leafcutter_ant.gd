extends Player


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
	if equipped_slot == "class_ability" and stunned == false:
		return
