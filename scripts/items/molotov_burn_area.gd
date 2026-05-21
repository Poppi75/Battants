extends Area2D

@export var expand_time: float = 0.6
@export var full_size_time: float = 5.0
@export var fade_time: float = 1.0
@export var max_scale: float = 5.0
@export var damage_per_second: float = 20.0

# Damage tick settings
@export var tick_interval: float = 0.5

var time_alive: float = 0.0
var total_lifetime: float

# Set of bodies inside the area
var bodies_in_fire: Dictionary = {} # body -> true

var tick_timer: Timer
var owner_player: Node = null

@onready var break_sound: AudioStreamPlayer2D = $break_sound
@onready var burning_sound: AudioStreamPlayer2D = $burning_sound
@onready var flames: GPUParticles2D = $Flames
@onready var embers: GPUParticles2D = $Embers
@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready() -> void:
	randomize()
	total_lifetime = expand_time + full_size_time + fade_time

	# Ensure it starts small (prevents “pop” on the first rendered frame)
	scale = Vector2.ONE * 0.2
	_set_particles_alpha(1.0)

	break_sound.pitch_scale = randf_range(0.9, 1.1)
	break_sound.play()

	burning_sound.play()
	var tween := create_tween()
	tween.tween_property(burning_sound, "volume_db", -20.0, 5.0)
	tween.tween_callback(burning_sound.stop)

	lifetime_timer.wait_time = total_lifetime
	lifetime_timer.one_shot = true
	if not lifetime_timer.timeout.is_connected(_on_lifetime_timer_timeout):
		lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	lifetime_timer.start()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Damage tick timer only
	tick_timer = Timer.new()
	tick_timer.one_shot = false
	tick_timer.wait_time = max(tick_interval, 0.001)
	add_child(tick_timer)
	tick_timer.timeout.connect(_on_damage_tick)
	tick_timer.start()

func _process(delta: float) -> void:
	# Smooth visuals
	time_alive += delta
	_update_scale_and_fade()

func _on_damage_tick() -> void:
	_apply_damage(tick_timer.wait_time)

func _update_scale_and_fade() -> void:
	var s: float

	if time_alive < expand_time:
		var t: float = time_alive / max(expand_time, 0.001)
		s = lerp(0.2, max_scale, t)
		_set_particles_alpha(1.0)

	elif time_alive < expand_time + full_size_time:
		s = max_scale
		_set_particles_alpha(1.0)

	else:
		var fade_start: float = expand_time + full_size_time
		var t2: float = (time_alive - fade_start) / max(fade_time, 0.001)
		t2 = clamp(t2, 0.0, 1.0)

		s = lerp(max_scale, 0.0, t2)
		_set_particles_alpha(lerp(1.0, 0.0, t2))

	scale = Vector2.ONE * s

func _set_particles_alpha(alpha: float) -> void:
	alpha = clamp(alpha, 0.0, 1.0)

	if is_instance_valid(flames) and flames.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = flames.process_material
		var c := mat.color
		c.a = alpha
		mat.color = c

	if is_instance_valid(embers) and embers.process_material is ParticleProcessMaterial:
		var mat2: ParticleProcessMaterial = embers.process_material
		var c2 := mat2.color
		c2.a = alpha
		mat2.color = c2
		mat2.color = c2

func _apply_damage(dt: float) -> void:
	if damage_per_second <= 0.0:
		return

	var dmg := damage_per_second * dt

	for body in bodies_in_fire.keys():
		if not is_instance_valid(body):
			continue
		if not body.has_method("take_damage"):
			continue

		# Use your float-based signature
		body.take_damage(owner_player if owner_player else null, dmg, false)

func _on_body_entered(body: Node) -> void:
	bodies_in_fire[body] = true

	# Optional: if you want “immediate first tick” feel, uncomment:
	# _apply_damage(0.0) # (does nothing) — instead do:
	# if damage_per_second > 0.0 and body.has_method("take_damage"):
	#     body.take_damage(owner_player if owner_player else null, damage_per_second * tick_timer.wait_time, false)

func _on_body_exited(body: Node) -> void:
	bodies_in_fire.erase(body)

func _on_lifetime_timer_timeout() -> void:
	bodies_in_fire.clear()

	if is_instance_valid(tick_timer):
		tick_timer.stop()

	queue_free()
