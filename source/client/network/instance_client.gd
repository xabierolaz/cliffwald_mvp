class_name InstanceClient
extends Node

# --- CONFIGURACIÓN DE ESCENAS 3D ---
const LOCAL_PLAYER: PackedScene = preload("res://source/client/local_player/player_3d.tscn")

# NOTA: Temporalmente usamos el mismo player_3d para el Dummy (otros jugadores).
const DUMMY_PLAYER: PackedScene = preload("res://source/client/local_player/player_3d.tscn")

static var current: InstanceClient
# Usamos CharacterBody3D para evitar depender de la clase Player3D y romper ciclos
static var local_player: CharacterBody3D

# Diccionario actualizado para guardar referencias 3D
var players_by_peer_id: Dictionary

var synchronizer_manager: StateSynchronizerManagerClient
var instance_map: Node # Nodo genérico para soportar mapas 3D

static var _next_data_request_id: int
static var _pending_data_requests: Dictionary
static var _data_subscriptions: Dictionary


static func _static_init() -> void:
	# CORRECCIÓN: Llamamos a subscribe directamente (sin InstanceClient.)
	subscribe(&"action.perform", func(data: Dictionary) -> void:
		if data.is_empty() or not data.has_all(["p", "d", "i"]):
			return

		# CORRECCIÓN: Accedemos a current directamente (sin InstanceClient.)
		if not current:
			return

		var player := current.players_by_peer_id.get(data["p"]) as CharacterBody3D
		if player == null:
			return
		# TODO: agregar lógica de combate aquí cuando esté lista
	)


func _ready() -> void:
	current = self
	# Inicializar contenedores
	players_by_peer_id = {}
	if _pending_data_requests == null:
		_pending_data_requests = {}
	if _data_subscriptions == null:
		_data_subscriptions = {}
	_next_data_request_id = 1

	synchronizer_manager = StateSynchronizerManagerClient.new()
	synchronizer_manager.name = "StateSynchronizerManager"

	if instance_map and "replicated_props_container" in instance_map and instance_map.replicated_props_container:
		synchronizer_manager.add_container(1_000_000, instance_map.replicated_props_container)

	add_child(synchronizer_manager, true)


@rpc("any_peer", "call_remote", "reliable", 0)
func ready_to_enter_instance() -> void:
	rpc_id(1, "ready_to_enter_instance")


#region spawn/despawn
@rpc("authority", "call_remote", "reliable", 0)
func spawn_player(player_id: int) -> void:
	var new_player: CharacterBody3D
	var is_local: bool = player_id == multiplayer.get_unique_id()

	if is_local:
		if local_player and is_instance_valid(local_player):
			new_player = local_player
		else:
			var instance = LOCAL_PLAYER.instantiate()
			if not instance:
				printerr("ERROR CRÍTICO: No se pudo instanciar LOCAL_PLAYER.")
				return

			new_player = instance as CharacterBody3D
			local_player = new_player

		if new_player and "synchronizer_manager" in new_player:
			new_player.set("synchronizer_manager", synchronizer_manager)
	else:
		new_player = DUMMY_PLAYER.instantiate() as CharacterBody3D

	if not new_player:
		printerr("ERROR: new_player es null para ID: ", player_id)
		return

	new_player.name = str(player_id)
	new_player.set_multiplayer_authority(player_id)

	players_by_peer_id[player_id] = new_player
	print("InstanceClient: spawn %s player_id=%d map=%s" % [
		"local" if is_local else "remote",
		player_id,
		instance_map.name if instance_map else "null"
	])

	if instance_map and not new_player.is_inside_tree():
		instance_map.add_child(new_player)
	elif not instance_map:
		printerr("ERROR: instance_map no está asignado en InstanceClient.")

	if new_player.is_inside_tree() and self.is_ancestor_of(new_player):
		new_player.set_owner(self)

	var sync_node = new_player.get("state_synchronizer")
	if not sync_node:
		sync_node = new_player.get_node_or_null("StateSynchronizer")

	if sync_node:
		synchronizer_manager.add_entity(player_id, sync_node)
	else:
		push_warning("Player " + str(player_id) + " no tiene 'state_synchronizer'.")

	if is_local:
		ClientState.local_player = new_player
		ClientState.local_player_ready.emit(new_player)

		var cam: Camera3D = new_player.get_node_or_null("SpringArm3D/Camera3D") as Camera3D
		if cam and not cam.current:
			cam.make_current()


@rpc("authority", "call_remote", "reliable", 0)
func despawn_player(player_id: int) -> void:
	synchronizer_manager.remove_entity(player_id)

	var player: CharacterBody3D = players_by_peer_id.get(player_id, null)
	if player and player != local_player:
		player.queue_free()
	players_by_peer_id.erase(player_id)
#endregion


## Subscribe to a kind of data from anywhere in the project.
static func subscribe(type: StringName, handler: Callable) -> void:
	if _data_subscriptions.has(type):
		_data_subscriptions[type].append(handler)
	else:
		_data_subscriptions[type] = [handler]


static func unsubscribe(type: StringName, handler: Callable) -> void:
	if not _data_subscriptions.has(type):
		return
	_data_subscriptions[type].erase(handler)


func request_data(type: StringName, handler: Callable, args: Dictionary = {}) -> int:
	var request_id: int = _next_data_request_id
	_next_data_request_id += 1
	_pending_data_requests[request_id] = handler
	data_request.rpc_id(1, request_id, type, args)
	return request_id


func cancel_request_data(request_id: int) -> bool:
	return _pending_data_requests.erase(request_id)


@rpc("any_peer", "call_remote", "reliable", 1)
func data_request(_request_id: int, _type: StringName, _args: Dictionary) -> void:
	pass


@rpc("authority", "call_remote", "reliable", 1)
func data_response(request_id: int, type: StringName, data: Dictionary) -> void:
	var callable: Callable = _pending_data_requests.get(request_id, Callable())
	_pending_data_requests.erase(request_id)
	if callable.is_valid():
		callable.call(data)
	data_push(type, data)


@rpc("authority", "call_remote", "reliable", 1)
func data_push(type: StringName, data: Dictionary) -> void:
	for handler: Callable in _data_subscriptions.get(type, []):
		if handler.is_valid():
			handler.call(data)
		else:
			unsubscribe(type, handler)
