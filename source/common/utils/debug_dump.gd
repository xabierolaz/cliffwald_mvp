extends Node

# Optional runtime dump of files and the active scene tree.
# Enabled when the env var CLIFFWALD_DEBUG_DUMP is set to a non-empty value.
const ENV_ENABLE := "CLIFFWALD_DEBUG_DUMP"
const OUTPUT_PATH := "user://debug_dump.log"

func _ready() -> void:
	if not _enabled():
		return
	call_deferred("_dump_everything")


func _enabled() -> bool:
	if not OS.has_environment(ENV_ENABLE):
		return false
	return str(OS.get_environment(ENV_ENABLE)).strip_edges() != ""


func _dump_everything() -> void:
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		printerr("DebugDump: cannot open %s" % OUTPUT_PATH)
		return

	file.store_line("== Debug dump ==")
	file.store_line("Time: %s" % Time.get_datetime_string_from_system())
	file.store_line("Version: %s" % Engine.get_version_info().get("string", "unknown"))
	var features: PackedStringArray = PackedStringArray()
	if OS.has_method("get_features"):
		features = OS.call("get_features")
	elif OS.has_method("get_feature_tags"):
		features = OS.call("get_feature_tags")
	file.store_line("Features: %s" % ", ".join(features))
	file.store_line("Args: %s" % " ".join(OS.get_cmdline_args()))
	file.store_line("Current scene: %s" % str(get_tree().current_scene))
	file.store_line("")

	file.store_line("=== Files (res://) ===")
	for path in _list_files("res://"):
		file.store_line(path)
	file.store_line("")

	file.store_line("=== Scene Tree ===")
	_dump_tree(get_tree().root, file, 0)
	file.close()
	print("DebugDump: wrote %s" % OUTPUT_PATH)


func _list_files(base: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var stack: Array[String] = []
	stack.append(base)
	while stack.size() > 0:
		var dir_path: String = stack.pop_back()
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			var full_path := dir.get_current_dir().path_join(file_name)
			if dir.current_is_dir():
				stack.append(full_path)
			else:
				result.append(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	result.sort()
	return result


func _dump_tree(node: Node, file: FileAccess, depth: int) -> void:
	var line := "%s%s" % ["  ".repeat(depth), node.name]
	var script: Script = null
	if node is Node:
		script = node.get_script()
	if script and script.resource_path != "":
		line += " (%s)" % script.resource_path
	file.store_line(line)
	for child in node.get_children():
		_dump_tree(child, file, depth + 1)
