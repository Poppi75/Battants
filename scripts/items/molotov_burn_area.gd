extends Area2D

@export var expand_time: float = 0.6        # time to grow to full size
@export var full_size_time: float = 5.0     # time it stays max size
@export var fade_time: float = 1.0          # time to shrink/fade out
@export var max_scale: float = 5.0          # how big the patch gets
@export var damage_per_second: float = 20.0 # damage over time

# TICK SETTINGS (fixed update)
@export var tick_interval: float = 0.5     # 20 ticks/sec. Try 0.1 for 10 ticks/sec.

var time_alive: float = 0.0
var total_lifetime: float
var bodies_in_fire := {}      # just used as a set: body -> true
var damage_accumulator := {}  # body -> accumulated float damage

@onready var break_sound: AudioStreamPlayer2D = $break_sound
@onready var burning_sound: AudioStreamPlayer2D = $burning_sound
@onready var flames: GPUParticles2D = $Flames
@onready var embers: GPUParticles2D = $Embers

var tick_timer: Timer
var owner_player = null

func _ready() -> void:
	randomize()
	total_lifetime = expand_time + full_size_time + fade_time

	break_sound.pitch_scale = randf_range(0.9, 1.1)
	break_sound.play()

	burning_sound.play()

	var tween := create_tween()
	tween.tween_property(burning_sound, "volume_db", -20.0, 5)  # fade out
	tween.tween_callback(burning_sound.stop)                    # stop after fade

	var lifetime_timer: Timer = $LifetimeTimer
	lifetime_timer.wait_time = total_lifetime
	lifetime_timer.one_shot = true
	if not lifetime_timer.timeout.is_connected(_on_lifetime_timer_timeout):
		lifetime_timer.timeout.connect(_on_lifetime_timer_timeout)
	lifetime_timer.start()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# --- TICK TIMER ---
	tick_timer = Timer.new()
	tick_timer.one_shot = false
	tick_timer.wait_time = max(tick_interval, 0.001)
	add_child(tick_timer)
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()

	# Initialize visuals immediately (tick-based systems otherwise wait until first tick)
	_update_scale_and_fade()
	_apply_damage(tick_timer.wait_time)

# Remove frame-based processing entirely
# func _process(delta: float) -> void:
#     pass

func _on_tick() -> void:
	var dt := tick_timer.wait_time

	time_alive += dt
	_update_scale_and_fade()
	_apply_damage(dt)

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

func _apply_damage(delta: float) -> void:
	if damage_per_second <= 0.0:
		return

	for body in bodies_in_fire.keys():
		if not is_instance_valid(body):
			continue
		if not body.has_method("take_damage"):
			continue

		var dmg: float = damage_per_second * delta

		if not damage_accumulator.has(body):
			damage_accumulator[body] = 0.0

		damage_accumulator[body] += dmg

		var whole: float = float(damage_accumulator[body])
		if whole > 0:
			damage_accumulator[body] -= float(whole)
			body.take_damage(owner_player, whole, false)

func _on_body_entered(body: Node) -> void:
	if bodies_in_fire.has(body):
		return
	bodies_in_fire[body] = true
	damage_accumulator[body] = 0.0

func _on_body_exited(body: Node) -> void:
	if not bodies_in_fire.has(body):
		return
	bodies_in_fire.erase(body)
	damage_accumulator.erase(body)

func _on_lifetime_timer_timeout() -> void:
	bodies_in_fire.clear()
	damage_accumulator.clear()

	if is_instance_valid(tick_timer):
		tick_timer.stop()

	queue_free()
