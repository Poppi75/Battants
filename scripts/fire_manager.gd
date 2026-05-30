extends Node

@export var fire_fx_scene: PackedScene = preload("res://scenes/items/fire_cell.tscn")
@export var max_fx_instances: int = 260

# Damage
@export var damage_per_tick: float = 10.0
@export var damage_tick_seconds: float = 1.0
@export var damage_radius: float = 24.0  # Distance from fire cell center to take damage

# Area
@export var radius_cells: int = 4
@export var initial_core_radius: int = 1
@export var initial_core_count: int = 3

# Timing
@export var spread_total_time: float = 1.0
@export var hold_time: float = 8.0
@export var burnout_total_time: float = 1.0

# Fades
@export var fade_in_time: float = 0.25
@export var fade_out_time: float = 0.60

# Natural randomness
@export var ignite_chance_center: float = 1.0
@export var ignite_chance_edge: float = 0.85
@export var ember_chance: float = 0.15
@export var ember_distance: int = 2

# Tilemap
@export var pits_cell_offset: Vector2i = Vector2i.ZERO
@export var start_search_radius: int = 6

# Particles
@export var amount_scale_min: float = 0.12
@export var amount_scale_max: float = 0.75

var floors: TileMapLayer
var walls: TileMapLayer
var pits: TileMapLayer

class FireCell:
	var fx: Node2D
	var particles: GPUParticles2D
	var base_amount: int = 0
	var intensity: float = 0.0
	var fade_mode: int = 0
	var fade_t: float = 0.0
	var source_player: Node = null
	var ignite_time: float = 0.0
	var world_pos: Vector2 = Vector2.ZERO

var active: Dictionary = {}
var fx_pool_free: Array[Node2D] = []
var fire_tick_accum: Dictionary = {}

func _ready() -> void:
	_build_fx_pool()

func _build_fx_pool() -> void:
	fx_pool_free.clear()
	if fire_fx_scene == null:
		push_warning("FireManager: fire_fx_scene is null.")
		return
	for i in range(max_fx_instances):
		var fx := fire_fx_scene.instantiate() as Node2D
		fx.visible = false
		add_child(fx)
		fx_pool_free.append(fx)

func register_layers(_floors: TileMapLayer, _walls: TileMapLayer, _pits: TileMapLayer) -> void:
	floors = _floors
	walls = _walls
	pits = _pits
	_clear_all()

func _clear_all() -> void:
	for c in active.keys():
		_deactivate_cell_immediate(c)
	active.clear()
	fire_tick_accum.clear()

func ignite_at_world(world_pos: Vector2, source_player: Node, override_radius: int = -1) -> void:
	if floors == null or walls == null or pits == null:
		push_warning("FireManager: map layers not registered yet.")
		return

	var r := radius_cells if override_radius <= 0 else override_radius
	var origin: Vector2i = floors.local_to_map(floors.to_local(world_pos))
	var start: Variant = _find_nearest_burnable_cell(origin, start_search_radius)
	if start == null:
		return

	sequence_coroutine(start as Vector2i, r, source_player)

func sequence_coroutine(origin: Vector2i, r: int, source_player: Node) -> void:
	var rings: Array = _compute_rings_blocked(origin, r)
	
	# 1) Ignite initial core
	var core_candidates: Array[Vector2i] = []
	var max_core_ring = min(initial_core_radius, rings.size() - 1)
	for ring in range(0, max_core_ring + 1):
		for c in rings[ring]:
			core_candidates.append(c)

	core_candidates.shuffle()
	var picked = min(initial_core_count, core_candidates.size())
	for i in range(picked):
		_activate_cell_if_needed(core_candidates[i], source_player, true)

	# 2) Spread with natural variation
	var spread_cells: Array[Vector2i] = []
	for ring in range(rings.size()):
		for c in rings[ring]:
			if active.has(c):
				continue
			var t = float(ring) / max(1.0, float(r))
			var chance = lerp(ignite_chance_center, ignite_chance_edge, t)
			if randf() <= chance:
				spread_cells.append(c)

	var steps = max(1, spread_cells.size())
	var step_time := spread_total_time / float(steps)

	for c in spread_cells:
		if _activate_cell_if_needed(c, source_player):
			await get_tree().create_timer(step_time * randf_range(0.6, 1.4)).timeout
		
		# Embers: spontaneous secondary ignition
		if randf() < ember_chance:
			for _i in range(randi_range(1, 2)):
				var ember_target = c + Vector2i(randi_range(-ember_distance, ember_distance), randi_range(-ember_distance, ember_distance))
				if _cell_can_burn_32(ember_target) and not active.has(ember_target):
					_activate_cell_if_needed(ember_target, source_player)

	# 3) Hold
	if hold_time > 0.0:
		await get_tree().create_timer(hold_time).timeout

	# 4) Burnout (newest->oldest)
	var burnout_list: Array[Vector2i] = []
	for c in active.keys():
		burnout_list.append(c)
	
	burnout_list.sort_custom(func(a, b): return active[a].ignite_time > active[b].ignite_time)
	
	var burnout_steps = max(1, burnout_list.size())
	var burnout_step_time := burnout_total_time / float(burnout_steps)

	for c in burnout_list:
		_start_fade_out(c)
		await get_tree().create_timer(burnout_step_time).timeout

# ---

func _physics_process(delta: float) -> void:
	if active.is_empty():
		fire_tick_accum.clear()
		return
	_apply_tick_damage(delta)

