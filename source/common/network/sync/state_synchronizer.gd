@tool
class_name StateSynchronizer
extends Node

## Sincronizador de Estado: Aplica baselines/deltas y rastrea cambios locales.

@export var root_node: Node

# Estado interno
var last_applied: Dictionary = {}      # fid -> valor
var dirty_outgoing: Dictionary = {}    # fid -> valor pendiente
var _pending_pairs: Array = []         # buffer de espera
var _prop_cache: Dictionary = {}       # Cache de propiedades (PropertyCache)

func _ready() -> void:
	if Engine.is_editor_hint():
		if root_node == null: root_node = get_parent()
		return
	assert(root_node != null, "StateSynchronizer necesita un nodo raíz.")

# --- API Pública ---

func apply_baseline(pairs: Array) -> void:
	_apply_pairs(pairs)
	dirty_outgoing.clear()

func apply_delta(pairs: Array) -> void:
	_apply_pairs(pairs)

func collect_dirty_pairs() -> Array:
	if dirty_outgoing.is_empty(): return []
	var out: Array = []
	for fid: int in dirty_outgoing:
		out.append([fid, dirty_outgoing[fid]])
	dirty_outgoing.clear()
	return out

func capture_baseline() -> Array:
	var out: Array = []
	for fid: int in last_applied:
		out.append([fid, last_applied[fid]])
	return out

# --- Helpers ---

func set_by_path(path: NodePath, value: Variant, only_if_changed: bool = true) -> void:
	var path_str := String(path)
	var fid: int = PathRegistry.ensure_id(path_str)
	if fid == 0:
		push_error("StateSynchronizer: unable to register path '%s'." % path_str)
		return
	# Marca sucio y actualiza la caché local
	mark_dirty_by_id(fid, value, only_if_changed)
	var property_cache: PropertyCache = PropertyCache.ensure_cache_for(fid, root_node, _prop_cache)
	if property_cache == null or not property_cache.apply_or_try_resolve(root_node, value):
		_pending_pairs.append([fid, value])
	_try_flush_pending()

# --- Marcar Sucio (Cambios Locales) ---

func mark_dirty_by_id(fid: int, value: Variant, only_if_changed: bool = true) -> void:
	if only_if_changed:
		var prev: Variant = last_applied.get(fid, null)
		# Nota: SyncUtils.roughly_equal se asume existente o usa comparacion simple
		if prev != null and prev == value: return 
	last_applied[fid] = value
	dirty_outgoing[fid] = value

func mark_dirty_by_path(path: NodePath, value: Variant, only_if_changed: bool = true) -> void:
	var fid: int = PathRegistry.ensure_id(String(path))
	if fid == 0:
		return
	mark_dirty_by_id(fid, value, only_if_changed)

func mark_many_by_id(pairs: Array, only_if_changed: bool = true) -> void:
	for pair: Array in pairs:
		if pair.size() < 2: continue
		mark_dirty_by_id(pair[0], pair[1], only_if_changed)

func mark_many_by_path(pairs: Array, only_if_changed: bool = true) -> void:
	for pair: Array in pairs:
		if pair.size() < 2: continue
		mark_dirty_by_path(pair[0], pair[1], only_if_changed)

# --- Internos ---

func _apply_pairs(pairs: Array) -> void:
	for pair: Array in pairs:
		if pair.size() < 2: continue
		var fid: int = pair[0]
		var value: Variant = pair[1]
		last_applied[fid] = value

		var property_cache: PropertyCache = PropertyCache.ensure_cache_for(fid, root_node, _prop_cache)
		if property_cache == null or not property_cache.apply_or_try_resolve(root_node, value):
			_pending_pairs.append([fid, value])

	_try_flush_pending()

func _try_flush_pending() -> void:
	if _pending_pairs.is_empty(): return
	var pending: Array = _pending_pairs
	_pending_pairs = []
	# Reintentar aplicar
	for pair: Array in pending:
		var fid: int = pair[0]
		var value: Variant = pair[1]
		var property_cache: PropertyCache = PropertyCache.ensure_cache_for(fid, root_node, _prop_cache)
		if property_cache == null or not property_cache.apply_or_try_resolve(root_node, value):
			_pending_pairs.append(pair) # Vuelve a la cola si falla
