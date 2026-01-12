extends Sprite2D

@onready var pickup_area: Area2D = $Area2D

@export var bullet_scene: PackedScene = preload("res://scenes/weapons/testikapula_bullet.tscn")
@export var bullet_speed: float = 600.0
@export var fire_cooldown: float = 0.25

var holder: CharacterBody2D = null
var can_fire := true

func _ready():
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_body_entered)

func _on_pickup_body_entered(body: CharacterBody2D) -> void:
	if holder != null:
		return
	if body is CharacterBody2D and body.is_in_group("players"):
		print("[Weapon] Player entered pickup:", body.name)
		if body.has_method("equip_weapon"):
			body.equip_weapon(self)
		else:
			equip(body)

func equip(new_holder: CharacterBody2D) -> void:
	holder = new_holder
	# Attach to the player so it follows them
	if get_parent() != holder:
		reparent(holder)
	position = Vector2.ZERO
	rotation = 0.0
	visible = true
	if pickup_area:
		pickup_area.monitoring = false
		pickup_area.visible = false

func unequip() -> void:
	holder = null
	visible = true
	if pickup_area:
		pickup_area.monitoring = true

func fire(shooter: CharacterBody2D) -> void:
	if not can_fire:
		return
	if bullet_scene == null:
		return

	can_fire = false
	var dir: Vector2 = Vector2.UP.rotated(shooter.rotation).normalized()

	var bullet = bullet_scene.instantiate()
	# Dynamically attach a simple movement script to the bullet
	var bullet_script = load("res://scripts/weapons/testikapula_bullet.gd")
	bullet.set_script(bullet_script)

	# Spawn slightly in front of the shooter
	var spawn_offset := 14.0
	if bullet is Sprite2D:
		bullet.global_position = shooter.global_position + dir * spawn_offset
		bullet.rotation = dir.angle()

	# Provide velocity to the bullet script
	if bullet.has_method("init"):
		bullet.init(dir, bullet_speed, shooter)

	# Add bullet to the same parent as the shooter (world)
	var world_parent: Node = shooter.get_parent()
	world_parent.add_child(bullet)

	# Cooldown timer
	var t := get_tree().create_timer(fire_cooldown)
	t.timeout.connect(func(): can_fire = true)
