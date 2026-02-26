extends Area2D

@onready var pickup_sound: AudioStreamPlayer2D = $pickup_sound
@onready var sprite_2d_2: Sprite2D = $Sprite2D2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var claimed: bool = false
var players_in_range: Array[Player] = []

func _process(_delta: float) -> void:
	if claimed:
		return

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

	# Hide hint for everyone still in range (since the coin is gone)
	for pl in players_in_range:
		if is_instance_valid(pl):
			pl._pickup_area_exited()
	players_in_range.clear()

	p.pickup()

	sprite_2d_2.visible = false
	collision_shape_2d.set_deferred("disabled", true)

	pickup_sound.play()
	await pickup_sound.finished
	queue_free()
