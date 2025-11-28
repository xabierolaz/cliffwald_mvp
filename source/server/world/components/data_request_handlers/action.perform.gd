extends DataRequestHandler


func data_request_handler(
	peer_id: int,
	instance: ServerInstance,
	args: Dictionary
) -> Dictionary:
	var player = instance.players_by_peer_id.get(peer_id, null)
	if not player:
		return {}
	
	# Armas y acciones legado deshabilitadas; GestureManager manejará hechizos.
	return {}
