class_name ServerInstance
extends SubViewport

# Nota: quitamos type-hints en la señal para evitar fallos de parse en autoload.
signal player_entered_warper(player: Node, current_instance, warper)

# --- CARGAR LA ESCENA 3D DEL SERVIDOR ---
const PLAYER: PackedScene = preload("res://source/server/player/player_3d_server.tscn")
# ----------------------------------------

static var world_server: WorldServer
static var global_chat_commands: Dictionary
static var global_role_definitions: Dictionary = preload("res://source/server/world/data/server_roles.tres").get_roles()

var local_chat_commands: Dictionary
var local_role_definitions: Dictionary
var local_role_assignments: Dictionary

# USAR 'Node' GENÉRICO
var players_by_peer_id: Dictionary

var connected_peers: PackedInt64Array = PackedInt64Array()
var awaiting_peers: Dictionary = {}

var last_accessed_time: float
var instance_map: Map
var instance_resource: InstanceResource
var synchronizer_manager: StateSynchronizerManagerServer
var request_handlers: Dictionary


func _init() -> void:
	# Inicializamos el manager aquí para que esté listo antes de load_map
	synchronizer_manager = StateSynchronizerManagerServer.new()
	synchronizer_manager.name = "StateSynchronizerManager"


func _ready() -> void:
	# Añadimos el hijo aquí si no se ha añadido ya
	if synchronizer_manager.get_parent() != self:
		add_child(synchronizer_manager, true)
		
	world_server.multiplayer_api.peer_disconnected.connect(
		func(peer_id: int):
			if connected_peers.has(peer_id):
				despawn_player(peer_id)
	)


func load_map(map_path: String) -> void:
	if instance_map:
		instance_map.queue_free()
	
	var packed_scene: PackedScene = ResourceLoader.load(map_path, "PackedScene")
	if packed_scene == null:
		printerr("ERROR CRÍTICO: No se pudo cargar la escena '%s' (PackedScene nulo)." % map_path)
		return

	var scene_node = packed_scene.instantiate()
	instance_map = scene_node as Map
	
	if not instance_map:
		printerr("ERROR CRÍTICO: La escena cargada en '%s' no es de tipo Map (falta script o tipo incorrecto)." % map_path)
		scene_node.queue_free()
		return
	# -------------------------

	add_child(instance_map)
	
	# Asegurar que el manager esté en el árbol antes de inicializar zonas
	if synchronizer_manager.get_parent() != self:
		add_child(synchronizer_manager, true)
	
	# Inicializamos las zonas ahora que tenemos el mapa cargado
	synchronizer_manager.init_zones_from_map(instance_map)
	
	# Conectamos señales solo cuando el mapa esté listo en el árbol
	if instance_map.is_node_ready():
		_on_map_ready()
	else:
		instance_map.ready.connect(_on_map_ready)


func _on_map_ready() -> void:
	if instance_map.replicated_props_container:
		synchronizer_manager.add_container(1_000_000, instance_map.replicated_props_container)
	for child in instance_map.get_children():
		if child.has_signal("player_entered_interaction_area"):
			child.player_entered_interaction_area.connect(self._on_player_entered_interaction_area)


func _on_player_entered_interaction_area(player: Node, interaction_area: Node) -> void:
	if player.has_method("has_recently_teleported") and player.has_recently_teleported():
		return
	if interaction_area is Warper:
		player_entered_warper.emit.call_deferred(player, self, interaction_area)
	if interaction_area is Teleporter:
		if player.has_method("mark_just_teleported"):
			player.mark_just_teleported()
		var syn = player.get_node_or_null("StateSynchronizer")
		if syn:
			# En 3D, global_position es Vector3, que es lo que espera PathRegistry tras los cambios
			syn.set_by_path(^":position", interaction_area.target.global_position)


@rpc("any_peer", "call_remote", "reliable", 0)
func ready_to_enter_instance() -> void:
	var peer_id: int = multiplayer.get_remote_sender_id()
	spawn_player(peer_id)


@rpc("authority", "call_remote", "reliable", 0)
func spawn_player(peer_id: int) -> void:
	var player: Node
	var spawn_index: int = 0
	if awaiting_peers.has(peer_id):
		player = awaiting_peers[peer_id]["player"]
		spawn_index = awaiting_peers[peer_id]["target_id"]
		awaiting_peers.erase(peer_id)
	else:
		player = instantiate_player(peer_id)
		data_push.rpc_id(peer_id, &"chat.message", {"text": get_motd(), "id": 1, "name": "Server"})
	
	if player.has_method("mark_just_teleported"):
		player.mark_just_teleported()
	
	instance_map.add_child(player, true)
	players_by_peer_id[peer_id] = player
	
	var syn: StateSynchronizer = player.get_node("StateSynchronizer")
	# USA COORDENADAS 3D (Vector3)
	syn.set_by_path(^":position", instance_map.get_spawn_position(spawn_index))
	
	synchronizer_manager.add_entity(peer_id, syn)
	synchronizer_manager.register_peer(peer_id)

	connected_peers.append(peer_id)
	_propagate_spawn(peer_id)