func _apply_tick_damage(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return

	var seen_ids: Dictionary = {}
	for body in players:
		if body == null or not is_instance_valid(body):
			continue
		if not body.has_method("take_damage"):
			continue

		var id := body.get_instance_id()
		seen_ids[id] = true

		# Check all nearby fire cells within damage_radius
		var damaged_this_frame := false
		var strongest_source: Node = null
		
		for cell_pos in active.keys():
			var cell: FireCell = active[cell_pos]
			var distance = cell.world_pos.distance_to(body.global_position)
			
			# Only damage if within radius and cell is actively burning (intensity > 0)
			if distance <= damage_radius and cell.intensity > 0.0:
				damaged_this_frame = true
				strongest_source = cell.source_player
				break

		if not damaged_this_frame:
			fire_tick_accum.erase(id)
			continue

		var t: float = fire_tick_accum.get(id, 0.0) + delta
		while t >= damage_tick_seconds:
			t -= damage_tick_seconds
			body.take_damage(strongest_source, damage_per_tick, false)
		fire_tick_accum[id] = t

	for id in fire_tick_accum.keys():
		if not id in seen_ids:
			fire_tick_accum.erase(id)

# ---

func _process(delta: float) -> void:
	if active.is_empty():
		return

	var to_remove: Array[Vector2i] = []
	for c in active.keys():
		var cell: FireCell = active[c]
		var fade_target = fade_in_time if cell.fade_mode == 1 else fade_out_time
		
		if cell.fade_mode != 0:
			cell.fade_t += delta
			var t = clamp(cell.fade_t / max(0.001, fade_target), 0.0, 1.0)
			cell.intensity = t if cell.fade_mode == 1 else (1.0 - t)
			
			if cell.fade_mode == 1 and cell.intensity >= 1.0:
				cell.fade_mode = 0
			elif cell.fade_mode == 2 and cell.intensity <= 0.0:
				to_remove.append(c)

		_apply_intensity(cell)

	for c in to_remove:
		_deactivate_cell_immediate(c)
		active.erase(c)

func _apply_intensity(cell: FireCell) -> void:
	if not cell.particles:
		return
	var scale = lerp(amount_scale_min, amount_scale_max, cell.intensity)
	cell.particles.amount = max(1, int(round(cell.base_amount * scale)))
	cell.particles.speed_scale = lerp(0.6, 1.0, cell.intensity)

# ---

func _activate_cell_if_needed(c32: Vector2i, source_player: Node, skip_fade_in: bool = false) -> bool:
	if active.has(c32):
		var existing: FireCell = active[c32]
		# DON'T restart particles - let existing fire continue
		existing.source_player = source_player
		return false

	if fx_pool_free.is_empty():
		return false

	var fx: Node2D = fx_pool_free.pop_back()
	fx.visible = true

	var cell_local := floors.map_to_local(c32) + Vector2(16, 16)
	var world_position = floors.to_global(cell_local)
	fx.global_position = world_position

	var particles := fx.get_node_or_null("Particles") as GPUParticles2D
	var base_amount := 0

	if particles:
		base_amount = particles.amount
		_restart_particles_obj(particles)

	var cell := FireCell.new()
	cell.fx = fx
	cell.particles = particles
	cell.base_amount = base_amount
	cell.source_player = source_player
	cell.intensity = 1.0 if skip_fade_in else 0.0
	cell.fade_mode = 0 if skip_fade_in else 1
	cell.ignite_time = Time.get_ticks_msec()
	cell.world_pos = world_position

	active[c32] = cell
	_apply_intensity(cell)
	return true

func _restart_particles_obj(p: GPUParticles2D) -> void:
	p.emitting = false
	p.restart()
	p.emitting = true

func _start_fade_out(c32: Vector2i) -> void:
	if active.has(c32):
		var cell: FireCell = active[c32]
		if cell.fade_mode != 2:
			cell.fade_mode = 2
			cell.fade_t = 0.0

func _deactivate_cell_immediate(c32: Vector2i) -> void:
	if not active.has(c32):
		return
	var cell: FireCell = active[c32]
	if cell.particles:
		cell.particles.emitting = false
		cell.fx.visible = false
	fx_pool_free.append(cell.fx)

# ---

func _compute_rings_blocked(origin: Vector2i, r: int) -> Array:
	var rings: Array = []
	rings.resize(r + 1)
	for i in range(r + 1):
		rings[i] = []

	if not _cell_can_burn_32(origin):
		return rings

	var q: Array[Vector2i] = [origin]
	var dist: Dictionary = { origin: 0 }

	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		var d: int = dist[c]
		if d < 0 or d > r:
			continue

		rings[d].append(c)

		if d >= r:
			continue

		for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n = c + step
			if not dist.has(n) and _cell_can_burn_32(n):
				dist[n] = d + 1
				q.push_back(n)

	return rings

func _find_nearest_burnable_cell(origin: Vector2i, max_steps: int) -> Variant:
	if _cell_can_burn_32(origin):
		return origin
	for rr in range(1, max_steps + 1):
		for y in range(-rr, rr + 1):
			for x in range(-rr, rr + 1):
				var c := origin + Vector2i(x, y)
				if _cell_can_burn_32(c):
					return c
	return null

func _cell_can_burn_32(c32: Vector2i) -> bool:
	return (floors.get_cell_source_id(c32) != -1 and 
			walls.get_cell_source_id(c32) == -1 and 
			not _has_pit_in_32_cell(c32))

func _has_pit_in_32_cell(c32: Vector2i) -> bool:
	var pit_base: Vector2i = c32 * 2 + pits_cell_offset
	for oy in range(2):
		for ox in range(2):
			if pits.get_cell_source_id(pit_base + Vector2i(ox, oy)) != -1:
				return true
	return false
