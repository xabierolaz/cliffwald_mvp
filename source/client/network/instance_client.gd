class_name InstanceClient
extends Node

# --- CONFIGURACIÓN ---
const LOCAL_PLAYER: PackedScene = preload("res://source/common/gameplay/characters/player/net_player.tscn")

static var current: InstanceClient
static var local_player: Node

# Diccionario actualizado para guardar referencias 3D
var players_by_peer_id: Dictionary
var instance_map: Node

# Data Request System (Keep for inventory/stats)
static var _next_data_request_id: int
static var _pending_data_requests: Dictionary
static var _data_subscriptions: Dictionary

static func _static_init() -> void:
	subscribe(&"action.perform", func(data: Dictionary) -> void:
		pass # Combat logic stub
	)

func _ready() -> void:
	current = self
	players_by_peer_id = {}
	_pending_data_requests = {}
	_data_subscriptions = {}
	_next_data_request_id = 1

@rpc("any_peer", "call_remote", "reliable", 0)
func ready_to_enter_instance() -> void:
	print("InstanceClient: Map loaded. Requesting spawn via Spawner...")
	if instance_map:
		var spawner = instance_map.get_node_or_null("SimpleSpawner")
		if spawner:
			spawner.rpc_id(1, "request_spawn_server")
		else:
			printerr("SimpleSpawner not found in map!")

@rpc("authority", "call_remote", "reliable", 0)
func charge_new_instance(map_path: String, instance_name: String) -> void:
	print("InstanceClient: Loading map %s..." % map_path)

	if instance_map:
		instance_map.queue_free()

	var packed_scene = load(map_path)
	if packed_scene:
		instance_map = packed_scene.instantiate()
		instance_map.name = instance_name # Sync name with server for spawner paths
		add_child(instance_map)

		# Once map is loaded, tell server we are ready to receive spawns
		ready_to_enter_instance()
	else:
		printerr("Failed to load map: " + map_path)

# --- Data System ---

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