func instantiate_player(peer_id: int) -> Node:
	var player_resource: PlayerResource = world_server.connected_players[peer_id]
	
	# 1. Instanciar el cuerpo 3D del servidor
	var new_player: Node = PLAYER.instantiate()
	new_player.name = str(peer_id)
	
	# 2. Crear el Sincronizador manualmente
	if not new_player.has_node("StateSynchronizer"):
		var syn = StateSynchronizer.new()
		syn.name = "StateSynchronizer"
		syn.root_node = new_player
		new_player.add_child(syn)
	
	# 3. Configurar Jugador (Crea componentes internos)
	if new_player.has_method("setup_player"):
		new_player.setup_player(peer_id, world_server.world_manager)
	
	# 4. [FIX CRITICO] Inyección de Dependencias Manual
	var asc = new_player.get_node_or_null("AbilitySystemComponent")
	var syn_node = new_player.get_node("StateSynchronizer")
	
	if asc and syn_node:
		asc.synchronizer = syn_node # Conectar cables manualmente
	
	# 5. Inicializar valores de red
	syn_node.set_by_path(^":skin_id", player_resource.skin_id)
	syn_node.set_by_path(^":display_name", player_resource.display_name)
	
	if "player_resource" in new_player:
		new_player.player_resource = player_resource
	
	# 6. Cargar Stats
	var player_stats: Dictionary = player_resource.BASE_STATS.duplicate()
	
	player_resource.stats = player_stats
	data_push.rpc_id(peer_id, &"stats.get", player_stats)
	
	# 7. Aplicar Stats iniciales de forma segura
	if asc:
		for stat_name in player_stats:
			var value: float = player_stats[stat_name]
			# Usamos ensure_attribute para evitar errores si el path no está registrado
			asc.ensure_attribute(stat_name, value)
			
	return new_player

func get_motd() -> String:
	if world_server and world_server.has_method("get_motd"):
		return world_server.get_motd()
	return "Welcome!"


func _propagate_spawn(new_player_id: int) -> void:
	for peer_id: int in connected_peers:
		spawn_player.rpc_id(peer_id, new_player_id)
		if new_player_id != peer_id:
			spawn_player.rpc_id(new_player_id, peer_id)


@rpc("authority", "call_remote", "reliable", 0)
func despawn_player(peer_id: int, delete: bool = false) -> void:
	var idx := connected_peers.find(peer_id)
	if idx != -1:
		connected_peers.remove_at(idx)
	synchronizer_manager.remove_entity(peer_id)
	synchronizer_manager.unregister_peer(peer_id)
	
	var player: Node = players_by_peer_id.get(peer_id)
	if player:
		if delete:
			player.queue_free()
		else:
			instance_map.remove_child(player)
		players_by_peer_id.erase(peer_id)
	
	for id: int in connected_peers:
		if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(id):
			var mp := multiplayer.get_multiplayer_peer()
			if mp and mp.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				despawn_player.rpc_id(id, peer_id)


@rpc("any_peer", "call_remote", "reliable", 1)
func data_request(request_id: int, type: StringName, args: Dictionary) -> void:
	var peer_id: int = multiplayer.get_remote_sender_id()
	if not request_handlers.has(type):
		var script: GDScript = ContentRegistryHub.load_by_slug(&"data_request_handlers", type) as GDScript
		if not script: return
		var request_handler: DataRequestHandler = script.new() as DataRequestHandler
		if not request_handler: return
		request_handlers[type] = request_handler
	
	data_response.rpc_id(
		peer_id, request_id, type,
		request_handlers[type].data_request_handler(peer_id, self, args)
	)


@rpc("authority", "call_remote", "reliable", 1)
func data_response(request_id: int, type: StringName, data: Dictionary) -> void: pass


@rpc("authority", "call_remote", "reliable", 1)
func data_push(type: StringName, data: Dictionary) -> void: pass


func propagate_rpc(callable: Callable) -> void:
	for peer_id: int in connected_peers:
		callable.rpc_id(peer_id)


func get_player(peer_id: int) -> Node:
	return players_by_peer_id.get(peer_id, null)


func get_player_syn(peer_id: int) -> StateSynchronizer:
	var p: Node = get_player(peer_id)
	return null if p == null else p.get_node_or_null(^"StateSynchronizer")


func set_player_path_value(peer_id: int, rel_path: NodePath, value: Variant) -> bool:
	var syn: StateSynchronizer = get_player_syn(peer_id)
	if syn == null: return false
	syn.set_by_path(rel_path, value)
	return true


func set_player_attr_current(peer_id: int, attr: StringName, value: float) -> bool:
	var p: Node = get_player(peer_id)
	if p == null: return false
	var asc = p.get_node_or_null("AbilitySystemComponent")
	if asc != null and asc.has_method("set_attr_current"):
		asc.set_attr_current(attr, value)
		return true
	var np := NodePath("AbilitySystemComponent:" + String(attr))
	return set_player_path_value(peer_id, np, value)
