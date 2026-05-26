extends Area2D

@onready var pickup_sound: AudioStreamPlayer2D = $pickup_sound
@onready var sprite_2d_2: Sprite2D = $Sprite2D2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var utility_items: Array[PackedScene]

var claimed: bool = false
var players_in_range: Array[Player] = []

var random: int



func _ready() -> void:
	random = [-1, 1].pick_random()


func _process(_delta: float) -> void:
	if claimed:
		return

	rotation += 0.02 * random

	for p in players_in_range:
		if not is_instance_valid(p):
			continue
		if p.is_pickup_pressed():
			_claim(p)
			return

func _on_body_entered(body: Node2D) -> void:
	if claimed:
		return
	if body is Player and body.is_in_group("players"):
		if not players_in_range.has(body):
			players_in_range.append(body)
			body._pickup_area_entered()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		players_in_range.erase(body)
		body._pickup_area_exited()

func _claim(p: Player) -> void:
	if claimed:
		return
	claimed = true

	# Already disables hints for everyone, as before
	for pl in players_in_range:
		if is_instance_valid(pl):
			pl._pickup_area_exited()
	players_in_range.clear()

	# PICKUP: MOVE RANDOM PICK AND PASS IT TO THE PLAYER
	var chosen = _pick_random_item_from_pool()
	p.pickup(chosen)

	sprite_2d_2.visible = false
	collision_shape_2d.set_deferred("disabled", true)

	pickup_sound.play()
	await pickup_sound.finished
	queue_free()

# Move this method from player to here:
func _pick_random_item_from_pool() -> Dictionary:
	var pool: Array[Dictionary] = []

	for item in utility_items:
		pool.append({ "type": "utility", "scene": item })

	return pool.pick_random() if not pool.is_empty() else {}
