class_name WorldServer
extends BaseMultiplayerEndpoint
## Server autoload. Keep it clean and minimal.
## Should only care about connection and authentication stuff.

@export var database: WorldDatabase
@export var world_manager: WorldManagerClient

var token_list: Dictionary = {}
var connected_players: Dictionary = {}

var dev_insecure_auth: bool = false
var fallback_motd: String = "Welcome!"

func start_world_server() -> void:
	print("WorldServer.start_world_server")
	var configuration: Dictionary = ConfigFileUtils.load_section(
		"world-server",
		CmdlineUtils.get_parsed_args().get("config", "res://data/config/world_config.cfg")
	)

	if not configuration.has("error"):
		dev_insecure_auth = configuration.get("dev_insecure_auth", false)
		fallback_motd = configuration.get("motd", fallback_motd)

	if world_manager:
		world_manager.token_received.connect(
			func(auth_token: String, _username: String, character_id: int) -> void:
				var player: PlayerResource = database.player_data.get_player_resource(character_id)
				token_list[auth_token] = player
		)
	else:
		print("⚠️ WorldServer: master client no asignado. Modo dev=%s" % dev_insecure_auth)

	if not configuration.has("error"):
		var err := create(Role.SERVER, configuration.bind_address, configuration.port)
		if err != OK:
			printerr("WorldServer: no se pudo crear el peer en %s:%d (err=%s)" % [configuration.bind_address, configuration.port, error_string(err)])
		else:
			print("WorldServer escuchando en %s:%d" % [configuration.bind_address, configuration.port])

	$InstanceManager.start_instance_manager()


func _connect_multiplayer_api_signals(api: SceneMultiplayer) -> void:
	api.peer_connected.connect(_on_peer_connected)
	api.peer_disconnected.connect(_on_peer_disconnected)
	api.peer_authenticating.connect(_on_peer_authenticating)
	api.peer_authentication_failed.connect(_on_peer_authentication_failed)
	api.set_auth_callback(_authentication_callback)


func _on_peer_connected(peer_id: int) -> void:
	print("Peer: %d is connected." % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer: %d is disconnected." % peer_id)
	if world_manager and connected_players.has(peer_id):
		world_manager.player_disconnected.rpc_id(
			1,
			connected_players[peer_id].account_name
		)
	connected_players.erase(peer_id)


func _on_peer_authenticating(peer_id: int) -> void:
	print("Peer: %d is trying to authenticate." % peer_id)
	multiplayer.send_auth(peer_id, "data_from_server".to_ascii_buffer())


func _on_peer_authentication_failed(peer_id: int) -> void:
	print("Peer: %d failed to authenticate." % peer_id)


func _authentication_callback(peer_id: int, data: PackedByteArray) -> void:
	var auth_token := bytes_to_var(data) as String
	print('Peer: %d is trying to connect with data: "%s".' % [peer_id, auth_token])
	if is_valid_authentication_token(auth_token):
		multiplayer.complete_auth(peer_id)
		if token_list.has(auth_token):
			connected_players[peer_id] = token_list[auth_token]
			token_list.erase(auth_token)
		elif dev_insecure_auth:
			connected_players[peer_id] = _dev_pick_player(auth_token)
	else:
		peer.disconnect_peer(peer_id)


func is_valid_authentication_token(auth_token: String) -> bool:
	if token_list.has(auth_token):
		return true
	if dev_insecure_auth:
		return true
	return false


func _dev_pick_player(auth_token: String) -> PlayerResource:
	# Selecciona el primer personaje existente o genera uno básico para pruebas.
	for p in database.player_data.players.values():
		return p
	var player_resource := PlayerResource.new()
	var next_id: int = max(1, database.player_data.next_player_id + 1)
	player_resource.init(next_id, auth_token, auth_token, 1)
	player_resource.available_attributes_points = 0
	player_resource.level = 1
	database.player_data.players[next_id] = player_resource
	database.player_data.next_player_id = next_id
	return player_resource


func get_motd() -> String:
	if world_manager and world_manager.world_info:
		return world_manager.world_info.get("motd", fallback_motd)
	return fallback_motd
