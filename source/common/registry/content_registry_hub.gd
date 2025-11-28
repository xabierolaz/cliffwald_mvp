class_name ContentRegistryHub


static var _content_by_name: Dictionary = {}
static var _versions: Dictionary = {}


static func _static_init() -> void:
	if OS.has_feature("master-server") or OS.has_feature("gateway-server"):
		return
	const INDEXES_DIR: String = "res://source/common/registry/indexes/"
	for index_path: String in _safe_list_index_files(INDEXES_DIR):
		var content_index: ContentIndex = ResourceLoader.load(INDEXES_DIR + index_path)
		if not content_index:
			continue
		var name := index_path.trim_suffix("_index.tres")
		register_registry(name, content_index)


static func register_registry(content_name: StringName, content_index: ContentIndex) -> void:
	#var content_registry: ContentRegistry = ContentRegistry.new(content_index)
	_content_by_name[content_name] = ContentRegistry.new(content_index)
	_versions[content_name] = content_index.version


# Godot 4 doesn't expose ResourceLoader.list_directory; DirAccess works everywhere.
static func _safe_list_index_files(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for file_name: String in dir.get_files():
		if file_name.ends_with("_index.tres"):
			out.append(file_name)
	return out


static func registry_of(content_name: StringName) -> ContentRegistry:
	return _content_by_name.get(content_name, null)


static func version_of(content_name: StringName) -> int:
	return _versions.get(content_name, 0)


static func id_from_slug(content_name: StringName, slug: StringName) -> int:
	return registry_of(content_name).id_from_slug(slug)


static func load_by_id(
	content_name: StringName,
	id: int,
	cache_mode: ResourceLoader.CacheMode = ResourceLoader.CACHE_MODE_REUSE
) -> Resource:
	var path: StringName = registry_of(content_name).path_from_id(id)
	if path.is_empty():
		return null
	return ResourceLoader.load(path, "", cache_mode)


static func load_by_slug(
	content_name: StringName,
	slug: StringName,
	cache_mode: ResourceLoader.CacheMode = ResourceLoader.CACHE_MODE_REUSE
) -> Resource:
	var path: StringName = registry_of(content_name).path_from_slug(slug)
	if path.is_empty():
		return null
	return ResourceLoader.load(path, "", cache_mode)


class CachedContent:
	pass
