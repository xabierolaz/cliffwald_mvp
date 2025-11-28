extends DataRequestHandler


func data_request_handler(
	peer_id: int,
	instance: ServerInstance,
	args: Dictionary
) -> Dictionary:
	var club_name: String = args.get("name", "")
	var player_resource: PlayerResource = instance.world_server.connected_players.get(peer_id, null)
	
	if club_name.is_empty() or not player_resource:
		return {}
	
	var club_created: bool = instance.world_server.database.player_data.create_club(
		club_name, player_resource.player_id
	)
	if not club_created:
		return {}
	
	var club: Club = instance.world_server.database.player_data.clubs.get(club_name)
	if not club:
		return {}
	
	club.add_member(player_resource.player_id, "Leader")
	club.leader_id = player_resource.player_id
	
	player_resource.club = club
	
	var club_info: Dictionary = {
		"name": club.club_name,
		"size": club.members.size(),
		"is_in_club": true,
	}
	return club_info
