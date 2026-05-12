extends Node

var player_bindings: Array = []
var joined_devices: Array = []

var maps: Array[String] = [
	"res://scenes/maps/map2.tscn",
]

var playerwins = [
	0,
	0,
	0,
	0
]

# -------------------------
# 🟢 Loading system logic
# -------------------------

var next_scene: String = ""

func pick_random_map() -> String:
	if maps.is_empty():
		push_error("No maps available!")
		return ""
	
	next_scene = maps.pick_random()
	return next_scene

func set_next_map(path: String) -> void:
	next_scene = path

func get_next_scene() -> String:
	return next_scene
