class_name WorldPlayerData
extends Resource
# I can't recommend using Resources as a whole database, but for the demonstration,
# I found it interesting to use Godot exclusively to have a minimal setup.

## Used to store the different character IDs of registered accounts.[br][br]
## So if player with name ID "horizon" logs in to this world,
## we can retrieve its different character IDs thanks to this.[br][br]
## Here is how it should look like:
## [codeblock]
## print(accounts) # {"horizon": [6, 14], "another_guy": [2]}
## [/codeblock]
@export var accounts: Dictionary
@export var max_character_per_account: int = 3

@export var players: Dictionary
@export var next_player_id: int = 0

@export var admin_ids: PackedInt32Array
@export var user_roles: Dictionary
@export var clubs: Dictionary


func get_player_resource(player_id: int) -> PlayerResource:
	if players.has(player_id):
		return players[player_id]
	return null


func create_player_character(username: String, character_data: Dictionary) -> int:
	if (
		accounts.has(username)
		and accounts[username].size() > max_character_per_account
	):
		return -1
	
	next_player_id += 1
	var player_id: int = next_player_id
	var player_character := PlayerResource.new()
	
	# Temporary for fast test
	# No hay armas ni consumibles preasignados; los alumnos ya llevan su varita estética.
	player_character.inventory = {}
	
	player_character.available_attributes_points = 0
	
	player_character.init(
		player_id, username,
		character_data.get("name", player_character.display_name),
		character_data.get("skin", 1)
	)
	player_character.house = character_data.get("house", &"Ignis")
	players[player_id] = player_character
	if accounts.has(username):
		accounts[username].append(player_id)
	else:
		accounts[username] = [player_id] as PackedInt32Array
	return player_id


func get_account_characters(account_name: String) -> Dictionary:
	var data: Dictionary#[int, Dictionary]
	
	if accounts.has(account_name):
		for player_id: int in accounts[account_name]:
			var player_character: PlayerResource = get_player_resource(player_id)
			if player_character:
				data[player_id] = {
					"name": player_character.display_name,
					"skin": player_character.skin_id,
					"class": "Student",
				}
	return data


func create_club(club_name: String, player_id: int) -> bool:
	var player: PlayerResource = players.get(player_id)
	if not player or clubs.has(club_name):
		return false
	var new_club: Club = Club.new()
	new_club.leader_id = player_id
	new_club.club_name = club_name
	new_club.add_member(player_id, "Leader")
	clubs[club_name] = new_club
	return true
