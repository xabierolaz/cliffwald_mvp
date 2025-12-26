@tool
extends Node

# Usage:
# godot --headless --script res://source/common/utils/run_mmo.gd
# or call RunMMO.launch_all() from the editor console.
#
# Launches master, gateway, world (headless) and two clients using the current Godot executable.

class_name RunMMO

const SERVER_FEATURES := [
	"master-server",
	"gateway-server",
	"world-server"
]

const CLIENT_COUNT := 2

static func _executable() -> String:
	return OS.get_executable_path()

static func _launch(name: String, args: PackedStringArray) -> void:
	var exe := _executable()
	var err := OS.create_process(exe, args, false)
	if err != OK:
		push_error("RunMMO: failed to launch %s (err=%d)" % [name, err])

static func launch_all() -> void:
	# Servers
	for feature in SERVER_FEATURES:
		_launch(feature, [
			"--path", ".",
			"--headless",
			"--feature", feature
		])
	# Clients
	for i in CLIENT_COUNT:
		_launch("client_%d" % i, [
			"--path", ".",
			"--feature", "client"
		])

func _ready() -> void:
	launch_all()
	# Exit the launcher instance.
	get_tree().quit()
