class_name InstanceManagerServer
extends SubViewportContainer


const INSTANCE_COLLECTION_PATH: String = "res://source/common/gameplay/maps/instance/instance_collection/"
const GLOBAL_COMMANDS_PATH: String = "res://source/server/world/components/chat_command/global_commands/"

var loading_instances: Dictionary
var instance_collection: Array[InstanceResource]
var _default_instance: InstanceResource
var _pending_default_spawns: Array[int] = []
var _pending_attempts: Dictionary = {}
var _spawn_retry_timer: Timer

@export var world_server: WorldServer


func start_instance_manager() -> void:
	if world_server:
		ServerInstance.world_server = world_server
	else:
		printerr("InstanceManager: world_server is null!")

	setup_global_commands_and_roles()

	set_instance_collection.call_deferred()

	# Timer which will call unload_unused_instances
	var timer: Timer = Timer.new()
	timer.wait_time = 20.0 # 20.0 is for testing, consider increasing it

	timer.autostart = true
	timer.timeout.connect(unload_unused_instances)
	add_sibling(timer)

	# Timer to retry pending spawns without usar await
	_spawn_retry_timer = Timer.new()
	_spawn_retry_timer.wait_time = 0.2
	_spawn_retry_timer.one_shot = true
	_spawn_retry_timer.autostart = false
	_spawn_retry_timer.timeout.connect(_on_spawn_retry_timeout)
	add_child(_spawn_retry_timer)

func setup_global_commands_and_roles() -> void:
	var files: PackedStringArray = FileUtils.get_all_file_at(GLOBAL_COMMANDS_PATH, "*.gd")
	if files.is_empty():
		return

	var commands := ServerInstance.global_chat_commands
	for file_path: String in files:
		var command = load(file_path).new()
		commands.set(command.command_name, command)

	var roles := ServerInstance.global_role_definitions
	for role: String in roles:
		var role_data: Dictionary = roles[role]
		var role_commands: Array

		for command_name: String in commands:
			var command = commands[command_name]
			if command.command_priority <= role_data.get("priority", 0):
				role_commands.append(command_name)

		role_data['commands'] = role_commands


@rpc("authority", "call_remote", "reliable", 0)
func charge_new_instance(_map_path: String, _instance_id: String) -> void:
	pass

@rpc("any_peer", "call_remote", "reliable", 0)
func ready_to_enter_instance() -> void:
	var peer_id: int = multiplayer.get_remote_sender_id()
	print("InstanceManager: Player %d ready to enter. Spawning in Default Instance..." % peer_id)

	if _default_instance and not _default_instance.charged_instances.is_empty():
		var instance = _default_instance.charged_instances[0]
		if instance and instance.instance_map:
			var spawner = instance.instance_map.get_node_or_null("SimpleSpawner")
			if spawner and spawner.has_method("spawn_player"):
				var player_resource = ServerInstance.world_server.connected_players.get(peer_id)
				spawner.spawn_player(peer_id, player_resource)
				instance.connected_peers.append(peer_id)


func _on_player_entered_warper(player: Node, current_instance, warper) -> void:
	var instance_index: int = -1 # Will be useful later
	var target_instance
	var instance_resource = warper.target_instance
	if not instance_resource:
		return

	if instance_resource.can_join_instance(player, instance_index):
		target_instance = instance_resource.get_instance()
		if target_instance:
			player_switch_instance(target_instance, warper.target_id, player, current_instance)
		else:
			queue_charge_instance(
				instance_resource,
				player_switch_instance.bind(warper.target_id, player, current_instance)
			)
	else:
		return


func queue_charge_instance(instance_resource: InstanceResource, callback: Callable) -> void:
	if loading_instances.has(instance_resource):
		loading_instances[instance_resource].ready.connect(
			callback.bind(loading_instances[instance_resource])
		)
		return
	var new_instance: ServerInstance = prepare_instance(instance_resource)
	new_instance.ready.connect(callback.bind(new_instance), CONNECT_ONE_SHOT)
	add_child(new_instance, true)


func player_switch_instance(
	target_instance: ServerInstance,
	warper_target_id: int,
	player: Node,
	current_instance: ServerInstance,
) -> void:
	var peer_id: int = player.name.to_int()
	if current_instance.connected_peers.has(peer_id):
		current_instance.despawn_player(peer_id, false)
	else:
		return
	charge_new_instance.rpc_id(
		peer_id,
		target_instance.instance_resource.map_path,
		target_instance.name
	)
	target_instance.awaiting_peers[peer_id] = {
		"player": player,
		"target_id": warper_target_id
	}


