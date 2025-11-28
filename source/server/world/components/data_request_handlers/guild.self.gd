extends DataRequestHandler


func data_request_handler(
	peer_id: int,
	instance: ServerInstance,
	args: Dictionary
) -> Dictionary:
	var player = instance.players_by_peer_id.get(peer_id)
	if not player:
		return {}
	
	var club: Club = player.player_resource.club
	var data: Dictionary
	if not club:
		return {}
	data = {"name": club.club_name}
	return data
