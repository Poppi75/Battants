extends Sprite2D

@export var speed: float = 600.0
@export var lifetime: float = 1.5
@export var damage: float = 10.0

@onready var hit_area: Area2D = get_node_or_null("Area2D")

var velocity: Vector2 = Vector2.ZERO
var shooter: Node = null

func init(dir: Vector2, s: float, who: Node = null) -> void:
	velocity = dir.normalized() * s
	speed = s
	shooter = who

func _ready() -> void:
	if hit_area:
		print("[Bullet] Area ready. layer=", hit_area.collision_layer, " mask=", hit_area.collision_mask)
		hit_area.body_entered.connect(_on_body_entered)
	else:
		push_warning("Bullet Area2D not found. No collisions will register.")

func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return
	if body and body.is_in_group("players"):
		print("[Bullet] Hit player:", body.name)
		if body.has_method("apply_damage"):
			body.apply_damage(damage)
	queue_free()

func _physics_process(delta: float) -> void:
	position += velocity * delta
	if velocity.length() > 0.0:
		rotation = velocity.angle()
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
