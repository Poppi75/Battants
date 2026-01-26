extends Control

@onready var host_btn: Button = $MarginContainer/VBoxContainer/HBoxContainer2/HostButton
@onready var find_btn: Button = $MarginContainer/VBoxContainer/HBoxContainer2/FindButton
@onready var games_list: ItemList = $MarginContainer/VBoxContainer/GamesList
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var start_btn: Button = $MarginContainer/VBoxContainer/ButtonsBottom/StartButton
@onready var back_btn: Button = $MarginContainer/VBoxContainer/ButtonsBottom/BackButton
@onready var server_name_edit: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/ServerNameEdit

var maps = Global.maps

func _ready() -> void:
	status_label.text = ""
	start_btn.visible = false
	games_list.clear()

	host_btn.pressed.connect(_on_HostButton_pressed)
	find_btn.pressed.connect(_on_FindButton_pressed)
	games_list.item_activated.connect(_on_GamesList_item_activated)
	start_btn.pressed.connect(_on_StartButton_pressed)
	back_btn.pressed.connect(_on_BackButton_pressed)

	Network.host_discovered.connect(_on_host_discovered)
	Network.discovery_finished.connect(_on_discovery_finished)


func _on_HostButton_pressed() -> void:
	var server_name := server_name_edit.text.strip_edges()
	if server_name == "":
		server_name = "My Server"

	Network.host_game(server_name)
	status_label.text = "Hosting '%s'..." % server_name
	start_btn.visible = true


func _on_FindButton_pressed() -> void:
	games_list.clear()
	status_label.text = "Searching for LAN games..."
	Network.start_discovery()


func _on_host_discovered(ip: String, port: int, server_name_str: String) -> void:
	var idx := games_list.get_item_count()
	# Display only server name
	games_list.add_item(server_name_str)
	# Store IP/port/name in metadata, hidden from user
	games_list.set_item_metadata(idx, {
		"ip": ip,
		"port": port,
		"name": server_name_str
	})
	status_label.text = "Found %d game(s)" % games_list.get_item_count()


func _on_discovery_finished() -> void:
	if games_list.get_item_count() == 0:
		status_label.text = "No games found."
	else:
		status_label.text += " (done)"


func _on_GamesList_item_activated(index: int) -> void:
	var meta = games_list.get_item_metadata(index)
	var ip: String = meta["ip"]
	var port: int = meta["port"]
	var server_name_str: String = meta["name"]

	Network.join_game(ip, port)
	status_label.text = "Joining '%s'..." % server_name_str
	start_btn.visible = false


func _on_StartButton_pressed() -> void:
	if not Network.is_host:
		return

	# One player per peer_id
	var bindings: Array = []
	bindings.append({ "peer_id": 1 })  # host

	for pid in multiplayer.get_peers():
		bindings.append({ "peer_id": pid })

	Global.player_bindings = bindings

	var chosen: String = maps[randi() % maps.size()]
	_rpc_start_match(chosen, bindings)


@rpc("authority", "reliable")
func _rpc_start_match(map_path: String, bindings: Array) -> void:
	Global.player_bindings = bindings
	get_tree().change_scene_to_file(map_path)


func _on_BackButton_pressed() -> void:
	Network.leave_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
