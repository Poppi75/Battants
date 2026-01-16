extends Node2D

const PlayerScene := preload("res://scenes/characters/player.tscn")

@onready var spawn_points := [
	$Spawns/Spawn1,
	$Spawns/Spawn2,
	$Spawns/Spawn3,
	$Spawns/Spawn4,
]

var players: Array[Player] = []

var player_number = 1

func _ready() -> void:
	var bindings: Array = Global.player_bindings

	for i in range(bindings.size()):
		var data: Dictionary = bindings[i]
		var device_id: int = data["device"]

		var player: Player = PlayerScene.instantiate()
		player.device_id = device_id
		player.player_index = i
		player.player_number = player_number
		player_number += 1

		if i < spawn_points.size():
			player.position = spawn_points[i].position

		add_child(player)
		players.append(player)

		print("Spawned player_index=", i, "device_id=", device_id)

# IMPORTANT:
# No per-player input feeding here anymore.
# Each Player reads input for itself.
