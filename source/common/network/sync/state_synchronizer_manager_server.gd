class_name StateSynchronizerManagerServer
extends Node

## Gestor de estado del Servidor.
## Coordina la sincronización de Entidades (Jugadores/NPCs) y Props (Objetos del mapa).

enum AOIMode { NONE, GRID }

@export var aoi_mode: AOIMode = AOIMode.NONE
@export var aoi_grid_size: Vector2i = Vector2i(512, 512)
@export var visible_grid_size: int = 2

@export var send_rate_hz_entities: int = 20
@export var send_rate_hz_props: int = 10
@export var enable_process_tick: bool = true
@export var owner_predict_suppress_ms: int = 120

var _accum_ent := 0.0
var _accum_props := 0.0

class PeerState:
	var known_version: int = 0

var entities: Dictionary = {}   # eid -> StateSynchronizer
var _owner_recent: Dictionary = {}
var peers: Dictionary = {}      # peer_id -> PeerState
var containers: Dictionary = {} # cid -> ReplicatedPropsContainer

# ZONING
var zone_cells: Dictionary = {}
var zone_cell_size: Vector2i = Vector2i(64, 64)
var zone_default_flags: int = 0
var eid_zone_last_change_ms: Dictionary = {}
var zone_hysteresis_ms: int = 500

func _ready() -> void:
	PathRegistry.ensure_initialized()
	set_process(enable_process_tick)

func _process(delta: float) -> void:
	if not enable_process_tick: return
	_accum_ent += delta
	_accum_props += delta

	var eint: float = 1.0 / float(send_rate_hz_entities)
	var pint: float = 1.0 / float(send_rate_hz_props)

	if _accum_ent >= eint:
		_accum_ent = fmod(_accum_ent, eint)
		_send_entity_deltas_one_shot()

	if _accum_props >= pint:
		_accum_props = fmod(_accum_props, pint)
		_send_container_deltas_one_shot()

# --- Inicialización del Mapa (Aquí conecta con tu map.gd) ---

func init_zones_from_map(map: Map) -> void:
	var data: Dictionary = map.get_zone_authoring_data()
	zone_cell_size = data.get("zone_cell_size", Vector2i(64, 64))
	
	# Leemos el modo por defecto (SAFE o PVP)
	var default_mode_enum: int = data.get("default_mode", Map.ZoneMode.SAFE)
	# Bit 0: Mode (0=Safe, 1=PvP). Bits 1+: Modifiers
	zone_default_flags = default_mode_enum 

	# Si hay parches (tu lista vacía), intentamos construirlos. Si no, no pasa nada.
	build_zone_grid(data)

func build_zone_grid(data: Dictionary) -> void:
	var patches: Array = data.get("patches", [])
	# Si la lista está vacía, simplemente terminamos y zone_cells queda vacío.
	if patches.is_empty():
		return
		
	patches.sort_custom(func(a, b): return a.get("zone_priority", 0) < b.get("zone_priority", 0))
	
	for patch: Dictionary in patches:
		# Lógica de construcción de polígonos (se ejecuta solo si habilitas zonas en el futuro)
		pass 

func update_zone_flags_for_entity(entity_id: int) -> void:
	var entity: Node = entities[entity_id].root_node as Node
	if not entity: return
	
	# Si no hay celdas de zona definidas, usamos el flag por defecto para todo el mapa.
	if zone_cells.is_empty():
		entity.zone_flags = zone_default_flags
		return
	
	# Lógica avanzada de zonas (se omite si zone_cells es vacío)
	pass

# --- Gestión de Entidades (Jugadores) ---

func add_entity(eid: int, sync: StateSynchronizer) -> void:
	assert(sync != null)
	entities[eid] = sync
	update_zone_flags_for_entity(eid) # Asigna flags PvP/Safe al nacer
	sync.mark_many_by_id(sync.capture_baseline(), false)

func remove_entity(eid: int) -> void:
	entities.erase(eid)

