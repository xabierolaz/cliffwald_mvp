class_name WorldManagerClient
extends BaseMultiplayerEndpoint


signal token_received(auth_token: String, username: String, character_id: int)

@export var database: WorldDatabase
@export var world_server: WorldServer

var world_info: Dictionary


func start_client_to_master_server(_world_info: Dictionary) -> void:

	world_info = _world_info
	var configuration: Dictionary = ConfigFileUtils.load_section(
		"world-manager-client",
		CmdlineUtils.get_parsed_args().get("config", "res://data/config/world_config.cfg")
	)

	var tls_options: TLSOptions = null
	if configuration.has("certificate_path") and not configuration.certificate_path.is_empty():
		var cert = load(configuration.certificate_path)
		if cert:
			tls_options = TLSOptions.client(cert)

	create(Role.CLIENT, configuration.address, configuration.port, tls_options)


func _connect_multiplayer_api_signals(api: SceneMultiplayer) -> void:
	api.connected_to_server.connect(_on_connection_succeeded)
	api.connection_failed.connect(_on_connection_failed)
	api.server_disconnected.connect(_on_server_disconnected)


func _on_connection_succeeded() -> void:
	print("Successfully connected to the Gateway as %d!" % multiplayer.get_unique_id())
	var port_val: int = int(world_info.get("port", 0))
	if port_val <= 0:
		port_val = 8087
	var addr_val: String = str(world_info.get("bind_address", "127.0.0.1"))
	var info_payload: Dictionary = {
		"name": world_info.get("name", "NoName"),
		"max_players": world_info.get("max_players", 200),
		"hardcore": world_info.get("hardcore", false),
		"motd": world_info.get("motd", "Welcome!"),
		"bonus_xp": world_info.get("bonus_xp", 0.0),
		"max_character": world_info.get("max_character", 5),
		"pvp": world_info.get("pvp", true)
	}
	fetch_server_info.rpc_id(
		1,
		{
			"port": port_val,
			"address": addr_val,
			"info": info_payload,
			"population": world_server.connected_players.size()
		}
	)


func _on_connection_failed() -> void:
	print("Failed to connect to the MasterServer as WorldServer.")


func _on_server_disconnected() -> void:
	print("Game Server disconnected.")


@rpc("any_peer")
func fetch_server_info(_info: Dictionary) -> void:
	pass


@rpc("authority")
func fetch_token(auth_token: String, username: String, character_id: int) -> void:
	token_received.emit(auth_token, username, character_id)


@rpc("any_peer")
func player_disconnected(_username: String) -> void:
	pass


@rpc("authority")
func create_player_character_request(gateway_id: int, peer_id: int, username: String, character_data: Dictionary) -> void:
	player_character_creation_result.rpc_id(
		1,
		gateway_id,
		peer_id,
		username,
		database.player_data.create_player_character(username, character_data)
	)


@rpc("any_peer")
func player_character_creation_result(_gateway_id: int, _peer_id: int, _username: String, _result_code: int) -> void:
	pass


@rpc("authority")
func request_player_characters(gateway_id: int, peer_id: int, username: String) -> void:
	receive_player_characters.rpc_id(
		1,
		database.player_data.get_account_characters(username),
		gateway_id,
		peer_id
	)


@rpc("any_peer")
func receive_player_characters(_gateway_id: int, _peer_id: int, _player_characters: Dictionary) -> void:
	pass


@rpc("authority")
func request_login(
	gateway_id: int,
	peer_id: int,
	username: String,
	character_id: int
) -> void:
	if (
		database.player_data.players.has(character_id)
		and database.player_data.players[character_id].account_name == username
	):
		result_login.rpc_id(
			1,
			OK,
			gateway_id,
			peer_id,
			username,
			character_id,
		)


@rpc("any_peer")
func result_login(
	_result_code: int,
	_gateway_id: int,
	_peer_id: int,
	_username: String,
	_character_id: int
) -> void:
	pass
