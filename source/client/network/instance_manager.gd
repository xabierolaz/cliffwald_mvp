class_name InstanceManagerClient
extends Node


signal instance_changed(instance: InstanceClient)

var current_ui: UI
var current_instance: InstanceClient


func _ready() -> void:
	pass


@rpc("authority", "call_remote", "reliable", 0)
func charge_new_instance(map_path: String, instance_id: String) -> void:
	var new_instance: InstanceClient = InstanceClient.new()
	new_instance.name = instance_id

	print("Loading new map: %s." % map_path)
	var map: Map = load(map_path).instantiate() as Map
	if not map:
		return
	new_instance.instance_map = map

	if current_instance:
		if current_instance.local_player:
			current_instance.instance_map.remove_child(current_instance.local_player)
			#current_instance.local_player.reparent(new_instance, false)
		current_instance.queue_free()
	current_instance = new_instance
	new_instance.add_child(map, true)
	add_child(new_instance, true)

	# Enviamos el ready solo cuando el mapa está en el árbol para que InstanceClient tenga instance_map válido.
	var ready_state := {"sent": false}
	var send_ready := func():
		if ready_state["sent"]:
			return
		ready_state["sent"] = true
		# Prefer calling the RPC on the Manager itself if that is the intended flow,
		# OR keep calling it on new_instance if that matches the child node structure.
		# For now, we just add the definition below to fix the checksum.
		new_instance.ready_to_enter_instance.rpc_id(1)
		instance_changed.emit(new_instance)

	# Si el mapa ya estaba listo, disparamos de inmediato; si no, esperamos al signal.
	if map.is_node_ready():
		send_ready.call()
	else:
		map.ready.connect(send_ready, CONNECT_ONE_SHOT)

	# Watchdog: si no tenemos player local en breve, reenviamos el ready.
	call_deferred("_ensure_local_player_spawned", new_instance)

	# Charge different type of UI/HUD and clear old one,
	# for mini game / special instances that would require unique HUD ?

	#if current_ui:
		#current_ui.queue_free()
	if not current_ui:
		current_ui = preload("res://source/client/ui/ui.tscn").instantiate()
		get_parent().add_sibling(current_ui)


@rpc("any_peer", "call_remote", "reliable", 0)
func ready_to_enter_instance() -> void:
	pass


func _ensure_local_player_spawned(instance: InstanceClient) -> void:
	# Revisa luego de un pequeño delay si se creó el jugador local; si no, reenvía el ready.
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	if instance != current_instance:
		return
	var my_id: int = multiplayer.get_unique_id()
	if instance.players_by_peer_id.has(my_id):
		return
	print("InstanceManager: re-enviando ready_to_enter_instance (jugador local no spawneado)")
	instance.ready_to_enter_instance.rpc_id(1)
