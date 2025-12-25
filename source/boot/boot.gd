extends Node

func _ready() -> void:
	# Small delay to let autoloads finish initialization
	await get_tree().process_frame

	var scene_path: String = "res://source/client/client_main.tscn"

	if OS.has_feature("master-server"):
		scene_path = "res://source/server/master/master_main.tscn"
	elif OS.has_feature("gateway-server"):
		scene_path = "res://source/server/gateway/gateway_main.tscn"
	elif OS.has_feature("world-server"):
		scene_path = "res://source/server/world/world_main.tscn"
	elif OS.has_feature("client"):
		scene_path = "res://source/client/client_main.tscn"

	print("Booting into: " + scene_path)

	# Verify file exists before switching
	if not FileAccess.file_exists(scene_path):
		printerr("Boot error: Scene not found: " + scene_path)
		# Fallback or quit
		if OS.has_feature("server"):
			get_tree().quit(1)
		return

	get_tree().change_scene_to_file(scene_path)
