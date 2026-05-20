extends Player

var can_extra_dmg: bool = false
@onready var extra_dmg_timer: Timer = $ExtraDmgTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var bars := [
	$UI/health,
	$UI/extra_health,
	$UI/damagetaken
]

var cloak_progress := 0.0
var cloak_tween: Tween
var bars_tween: Tween

func _ready() -> void:
	super._ready()
	if sprite.material:
		sprite.material = sprite.material.duplicate()
		sprite.material.resource_local_to_scene = true

	set_cloak_progress(0.0)
	set_bars_alpha(1.0)

func set_cloak_progress(v: float) -> void:
	cloak_progress = clampf(v, 0.0, 1.0)
	var mat := sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("cloak_progress", cloak_progress)

func set_bars_alpha(a: float) -> void:
	a = clampf(a, 0.0, 1.0)
	for b in bars:
		if is_instance_valid(b):
			b.modulate.a = a

func fade_bars(to_visible: bool, duration: float = 0.2) -> void:
	var target_a := 1.0 if to_visible else 0.0

	if bars_tween and bars_tween.is_running():
		bars_tween.kill()

	bars_tween = create_tween()
	bars_tween.set_trans(Tween.TRANS_SINE)
	bars_tween.set_ease(Tween.EASE_IN_OUT)

	if to_visible:
		# show first, then fade in
		for b in bars:
			if is_instance_valid(b):
				b.visible = true
		bars_tween.tween_method(set_bars_alpha, bars[0].modulate.a if is_instance_valid(bars[0]) else 0.0, target_a, duration)
	else:
		# fade out, then hide
		bars_tween.tween_method(set_bars_alpha, bars[0].modulate.a if is_instance_valid(bars[0]) else 1.0, target_a, duration)
		bars_tween.tween_callback(func ():
			for b in bars:
				if is_instance_valid(b):
					b.visible = false
		)

func animate_cloak(to_on: bool, duration := 0.6) -> void:
	var target := 1.0 if to_on else 0.0

	if cloak_tween and cloak_tween.is_running():
		cloak_tween.kill()

	cloak_tween = create_tween()
	cloak_tween.set_trans(Tween.TRANS_SINE)
	cloak_tween.set_ease(Tween.EASE_IN_OUT)

	# fade UI alongside cloak
	if to_on:
		fade_bars(false, 0.6) # fade out quickly at start
	else:
		# keep hidden until cloak finishes, then fade back in
		cloak_tween.tween_callback(func(): fade_bars(true, 0.6)).set_delay(duration)

	cloak_tween.tween_method(set_cloak_progress, cloak_progress, target, duration)

func _on_extra_dmg_timer_timeout() -> void:
	can_extra_dmg = true
	animate_cloak(cloak_progress < 0.5, 0.6)