func charge_instance(instance_resource: InstanceResource) -> void:
	if loading_instances.has(instance_resource):
		return
	var new_instance: ServerInstance = prepare_instance(instance_resource)
	add_child.call_deferred(new_instance, true)


func prepare_instance(instance_resource: InstanceResource) -> ServerInstance:
	# Force re-compile
	var instance: ServerInstance = ServerInstance.new()
	loading_instances[instance_resource] = instance
	instance.name = str(instance.get_instance_id())
	instance.instance_resource = instance_resource
	instance.player_entered_warper.connect(_on_player_entered_warper)
	instance.ready.connect(
		func():
			loading_instances.erase(instance_resource)
			instance_resource.charged_instances.append(instance),
		CONNECT_ONE_SHOT
	)
	instance.load_map(instance_resource.map_path)
	return instance


func set_instance_collection() -> void:
	_default_instance = null

	for file_path: String in FileUtils.get_all_file_at(INSTANCE_COLLECTION_PATH, "*.tres"):
		print(file_path)
		instance_collection.append(ResourceLoader.load(file_path, "InstanceResource"))

	for instance_resource: InstanceResource in instance_collection:
		if instance_resource.load_at_startup:
			charge_instance(instance_resource)
		if instance_resource.instance_name == "Overworld":
			_default_instance = instance_resource

	# Asegurar que la instancia por defecto esté cargada
	if _default_instance and _default_instance.charged_instances.is_empty() and not loading_instances.has(_default_instance):
		charge_instance(_default_instance)

	# Spawn tras auth, con reintentos controlados
	world_server.player_authenticated.connect(
		func(peer_id: int):
			_schedule_default_spawn(peer_id)
	)

func _schedule_default_spawn(peer_id: int) -> void:
	if _pending_default_spawns.has(peer_id):
		return
	_pending_default_spawns.append(peer_id)
	_pending_attempts[peer_id] = 0
	_try_dispatch_default_spawns()

func _try_dispatch_default_spawns() -> void:
	if not world_server or not world_server.multiplayer_api:
		return
	var mp: MultiplayerPeer = world_server.multiplayer_api.multiplayer_peer
	var dispatched: Array[int] = []
	for pid in _pending_default_spawns:
		if _dispatch_default_spawn(pid, mp):
			dispatched.append(pid)
	for pid in dispatched:
		_pending_default_spawns.erase(pid)
		_pending_attempts.erase(pid)
	if not _pending_default_spawns.is_empty():
		_spawn_retry_timer.start()

func _dispatch_default_spawn(peer_id: int, mp: MultiplayerPeer) -> bool:
	if _default_instance == null:
		return false

	# CORRECCIÓN: Usar get_peers() de la API en lugar de mp.has_peer()
	# Si mp es nulo o el peer_id no está en la lista de peers conectados, fallamos.
	if mp == null or not peer_id in world_server.multiplayer_api.get_peers():
		return false

	if _default_instance.charged_instances.is_empty():
		return false

	print("InstanceManager: Player %d authenticated, sending to Overworld." % peer_id)
	charge_new_instance.rpc_id(
		peer_id,
		_default_instance.map_path,
		_default_instance.charged_instances[0].name
	)
	return true

func _on_spawn_retry_timeout() -> void:
	if not world_server or not world_server.multiplayer_api:
		return
	var mp: MultiplayerPeer = world_server.multiplayer_api.multiplayer_peer
	var to_remove: Array[int] = []
	for pid in _pending_default_spawns:
		_pending_attempts[pid] = _pending_attempts.get(pid, 0) + 1
		if _dispatch_default_spawn(pid, mp):
			to_remove.append(pid)
		elif _pending_attempts[pid] > 50: # ~10s de reintentos
			to_remove.append(pid)
	for pid in to_remove:
		_pending_default_spawns.erase(pid)
		_pending_attempts.erase(pid)
	if not _pending_default_spawns.is_empty():
		_spawn_retry_timer.start()


func unload_unused_instances() -> void:
	for child in get_children():
		if not child is ServerInstance:
			continue
		var instance: ServerInstance = child as ServerInstance
		if instance.instance_resource.load_at_startup:
			continue
		if instance.connected_peers:
			continue
		instance.instance_resource.charged_instances.erase(instance)
		instance.queue_free()
