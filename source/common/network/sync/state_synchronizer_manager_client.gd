class_name StateSynchronizerManagerClient
extends Node

## Gestor de cliente: Recibe mensajes y aplica cambios a entidades locales y props.

@export var server_peer_id: int = 1 

var entities: Dictionary = {}   # eid -> StateSynchronizer
var _pending_baseline: Dictionary = {}
var _pending_deltas: Dictionary = {}

var containers: Dictionary = {} # cid -> ReplicatedPropsContainer
var _pending_prop_blocks: Array = []

func _ready() -> void:
	PathRegistry.ensure_initialized()

func add_entity(eid: int, sync: StateSynchronizer) -> void:
	assert(sync != null)
	entities[eid] = sync

	# Procesar datos pendientes si llegaron antes que la entidad
	if _pending_baseline.has(eid):
		sync.apply_baseline(_pending_baseline[eid])
		_pending_baseline.erase(eid)

	if _pending_deltas.has(eid):
		for pairs: Array in _pending_deltas[eid]:
			sync.apply_delta(pairs)
		_pending_deltas.erase(eid)

func remove_entity(eid: int) -> void:
	entities.erase(eid)
	_pending_baseline.erase(eid)
	_pending_deltas.erase(eid)

func add_container(cid: int, container: ReplicatedPropsContainer) -> void:
	containers[cid] = container
	# Procesar props pendientes
	# (Lógica simplificada de flush)
	pass

func send_my_delta(eid: int, pairs: Array) -> void:
	if pairs.is_empty(): return
	var blocks: Array = [ { "eid": eid, "pairs": pairs } ]
	var bytes: PackedByteArray = WireCodec.encode_delta(blocks)
	on_client_delta.rpc_id(server_peer_id, bytes)

# --- RPC Handlers ---

@rpc("authority", "reliable")
func on_bootstrap(payload: PackedByteArray) -> void:
	var msg: Dictionary = WireCodec.decode_bootstrap(payload)
	var objects: Array = msg.get("objects", [])
	
	for obj: Dictionary in objects:
		var eid: int = int(obj.get("eid", -1))
		var pairs: Array = obj.get("pairs", [])
		var syn: StateSynchronizer = entities.get(eid, null)
		if syn == null:
			_pending_baseline[eid] = pairs
		else:
			syn.apply_baseline(pairs)

@rpc("authority", "reliable")
func on_state_delta(bytes: PackedByteArray) -> void:
	var blocks: Array = WireCodec.decode_delta(bytes)
	for blk: Dictionary in blocks:
		var eid: int = int(blk.get("eid", -1))
		var pairs: Array = blk.get("pairs", [])
		NetDiagnostics.log("delta eid=%d pairs=%d" % [eid, pairs.size()])
		var syn: StateSynchronizer = entities.get(eid, null)
		if syn == null:
			var q: Array = _pending_deltas.get(eid, [])
			q.append(pairs)
			_pending_deltas[eid] = q
		else:
			syn.apply_delta(pairs)

@rpc("authority", "reliable")
func on_props_bootstrap(bytes: PackedByteArray) -> void:
	var msg: Dictionary = WireCodec.decode_container_block_named(bytes)
	var cid: int = int(msg.get("eid", -1))
	var cont: ReplicatedPropsContainer = containers.get(cid, null)
	if cont:
		cont.apply_spawns(msg.get("spawns", []))
		cont.apply_pairs(msg.get("pairs", []))
		cont.apply_despawns(msg.get("despawns", []))

@rpc("authority", "reliable")
func on_props_delta(bytes: PackedByteArray) -> void:
	on_props_bootstrap(bytes) # Misma lógica para este MVP

@rpc("any_peer", "reliable")
func on_client_delta(_bytes: PackedByteArray) -> void:
	pass
