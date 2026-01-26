extends Node

# Used by both local and LAN modes to tell Game.tscn how many players to spawn
# Local: [ { "device": int }, ... ]
# LAN:   [ { "peer_id": int }, ... ]
var player_bindings: Array = []

# For this minimal LAN test, we only have one map
var maps: Array[String] = [
	"res://scenes/maps/dev_test_map_test.tscn",
	"res://scenes/maps/map1.tscn",
	"res://scenes/maps/map2.tscn",
]
