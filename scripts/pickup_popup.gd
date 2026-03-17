extends Node2D

@onready var label: Label = $HBoxContainer/Label
@onready var icon_rect: TextureRect = $HBoxContainer/TextureRect

@export var float_speed := 40.0
@export var lifetime := 0.9

var _time_left := 0.0

func setup(text: String, icon: Texture2D = null) -> void:
	label.text = text

	icon_rect.texture = icon
	icon_rect.visible = (icon != null)

	_time_left = lifetime
	modulate.a = 1.0  # start fully visible

func _process(delta: float) -> void:
	# Move ONLY upwards (negative Y in 2D)
	position.y -= float_speed * delta

	# Fade out over lifetime
	_time_left -= delta
	var t := 0.0
	if lifetime > 0.0:
		t = clamp(_time_left / lifetime, 0.0, 1.0)

	modulate.a = t

	if _time_left <= 0.0:
		queue_free()
