extends SceneTree

func _init():
	print("Verifying project integrity...")
	
	var scripts_to_check = [
		"res://source/scripts/player.gd",
		"res://source/scripts/network.gd",
		"res://source/scripts/gesture_manager.gd",
		"res://source/scripts/item_database.gd",
		"res://source/scripts/inventory_ui.gd",
		"res://source/scripts/level.gd"
	]
	
	var scenes_to_check = [
		"res://source/scenes/level/level.tscn",
		"res://source/scenes/level/player.tscn",
		"res://source/scenes/ui/inventory_ui.tscn"
	]
	
	for s_path in scripts_to_check:
		print("Checking script: " + s_path)
		var s = load(s_path)
		if s:
			print("  OK")
		else:
			print("  FAILED to load")
			quit(1)
			
	for s_path in scenes_to_check:
		print("Checking scene: " + s_path)
		var s = load(s_path)
		if s:
			print("  OK")
		else:
			print("  FAILED to load")
			quit(1)
			
	print("Verification complete. All key files loaded successfully.")
	quit(0)
