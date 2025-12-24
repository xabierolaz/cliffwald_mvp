extends Node

const OUTPUT_PATH := "res://server_audit.txt"
const ROOT_DIR := "res://"

func _ready() -> void:
	# Ejecuta la exportación al arrancar el juego.
	_export_project()
	# No se necesita en el árbol después de exportar.
	queue_free()


func _export_project() -> void:
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if not file:
		push_error("No se pudo abrir %s" % OUTPUT_PATH)
		return
	file.store_line("=== PROJECT EXPORT (files + scripts + scenes) ===")
	_dump_dir(ROOT_DIR, file)
	file.close()
	print("ProjectExport: wrote %s" % OUTPUT_PATH)


func _dump_dir(path: String, file: FileAccess) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry_name := dir.get_next()
		if entry_name == "":
			break
		if dir.current_is_dir():
			if entry_name.begins_with("."):
				continue
			_dump_dir(path.path_join(entry_name), file)
		else:
			var full_path := path.path_join(entry_name)
			# List every file name
			file.store_line(full_path)
			# Dump content for .gd/.tscn
			if entry_name.ends_with(".gd") or entry_name.ends_with(".tscn"):
				file.store_line("\n--- %s ---" % full_path)
				var content := FileAccess.get_file_as_string(full_path)
				file.store_string(content)
