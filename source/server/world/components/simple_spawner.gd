extends Node

var player_scene = preload("res://source/common/gameplay/characters/player/net_player.tscn")

func _ready():
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

# Called explicitly by InstanceServer when client says "I'm ready"
# OR called by client via RPC once map is loaded
@rpc("any_peer", "call_remote", "reliable", 0)
func request_spawn_server() -> void:
	var id = multiplayer.get_remote_sender_id()
	spawn_player(id)

func spawn_player(id: int, data: PlayerResource = null):
	if get_parent().has_node(str(id)):
		return # Already spawned

	print("Spawning NetPlayer for: %d" % id)
	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = Vector3(0, 2.5, 0)

	if data:
		player.skin_id = data.skin_id

	# Check for spawn points
	var spawn_point = get_parent().get_node_or_null("SpawnPoint")
	if spawn_point:
		player.position = spawn_point.position

	get_parent().add_child(player)

func _on_peer_disconnected(id: int):
	var player = get_parent().get_node_or_null(str(id))
	if player:
		player.queue_free()
