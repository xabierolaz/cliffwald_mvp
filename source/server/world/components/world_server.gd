class_name WorldServer
extends BaseMultiplayerEndpoint
## Server autoload. Keep it clean and minimal.
## Should only care about connection and authentication stuff.

@export var database: WorldDatabase
@export var world_manager: WorldManagerClient

# Notifica cuando un peer completó auth y tiene PlayerResource asignado
signal player_authenticated(peer_id: int)

var token_list: Dictionary = {}
var connected_players: Dictionary = {}

func start_world_server() -> void:
	print("WorldServer.start_world_server")
	var configuration: Dictionary = ConfigFileUtils.load_section(
		"world-server",
		CmdlineUtils.get_parsed_args().get("config", "res://data/config/world_config.cfg")
	)

	if world_manager:
		world_manager.token_received.connect(
			func(auth_token: String, _username: String, character_id: int) -> void:
				var player: PlayerResource = database.player_data.get_player_resource(character_id)
				token_list[auth_token] = player
		)
	if not configuration.has("error"):
		var tls_options: TLSOptions = null
		if configuration.has("certificate_path") and configuration.has("key_path"):
			var cert = load(configuration.certificate_path)
			var key = load(configuration.key_path)
			if cert and key:
				tls_options = TLSOptions.server(key, cert)

		var err := create(Role.SERVER, configuration.bind_address, configuration.port, tls_options)
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
	# IMPORTANT: Remove from connected_players to avoid stale lookups in instance_server
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
		connected_players[peer_id] = token_list[auth_token]
		token_list.erase(auth_token)
		player_authenticated.emit(peer_id)
	else:
		peer.disconnect_peer(peer_id)


func is_valid_authentication_token(auth_token: String) -> bool:
	if token_list.has(auth_token):
		return true
	return false
