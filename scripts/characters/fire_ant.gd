extends Player

var damage_dealt: float = 0.0

# ===== Dash ability =====
var dash_charge := 0.0

@export var max_dash_charge := 2.0
@export var min_dash_distance := 120.0
@export var max_dash_distance := 520.0
@export var dash_speed := 1400.0

@export var dash_damage := 25.0

var dash_direction := Vector2.ZERO
var is_dashing := false

var dash_velocity := Vector2.ZERO
var dash_time_left := 0.0

@onready var ability_cooldown: Timer = $AbilityCooldown

@export var burn_trail_scene: PackedScene

var hit_targets := []


func _physics_process(delta: float) -> void:

	# ===== DASH MOVEMENT =====
	if is_dashing:

		velocity = dash_velocity

		move_and_slide()

		dash_time_left -= delta

		# Stop if we hit a wall
		if is_on_wall():
			_finish_dash()

		# Stop when dash duration ends
		if dash_time_left <= 0.0:
			_finish_dash()

		return

	# Normal player logic
	super._physics_process(delta)

	# ===== DASH CHARGE =====
	if equipped_slot == "class_ability":

		# Start charging
		if controller.shoot_held and can_ability and !charging_dash:
			charging_dash = true
			dash_charge = 0.0

		# Continue charging
		if charging_dash:
			dash_charge += delta
			dash_charge = min(dash_charge, max_dash_charge)

		# Release -> dash
		if charging_dash and !controller.shoot_held:
			charging_dash = false
			_activate_dash()


func _activate_dash():

	can_ability = false

	is_dashing = true

	hit_targets.clear()

	dash_direction = controller.aim.normalized()

	var t := dash_charge / max_dash_charge

	var dash_distance = lerp(
		min_dash_distance,
		max_dash_distance,
		t
	)

	var dash_time = dash_distance / dash_speed

	dash_velocity = dash_direction * dash_speed
	dash_time_left = dash_time

	$DashHitbox.monitoring = true

	_spawn_dash_trail_loop()


func _finish_dash():

	is_dashing = false

	velocity = Vector2.ZERO
	dash_velocity = Vector2.ZERO
	ability_cooldown.start()

	$DashHitbox.monitoring = false


func _spawn_dash_trail_loop():

	var timer := Timer.new()

	timer.wait_time = 0.05
	timer.one_shot = false

	add_child(timer)

	timer.start()

	timer.timeout.connect(func():

		if !is_dashing:
			timer.queue_free()
			return

		var trail = burn_trail_scene.instantiate()

		get_tree().current_scene.add_child(trail)

		trail.owner_player = self
		trail.global_position = global_position
	)


func _on_dash_hitbox_body_entered(body):

	if !is_dashing:
		return

	if body == self:
		return

	if body in hit_targets:
		return

	if body.has_method("take_damage"):

		hit_targets.append(body)

		body.take_damage(null, dash_damage)


func _on_ability_cooldown_timeout() -> void:
	can_ability = true
