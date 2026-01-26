extends Node2D

const PlayerScene := preload("res://scenes/characters/player.tscn")

@onready var spawn_points := [
	$Spawns/Spawn1,
	$Spawns/Spawn2,
	$Spawns/Spawn3,
	$Spawns/Spawn4,
]

var players: Array[Player] = []
var player_number := 1
var player_count := 0

func _ready() -> void:
	var bindings: Array = Global.player_bindings

	for i in range(bindings.size()):
		var data: Dictionary = bindings[i]
		var player: Player = PlayerScene.instantiate()

		player.player_index = i
		player.player_number = player_number
		player_number += 1

		if "peer_id" in data:
			# LAN mode
			var pid: int = data["peer_id"]
			player.is_networked = true
			player.peer_id = pid
			player.set_multiplayer_authority(pid)
			# For now, each peer uses keyboard
			player.device_id = -1
		else:
			# Fallback for local-only usage
			player.is_networked = false
			player.device_id = data.get("device", -1)

		if i < spawn_points.size():
			player.position = spawn_points[i].position

		player.died.connect(_on_player_died)
		add_child(player)
		players.append(player)

	player_count = players.size()
	print("Total players:", player_count)


func _on_player_died(player: Player) -> void:
	players.erase(player)
	player_count -= 1
	print("Player died. Remaining:", player_count)

	if player_count == 1:
		await get_tree().create_timer(3.0).timeout
		get_tree().reload_current_scene()
