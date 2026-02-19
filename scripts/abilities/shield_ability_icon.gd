extends Node2D

@export var shield_ability_scene: PackedScene

@onready var icon = load("res://assets/ability_art/shield_icon.png")

var owner_player: Player = null # set by your _equip_item() via item.owner_player = self

func _process(_delta: float) -> void:
	if owner_player == null:
		return

	# "shield ability is used (shoot is pressed)"
	if Input.is_action_just_pressed("shoot"):
		_activate_shield()

func _activate_shield() -> void:
	if shield_ability_scene == null:
		push_warning("Assign a scene to 'shield_ability_scene' in the Inspector.")
		return

	# activate at the previous shield_ability_icon position (player's ability icon)
	if owner_player.ability_icon == null:
		push_warning("owner_player.ability_icon is missing.")
		return

	var shield = shield_ability_scene.instantiate()
	get_tree().current_scene.add_child(shield)

	# place it where the icon currently is (i.e., the icon's "previous" position until it moves)
	shield.global_position = owner_player.ability_icon.global_position

	# optional: follow the same owner pattern as your weapon script/equip function
	if "owner_player" in shield:
		shield.owner_player = owner_player
