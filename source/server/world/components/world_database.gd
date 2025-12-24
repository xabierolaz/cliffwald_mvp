class_name WorldDatabase
extends Node


var database_path: String

var player_data: WorldPlayerData


func start_database(world_info: Dictionary) -> void:
	configure_database(world_info)
	load_world_database()


func configure_database(world_info: Dictionary) -> void:
	# Force using the res:// path to ensure consistency
	# In a real deployment, you might want this to be "user://"
	var name_val: Variant = world_info.get("name", "world")
	if typeof(name_val) != TYPE_STRING:
		name_val = str(name_val)
	database_path = "res://source/server/world/data/" + name_val.to_lower() + ".tres"


func load_world_database() -> void:
	if ResourceLoader.exists(database_path, "WorldPlayerData"):
		player_data = ResourceLoader.load(database_path, "WorldPlayerData")
	else:
		player_data = WorldPlayerData.new()


func save_world_database() -> void:
	var error: Error = ResourceSaver.save(player_data, database_path)
	if error:
		printerr("Error while saving player_data %s." % error_string(error))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_world_database()
