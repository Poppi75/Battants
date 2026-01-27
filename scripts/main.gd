extends Node2D

const PlayerScene := preload("res://scenes/characters/player.tscn")

@onready var spawn_points := [
	$Spawns/Spawn1,
	$Spawns/Spawn2,
	$Spawns/Spawn3,
	$Spawns/Spawn4,
]

@onready var winner = $Camera2D/win_text

var players: Array[Player] = []

var player_number := 1
var player_count := 0
var maps = Global.maps

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

		# 🔗 CONNECT PLAYER DEATH SIGNAL
		player.died.connect(_on_player_died)

		add_child(player)
		players.append(player)

		print("Spawned player_index=", i, " device_id=", device_id)

	# ✅ Correct player count
	player_count = players.size()

	print("Total players:", player_count)


func _on_player_died(player: Player) -> void:
	# Remove from list
	players.erase(player)

	# Decrease count
	player_count -= 1

	print("Player died. Remaining players:", player_count)

	if player_count == 1:
		if winner != null:
			winner.visible = true
			winner.text = str("WINNER: P",players[0].player_number)
		await get_tree().create_timer(5.0).timeout
		var chosen: String = maps[randi() % maps.size()]
		get_tree().change_scene_to_file(chosen)
