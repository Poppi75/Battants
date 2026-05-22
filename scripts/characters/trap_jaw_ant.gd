extends Player

var can_extra_dmg: bool = false
var _visible: bool = true

@export var stun_duration: float = 0.0

@onready var extra_dmg_timer: Timer = $ExtraDmgTimer
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ability: Area2D = $ability
@onready var cooldown: Timer = $AbilityCooldown
@export var SPIKE: PackedScene

@onready var bars := [
	$UI/health,
	$UI/extra_health,
	$UI/damagetaken
]

var cloak_progress := 0.0
var cloak_tween: Tween
var bars_tween: Tween

var nearby_players = []

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
	if _visible == true:
		animate_cloak(cloak_progress < 0.5, 0.6)
		_visible = false

func _attack() -> void:
	super._attack()
	if equipped_slot == "class_ability" and !stunned and can_ability:
		can_ability = false
		if _visible == true:
			animate_cloak(cloak_progress < 0.5, 0.6)
			_visible = false
		active_ability_use = true
		ability.monitoring = true
		await get_tree().create_timer(3.0).timeout
		teleport_to_closest()
		active_ability_use = false
		ability.monitoring = false
		cooldown.start()

func teleport_to_closest():
	# Remove invalid players first
	nearby_players = nearby_players.filter(func(p):
		return is_instance_valid(p)
	)

	if nearby_players.is_empty():
		print("No nearby players")
		return

	var closest = null
	var closest_distance = INF

	# Find closest valid player
	for player in nearby_players:
		var dist = global_position.distance_squared_to(player.global_position)

		if dist < closest_distance:
			closest = player
			closest_distance = dist

	if closest == null:
		print("No valid target")
		return

	# Try teleport spots around target
	var radius = 32.0
	var attempts = 12

	for i in range(attempts):
		var angle = (TAU / attempts) * i
		var offset = Vector2.RIGHT.rotated(angle) * radius
		var test_position = closest.global_position + offset

		if is_position_free(test_position, closest):
			print("Teleporting to: ", test_position)

		global_position = test_position
		closest.ability_stun(stun_duration)

		await fire_spikes(closest)

		return

	print("No free teleport position found")

func fire_spikes(target: Node2D) -> void:

	for i in range(3):

		if !is_instance_valid(target):
			return

		var spike = SPIKE.instantiate()

		spike.owner_player = self
		spike.target = target

		# Attach to player
		add_child(spike)

		# Position relative to player
		spike.position = Vector2(
	randf_range(-18, 18),
	randf_range(-18, 18)
)

		# Wait while attached
		await get_tree().create_timer(0.5).timeout

		# Fire
		if is_instance_valid(spike):
			spike.launch()

		await get_tree().create_timer(0.5).timeout

func is_position_free(pos: Vector2, target: Node2D) -> bool:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsShapeQueryParameters2D.new()

	query.shape = col_shape.shape
	query.transform = Transform2D(0, pos)

	query.collide_with_bodies = true
	query.collide_with_areas = false

	# Ignore self and target
	query.exclude = [
		self,
		target
	]

	var result = space_state.intersect_shape(query)

	return result.is_empty()

func _on_ability_body_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body != self:
		if !nearby_players.has(body):
			nearby_players.append(body)


func _on_ability_cooldown_timeout() -> void:
	can_ability = true


func _on_ability_body_exited(body: Node2D) -> void:
	if nearby_players.has(body):
		nearby_players.erase(body)
