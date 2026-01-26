extends Node

const GAME_PORT := 7777
const MAX_PLAYERS := 4

const DISCOVERY_PORT := 50000
const DISCOVERY_MESSAGE := "DISCOVER_HOST"
const DISCOVERY_RESPONSE_PREFIX := "HOST_INFO:" 
# HOST_INFO:<game_port>:<server_name>

var is_host: bool = false
var server_name: String = "Unnamed Server"

var _discovery_server: UDPServer
var _discovery_running: bool = false

var _discovery_client: PacketPeerUDP
# Each entry: { ip: String, port: int, name: String }
var discovered_hosts: Array = []

# Removed: signal game_start (it wasn't used)


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# =========================
# HOST / JOIN GAME
# =========================

func host_game(server_name_str: String, port: int = GAME_PORT) -> void:
	# rename parameter to avoid shadowing Node.name
	server_name = server_name_str
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		push_error("Failed to host server: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	is_host = true
	print("Hosting game '%s' on port %d" % [server_name, port])

	_start_discovery_server()


func join_game(ip: String, port: int = GAME_PORT) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		push_error("Failed to connect: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	is_host = false
	print("Joining game at", ip, ":", port)


func leave_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_host = false

	_stop_discovery_server()
	_stop_discovery_client()


# =========================
# DISCOVERY - HOST SIDE
# =========================

func _start_discovery_server() -> void:
	if _discovery_running:
		return

	_discovery_server = UDPServer.new()
	var err := _discovery_server.listen(DISCOVERY_PORT)
	if err != OK:
		push_error("Failed to start discovery server: %s" % err)
		return

	_discovery_running = true
	set_process(true)
	print("Discovery server started on UDP port", DISCOVERY_PORT)


func _stop_discovery_server() -> void:
	if _discovery_server:
		_discovery_server.close()
	_discovery_server = null
	_discovery_running = false


# =========================
# DISCOVERY - CLIENT SIDE
# =========================

func start_discovery() -> void:
	discovered_hosts.clear()
	_stop_discovery_client()

	_discovery_client = PacketPeerUDP.new()
	_discovery_client.set_broadcast_enabled(true)

	var err := _discovery_client.connect_to_host("255.255.255.255", DISCOVERY_PORT)
	if err != OK:
		push_error("Failed to setup discovery client: %s" % err)
		return

	print("Sending discovery broadcast...")
	_discovery_client.put_packet(DISCOVERY_MESSAGE.to_utf8_buffer())
	set_process(true)


func _stop_discovery_client() -> void:
	if _discovery_client:
		_discovery_client.close()
	_discovery_client = null


func finish_discovery() -> void:
	_stop_discovery_client()
	emit_signal("discovery_finished")


# =========================
# PROCESS: handle UDP
# =========================

func _process(_delta: float) -> void:
	# prefix with _ to mark unused and silence the warning

	# Host: incoming discovery requests
	if _discovery_running and _discovery_server:
		if _discovery_server.is_connection_available():
			var peer := _discovery_server.take_connection()
			if peer:
				var pkt := peer.get_packet()
				var msg := pkt.get_string_from_utf8()
				if msg == DISCOVERY_MESSAGE:
					var resp := "%s%d:%s" % [DISCOVERY_RESPONSE_PREFIX, GAME_PORT, server_name]
					peer.put_packet(resp.to_utf8_buffer())

	# Client: read discovery responses
	if _discovery_client:
		while _discovery_client.get_available_packet_count() > 0:
			var pkt := _discovery_client.get_packet()
			var msg := pkt.get_string_from_utf8()
			if msg.begins_with(DISCOVERY_RESPONSE_PREFIX):
				var payload := msg.substr(DISCOVERY_RESPONSE_PREFIX.length())
				var parts := payload.split(":", false, 2)
				if parts.size() >= 2:
					var port := int(parts[0])
					var name := parts[1]
					var host_ip := _discovery_client.get_packet_ip()

					var entry := { "ip": host_ip, "port": port, "name": name }
					var already := false
					for h in discovered_hosts:
						if h.ip == host_ip and h.port == port:
							already = true
							break

					if not already:
						discovered_hosts.append(entry)
						emit_signal("host_discovered", host_ip, port, name)
						print("Discovered host '%s' at %s:%d" % [name, host_ip, port])


# =========================
# MULTIPLAYER SIGNALS
# =========================

func _on_peer_connected(id: int) -> void:
	print("Peer connected:", id)


func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected:", id)


func _on_connection_failed() -> void:
	print("Connection failed")
	leave_game()


func _on_server_disconnected() -> void:
	print("Disconnected from server")
	leave_game()
