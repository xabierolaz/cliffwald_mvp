@tool
class_name ReplicatedPropsContainer
extends Node3D

## Contenedor compacto para props de escena "fríos" (estáticos y dinámicos).
## Permite al servidor marcar cambios y al cliente recibirlos sin saturar la red.

# Identificadores estáticos [0..STATIC_MAX], dinámicos empiezan después
const STATIC_MAX: int = 32767

# --- CPID helpers (16 bits child / 16 bits field) ---
const CPID_CHILD_BITS := 16
const CPID_FIELD_BITS := 16
const CPID_FIELD_MASK := 0xFFFF
const CPID_CHILD_MASK := 0xFFFF

static func make_cpid(child_id: int, field_id: int) -> int:
	return ((child_id & CPID_CHILD_MASK) << CPID_FIELD_BITS) | (field_id & CPID_FIELD_MASK)

static func cpid_child(cpid: int) -> int:
	return (cpid >> CPID_FIELD_BITS) & CPID_CHILD_MASK

static func cpid_field(cpid: int) -> int:
	return cpid & CPID_FIELD_MASK

@export var id_to_node: Dictionary
@export var node_to_id: Dictionary

var next_dynamic_prop_id: int = STATIC_MAX + 1
var dynamic_nodes: Dictionary = {}

# --- Colas de salida (Server tick) ---
var _dyn_spawns_queued: Array = []
var _dyn_despawns_queued: Array = []
var _ops_named_queued: Array = []

# --- Estado de props y suciedad ---
var _state_by_cpid: Dictionary = {}   # cpid -> valor
var _dirty_pairs: Dictionary = {}     # cpid -> valor pendiente
var _baseline_ops_by_child: Dictionary = {}
var _cpid_cache: Dictionary = {}
var _pending_by_cpid: Dictionary = {}

func _ready() -> void:
	if Engine.is_editor_hint() and id_to_node.is_empty():
		_bake_static_map()

# Herramienta de editor: mapea los hijos actuales como estáticos
func _bake_static_map() -> void:
	id_to_node.clear()
	node_to_id.clear()
	var next_id: int = 0
	for node: Node in get_children():
		id_to_node[next_id] = node
		node_to_id[node] = next_id
		next_id += 1

# --- Lógica Cliente ---

func apply_spawns(spawns: Array) -> void:
	for to_spawn: Array in spawns:
		if to_spawn.size() < 2: continue
		var child_id: int = to_spawn[0]
		var scene_id: int = to_spawn[1]

		if _resolve_child(child_id) != null: continue

		# Intentamos cargar la escena dinámica desde el registro de contenidos.
		var packed_scene: PackedScene = ContentRegistryHub.load_by_id(&"scenes", scene_id)
		if not packed_scene:
			push_warning("ReplicatedProps: escena %s no encontrada para spawn %d" % [scene_id, child_id])
			continue
		var instance: Node = packed_scene.instantiate()
		if not instance:
			push_warning("ReplicatedProps: no se pudo instanciar escena %s" % scene_id)
			continue
		dynamic_nodes[child_id] = instance
		instance.set_meta(&"rp_container", self)
		add_child(instance)
		
	_flush_pending_pairs_for_spawned(spawns)

func _flush_pending_pairs_for_spawned(spawns: Array) -> void:
	for to_spawn in spawns:
		if to_spawn.size() < 2: continue
		var child_id: int = to_spawn[0]
		var child: Node = _resolve_child(child_id)
		if child == null: continue
		for cpid in _pending_by_cpid.keys():
			if cpid_child(cpid) != child_id: continue
			var fid := cpid_field(cpid)
			var pc := PropertyCache.ensure_cache_for(fid, child, _cpid_cache, cpid)
			if pc != null and pc.apply_or_try_resolve(child, _pending_by_cpid[cpid]):
				_pending_by_cpid.erase(cpid)

func apply_pairs(pairs: Array) -> void:
	for pair: Array in pairs:
		if pair.size() < 2: continue
		var cpid: int = pair[0]
		var value: Variant = pair[1]
		var child_id: int = cpid_child(cpid)
		var fid: int = cpid_field(cpid)
		var child: Node = _resolve_child(child_id)
		
		if not child:
			_pending_by_cpid[cpid] = value
			continue
		
		var pc: PropertyCache = PropertyCache.ensure_cache_for(fid, child, _cpid_cache, cpid)
		if pc == null or not pc.apply_or_try_resolve(child, value):
			_pending_by_cpid[cpid] = value

func apply_ops_named(ops_named: Array) -> void:
	for ops: Array in ops_named:
		if ops.size() < 2: continue
		var method_str: String = ops[1]
		if not method_str.begins_with("rp_"): continue
		var child_id: int = ops[0]
		var args: Array = ops[2] if ops.size() > 2 else []
		var root: Node = _resolve_child(child_id)
		if root and root.has_method(method_str):
			Callable(root, method_str).bindv(args).call_deferred()

func apply_despawns(ids: Array) -> void:
	for cid: int in ids:
		var node: Node = dynamic_nodes.get(cid, null)
		if node:
			dynamic_nodes.erase(cid)
			node.queue_free()

# --- Lógica Servidor ---

func collect_container_outgoing_and_clear() -> Dictionary:
	var spawns: Array = _dyn_spawns_queued.duplicate()
	var despawns: Array = _dyn_despawns_queued.duplicate()
	var ops_named: Array = _ops_named_queued.duplicate()
	
	var pairs: Array = []
	for cpid: int in _dirty_pairs:
		pairs.append([cpid, _dirty_pairs[cpid]])
	_dirty_pairs.clear()
	_dyn_spawns_queued.clear()
	_dyn_despawns_queued.clear()
	_ops_named_queued.clear()

	return { "pairs": pairs, "spawns": spawns, "despawns": despawns, "ops_named": ops_named }

func capture_bootstrap_block() -> Dictionary:
	var spawns: Array = []
	for child_id: int in dynamic_nodes:
		var n: Node = dynamic_nodes[child_id]
		if is_instance_valid(n):
			var scene_id: int = int(n.get_meta(&"scene_id", -1))
			if scene_id >= 0: spawns.append([child_id, scene_id])

	var pairs: Array = []
	for cpid: int in _state_by_cpid:
		pairs.append([cpid, _state_by_cpid[cpid]])

	# Construir ops baseline
	var ops_named: Array = []
	for child_id: int in _baseline_ops_by_child:
		for e: Array in _baseline_ops_by_child[child_id]:
			if not e.is_empty():
				ops_named.append([child_id, StringName(e[0]), e[1] if e.size() > 1 else []])

	return { "spawns": spawns, "pairs": pairs, "despawns": [], "ops_named": ops_named }

# --- Utilidades ---

func _resolve_child(child_id: int) -> Node:
	if child_id <= STATIC_MAX:
		return id_to_node.get(child_id, null)
	return dynamic_nodes.get(child_id, null)
