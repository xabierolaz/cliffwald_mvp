class_name WorldMain
extends Node


var world_info: Dictionary


func _ready() -> void:
	print("WorldMain: _ready start")
	# Server tick rate
	# For comparaison:
	# Eve Online - 1 tick par second.
	# Fortnite (Battle royale 100 players) - 30 ticks per second.
	# Albion Online - 2 ticks per second (to verify).
	# Valorant (5v5 FPS game) - 128 ticks per second.
	# I believe it depends of your game and architecture, it's a large topic.
	Engine.set_physics_ticks_per_second(10) # 60 by default
	
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("World Server")
		
	# Default config path. to use another one, override this;
	# or write --config=config_file_path.cfg as a launch argument.
	world_info = ConfigFileUtils.load_section_with_defaults(
		"world-server",
		CmdlineUtils.get_parsed_args().get("config", "res://data/config/world_config.cfg"),
		{
			"name": "NoName",
			"max_players": 200,
			"hardcore": false,
			"motd": "Welcome!",
			"bonus_xp": 0.0,
			"max_character": 5,
			"pvp": true,
			"dev_insecure_auth": false,
			"dev_skip_master": false
		}
		
	)
	if world_info.has("error"):
		printerr("World server loading configuration failed.")
	else:
		print("WorldMain: start_database")
		$Database.start_database(world_info)
		var skip_master: bool = world_info.get("dev_skip_master", false)
		if skip_master:
			print("🔌 DEV: saltando conexión con Master Server (dev_skip_master=true).")
			$WorldServer.world_manager = null
		else:
			print("WorldMain: conectando a Master")
			$WorldManagerClient.start_client_to_master_server(world_info)
			$WorldServer.world_manager = $WorldManagerClient
		print("WorldMain: arrancando WorldServer")
		$WorldServer.start_world_server()