func register_peer(peer_id: int) -> void:
	if peers.has(peer_id): return
	var ps: PeerState = PeerState.new()
	peers[peer_id] = ps
	send_bootstrap(peer_id)

func unregister_peer(peer_id: int) -> void:
	peers.erase(peer_id)

# --- Props / Containers ---

func add_container(cid: int, container: ReplicatedPropsContainer) -> void:
	# Register a props container so its deltas are included in ticks/bootstraps.
	containers[cid] = container

# --- Networking (Deltas & Bootstrap) ---

func _send_entity_deltas_one_shot() -> void:
	if peers.is_empty(): return
	
	var changed_pairs: Dictionary = {}
	for eid: int in entities:
		var pairs: Array = entities[eid].collect_dirty_pairs()
		if not pairs.is_empty(): changed_pairs[eid] = pairs

	if changed_pairs.is_empty(): return

	# Pre-codificar bloques
	var block_bytes_by_eid: Dictionary = {}
	for eid in changed_pairs:
		block_bytes_by_eid[eid] = WireCodec.encode_entity_block(eid, changed_pairs[eid])

	# Enviar a peers
	for peer_id: int in peers:
		var blocks_for_peer: Array = []
		# Aquí iría la lógica AOI. Por ahora enviamos todo.
		for eid in changed_pairs:
			blocks_for_peer.append(block_bytes_by_eid[eid])
		
		if not blocks_for_peer.is_empty():
			on_state_delta.rpc_id(peer_id, WireCodec.assemble_delta_from_blocks(blocks_for_peer))

func _send_container_deltas_one_shot() -> void:
	if peers.is_empty(): return
	var cont_blocks: Array = []
	for cid: int in containers:
		var out: Dictionary = containers[cid].collect_container_outgoing_and_clear()
		if out.values().any(func(x): return not x.is_empty()):
			cont_blocks.append(WireCodec.encode_container_block_named(cid, out.spawns, out.pairs, out.despawns, out.ops_named))
	
	if cont_blocks.is_empty(): return
	for peer_id in peers:
		for bb in cont_blocks:
			on_props_delta.rpc_id(peer_id, bb)

func send_bootstrap(peer_id: int) -> void:
	var objects: Array = []
	for eid: int in entities:
		var pairs: Array = entities[eid].capture_baseline()
		if not pairs.is_empty(): objects.append({ "eid": eid, "pairs": pairs })

	# Enviar el mapa completo de PathRegistry para que cliente/servidor compartan tipos.
	var map_updates: Array = PathRegistry.get_full_map_updates()
	var payload: PackedByteArray = WireCodec.encode_bootstrap(map_updates, objects)
	on_bootstrap.rpc_id(peer_id, payload)
	
	# Bootstrap props
	for cid: int in containers:
		var blk: Dictionary = containers[cid].capture_bootstrap_block()
		on_props_bootstrap.rpc_id(peer_id, WireCodec.encode_container_block_named(cid, blk.spawns, blk.pairs, blk.despawns, blk.ops_named))

# --- RPCs (Empty on server) ---
@rpc("authority", "reliable") func on_bootstrap(_p: PackedByteArray) -> void: pass
@rpc("authority", "reliable") func on_state_delta(_b: PackedByteArray) -> void: pass
@rpc("authority", "reliable") func on_props_bootstrap(_b: PackedByteArray) -> void: pass
@rpc("authority", "reliable") func on_props_delta(_b: PackedByteArray) -> void: pass

@rpc("any_peer", "reliable")
func on_client_delta(bytes: PackedByteArray) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	var blocks: Array = WireCodec.decode_delta(bytes)
	if blocks.is_empty(): return
	var first: Dictionary = blocks[0]
	var eid: int = int(first.get("eid", sender))
	
	# Seguridad: Solo el dueño puede mover su avatar
	if eid != sender: return 
	
	var pairs: Array = first.get("pairs", [])
	var syn: StateSynchronizer = entities.get(eid, null)
	if syn and not pairs.is_empty():
		syn.apply_delta(pairs)
		syn.mark_many_by_id(pairs, false) # Echo back
