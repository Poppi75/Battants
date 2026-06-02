extends CharacterBody2D

@export var health = 100

@onready var anim: Sprite2D = $Sprite2D

@export var rock_effect: PackedScene

var _flash_tween: Tween
var _default_modulate: Color = Color(1, 1, 1, 1)

func take_damage(amount: float) -> void:
	if health <= 0:
		return

	health -= amount

	_flash_on_damage()

	if health <= 0:
		if rock_effect != null:
			var effect = rock_effect.instantiate()
			get_tree().current_scene.add_child(effect)
			effect.global_position = global_position
		queue_free()

func _flash_on_damage() -> void:
	if not anim:
		return

	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()

	# Stronger white (push higher if you want, e.g. 3.0)
	anim.modulate = Color(4, 4, 4, 1.0)

	_flash_tween = create_tween()
	_flash_tween.set_parallel(false)

	# Hold the peak flash for a moment so it reads stronger
	_flash_tween.tween_interval(0.05)

	# Fade back faster (shorter duration feels punchier)
	_flash_tween.tween_property(anim, "modulate", _default_modulate, 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
