extends DataRequestHandler


func data_request_handler(
	peer_id: int,
	instance: ServerInstance,
	args: Dictionary
) -> Dictionary:
	var to_get: String = args.get("q", "")
	if to_get.is_empty():
		return {}
	var club: Club = instance.world_server.database.player_data.clubs.get(to_get)
	var club_info: Dictionary
	if club:
		club_info = {"name": club.club_name, "size": club.members.size()}
	return club_info
