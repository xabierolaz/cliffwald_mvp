class_name ServerInstance
extends SubViewport

signal player_entered_warper(player: Node, current_instance, warper)

static var world_server: WorldServer
static var global_chat_commands: Dictionary = {}
static var global_role_definitions: Dictionary = preload("res://source/server/world/data/server_roles.tres").get_roles()

var connected_peers: PackedInt64Array = PackedInt64Array()
var instance_map: Map
var instance_resource: InstanceResource
var request_handlers: Dictionary

func _ready() -> void:
	world_server.multiplayer_api.peer_disconnected.connect(_on_peer_disconnected)

func load_map(map_path: String) -> void:
	if instance_map:
		instance_map.queue_free()

	var packed_scene: PackedScene = ResourceLoader.load(map_path, "PackedScene")
	if packed_scene == null:
		print("ERROR: Could not load map ", map_path)
		return

	var scene_node = packed_scene.instantiate()
	instance_map = scene_node as Map
	add_child(instance_map)
	print("Map loaded: ", map_path)

func _on_peer_disconnected(peer_id: int) -> void:
	var idx := connected_peers.find(peer_id)
	if idx != -1:
		connected_peers.remove_at(idx)

	# MultiplayerSpawner handles despawn automatically if using spawn_function?
	# If using scene list, we might need to manually free.
	# Our SimpleSpawner handles queue_free on disconnect too.

# Stub functions to prevent crashes from other scripts calling them
func get_motd() -> String: return "Welcome to Cliffwald!"
func propagate_rpc(callable: Callable) -> void: pass
func get_player(peer_id: int) -> Node: return null

func set_player_path_value(peer_id: int, rel_path: NodePath, value: Variant) -> bool:
	print("set_player_path_value stub called for %d path %s" % [peer_id, str(rel_path)])
	return false
