extends Area2D

@export var expand_time: float = 4.0        # time to grow to full size
@export var full_size_time: float = 9.0     # time it stays max size
@export var fade_time: float = 3.0          # time to shrink/fade out
@export var max_scale: float = 5.0          # how big the patch gets
@export var damage_per_second: float = 35.0 # damage over time

var time_alive: float = 0.0
var total_lifetime: float
var bodies_in_fire: = {}      # just used as a set: body -> true
var damage_accumulator: = {}  # body -> accumulated float damage

var owner_player = null

@onready var break_sound: AudioStreamPlayer2D = $break_sound
@onready var burning_sound: AudioStreamPlayer2D = $burning_sound
@onready var flames: GPUParticles2D = $Flames
@onready var embers: GPUParticles2D = $Embers

func _ready() -> void:
	randomize()
	total_lifetime = expand_time + full_size_time + fade_time

	break_sound.pitch_scale = randf_range(0.9, 1.1)
	break_sound.play()

	burning_sound.play()
	
	var tween := create_tween()
	tween.tween_property(burning_sound, "volume_db", -20.0, 5)  # fade out
	tween.tween_callback(burning_sound.stop)                        # stop after fade

	var lifetime_timer: Timer = $LifetimeTimer
	lifetime_timer.wait_time = total_lifetime
	lifetime_timer.one_shot = true

	if not lifetime_timer.timeout.is_connected(_on_lifetime_timer_timeout):
		lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)

	lifetime_timer.start()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	time_alive += delta
	_update_scale_and_fade()
	# _apply_damage(delta) # no damage should be done

func _update_scale_and_fade() -> void:
	var s: float

	if time_alive < expand_time:
		# grow from tiny to max_scale
		var t: float = time_alive / max(expand_time, 0.001)
		s = lerp(0.2, max_scale, t)

		# fully visible during grow
		_set_particles_alpha(1.0)
	elif time_alive < expand_time + full_size_time:
		# full size, full opacity
		s = max_scale
		_set_particles_alpha(1.0)
	else:
		# shrink & fade during fade_time
		var fade_start: float = expand_time + full_size_time
		var t2: float = (time_alive - fade_start) / max(fade_time, 0.001)
		t2 = clamp(t2, 0.0, 1.0)

		# scale from max_scale -> 0
		s = lerp(max_scale, 0.0, t2)

		# alpha from 1 -> 0 (fade out)
		var alpha: float = lerp(1.0, 0.0, t2)
		_set_particles_alpha(alpha)

	scale = Vector2.ONE * s

func _set_particles_alpha(alpha: float) -> void:
	alpha = clamp(alpha, 0.0, 1.0)

	if is_instance_valid(flames) and flames.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = flames.process_material
		var col: Color = mat.color
		col.a = alpha
		mat.color = col

	if is_instance_valid(embers) and embers.process_material is ParticleProcessMaterial:
		var mat2: ParticleProcessMaterial = embers.process_material
		var col2: Color = mat2.color
		col2.a = alpha
		mat2.color = col2

func _apply_damage(_delta: float) -> void:
	pass

func _on_body_entered(body: Node) -> void:
	if bodies_in_fire.has(body):
		return

	# Just track bodies that are inside; no slowing
	bodies_in_fire[body] = true
	damage_accumulator[body] = 0.0

func _on_body_exited(body: Node) -> void:
	if not bodies_in_fire.has(body):
		return

	bodies_in_fire.erase(body)
	damage_accumulator.erase(body)

func _on_lifetime_timer_timeout() -> void:
	# Just clear state and delete; no speed to restore anymore
	bodies_in_fire.clear()
	damage_accumulator.clear()
	queue_free()
