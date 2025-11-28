class_name PropertyCache

## Cache por campo: resuelve NodePath una vez y guarda la referencia.

var node_path: NodePath
var property_path: NodePath
var node: Node

func _init(_node_path: NodePath, _property_path: NodePath, _node: Node) -> void:
	node_path = _node_path
	property_path = _property_path
	node = _node

func apply_or_try_resolve(root: Node, value: Variant) -> bool:
	if node != null and is_instance_valid(node):
		node.set_indexed(property_path, value)
		return true
	
	# Si node_path está vacío, se refiere al propio root
	if node_path.is_empty():
		node = root
	else:
		node = root.get_node_or_null(node_path)
		
	if node != null:
		node.set_indexed(property_path, value)
		return true
		
	return false

static func ensure_cache_for(property_id: int, root: Node, cache: Dictionary, cache_key: Variant = null) -> PropertyCache:
	if cache_key == null: cache_key = property_id
	var pc: PropertyCache = cache.get(cache_key, null)
	if pc: return pc

	# IMPORTANTE: Esto requiere tu PathRegistry global
	var np: NodePath = PathRegistry.nodepath_of(property_id)
	if np.is_empty(): return null
	var split := _split_nodepath(np)
	if split.property_path.is_empty(): return null

	pc = PropertyCache.new(
		split.node_path,
		split.property_path,
		root if split.node_path.is_empty() else null
	)
	cache[cache_key] = pc
	return pc


## TinyNodePath replacement: separa NodePath en ruta de nodo y ruta de propiedad (subnames).
static func _split_nodepath(np: NodePath) -> Dictionary:
	var node_parts: Array[String] = []
	for i in range(np.get_name_count()):
		node_parts.append(String(np.get_name(i)))
	var node_path_str := "/".join(node_parts)
	if node_path_str == "/":
		node_path_str = ""
	var prop_path := ""
	if np.get_subname_count() > 0:
		var subs: Array[String] = []
		for j in range(np.get_subname_count()):
			subs.append(String(np.get_subname(j)))
		prop_path = ":" + ":".join(subs)

	return {
		"node_path": NodePath(node_path_str),
		"property_path": NodePath(prop_path)
	}
