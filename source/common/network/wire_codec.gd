class_name WireCodec
extends Node

static func _new_buff() -> StreamPeerBuffer:
	var stream_peer_buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	stream_peer_buffer.big_endian = false
	return stream_peer_buffer

static func _from_bytes(bytes: PackedByteArray) -> StreamPeerBuffer:
	var stream_peer_buffer: StreamPeerBuffer = StreamPeerBuffer.new()
	stream_peer_buffer.big_endian = false
	stream_peer_buffer.data_array = bytes
	return stream_peer_buffer

#region vector helpers
static func _put_vec2(spb: StreamPeerBuffer, v: Vector2) -> void:
	spb.put_float(v.x)
	spb.put_float(v.y)

static func _get_vec2(spb: StreamPeerBuffer) -> Vector2:
	var x: float = spb.get_float()
	var y: float = spb.get_float()
	return Vector2(x, y)

static func _put_vec3(spb: StreamPeerBuffer, v: Vector3) -> void:
	spb.put_float(v.x)
	spb.put_float(v.y)
	spb.put_float(v.z)

static func _get_vec3(spb: StreamPeerBuffer) -> Vector3:
	var x: float = spb.get_float()
	var y: float = spb.get_float()
	var z: float = spb.get_float()
	return Vector3(x, y, z)
#endregion

static func _encode_value(spb: StreamPeerBuffer, wire_type: int, value: Variant) -> void:
	match wire_type:
		Wire.Type.VARIANT: spb.put_var(value)
		Wire.Type.BOOL: spb.put_u8(int(bool(value)))
		Wire.Type.U8: spb.put_u8(int(value))
		Wire.Type.U16: spb.put_u16(int(value))
		Wire.Type.U32: spb.put_u32(int(value))
		Wire.Type.U64: spb.put_u64(int(value))
		Wire.Type.S8: spb.put_8(int(value))
		Wire.Type.S16: spb.put_16(int(value))
		Wire.Type.S32: spb.put_32(int(value))
		Wire.Type.S64: spb.put_64(int(value))
		Wire.Type.F16: spb.put_half(float(value))
		Wire.Type.F32: spb.put_float(float(value))
		Wire.Type.F64: spb.put_double(float(value))
		Wire.Type.STR_UTF8_U16:
			var bytes := String(value).to_utf8_buffer()
			spb.put_u16(bytes.size())
			spb.put_data(bytes)
		Wire.Type.STR_UTF8_U32: spb.put_utf8_string(String(value))
		Wire.Type.BYTES_U16:
			var b := value as PackedByteArray
			spb.put_u16(b.size())
			spb.put_data(b)
		Wire.Type.BYTES_U32:
			var b2 := value as PackedByteArray
			spb.put_u32(b2.size())
			spb.put_data(b2)
		Wire.Type.VEC2_F32: _put_vec2(spb, value as Vector2)
		Wire.Type.VEC3_F32: _put_vec3(spb, value as Vector3)
		_: spb.put_var(value)

static func _decode_value(spb: StreamPeerBuffer, wire_type: int) -> Variant:
	# Minimal decode with a single guard to avoid reading past buffer end.
	if spb.get_available_bytes() <= 0:
		return null
	match wire_type:
		Wire.Type.VARIANT:
			return spb.get_var()
		Wire.Type.BOOL:
			return spb.get_u8() != 0
		Wire.Type.U8:
			return spb.get_u8()
		Wire.Type.U16:
			return spb.get_u16()
		Wire.Type.U32:
			return spb.get_u32()
		Wire.Type.U64:
			return spb.get_u64()
		Wire.Type.S8:
			return spb.get_8()
		Wire.Type.S16:
			return spb.get_16()
		Wire.Type.S32:
			return spb.get_32()
		Wire.Type.S64:
			return spb.get_64()
		Wire.Type.F16:
			return spb.get_half()
		Wire.Type.F32:
			return spb.get_float()
		Wire.Type.F64:
			return spb.get_double()
		Wire.Type.STR_UTF8_U16:
			var n: int = spb.get_u16()
			var res: Array = spb.get_data(n)
			return res[1].get_string_from_utf8() if res[0] == OK else ""
		Wire.Type.STR_UTF8_U32:
			return spb.get_utf8_string()
		Wire.Type.BYTES_U16:
			var n: int = spb.get_u16()
			var res2: Array = spb.get_data(n)
			return res2[1] if res2[0] == OK else PackedByteArray()
		Wire.Type.BYTES_U32:
			var n: int = spb.get_u32()
			var res3: Array = spb.get_data(n)
			return res3[1] if res3[0] == OK else PackedByteArray()
		Wire.Type.VEC2_F32:
			return _get_vec2(spb)
		Wire.Type.VEC3_F32:
			return _get_vec3(spb)
		_:
			return spb.get_var()

static func encode_entity_block(eid: int, pairs: Array) -> PackedByteArray:
	var spb: StreamPeerBuffer = _new_buff()
	spb.put_u32(eid)
	var n: int = pairs.size()
	spb.put_u16(n)
	for i in range(n):
		var p: Array = pairs[i]
		var pid: int = int(p[0])
		spb.put_u16(pid)
		var wt: int = PathRegistry.type_of(pid)
		_encode_value(spb, wt, p[1])
	return spb.data_array

static func assemble_delta_from_blocks(blocks_bytes: Array) -> PackedByteArray:
	var spb: StreamPeerBuffer = _new_buff()
	spb.put_u16(blocks_bytes.size())
	for i in range(blocks_bytes.size()):
		var bb: PackedByteArray = blocks_bytes[i]
		spb.put_data(bb)
	return spb.data_array

static func encode_delta(blocks: Array) -> PackedByteArray:
	var spb := _new_buff()
	spb.put_u16(blocks.size())
	for block in blocks:
		var eid: int = int(block["eid"])
		spb.put_u32(eid)
		var pairs: Array = block.get("pairs", [])
		spb.put_u16(pairs.size())
		for p in pairs:
			var pid: int = int(p[0])
			spb.put_u16(pid)
			var wt: int = PathRegistry.type_of(pid)
			_encode_value(spb, wt, p[1])
	return spb.data_array

static func decode_delta(data: PackedByteArray) -> Array:
	var spb := _from_bytes(data)
	var block_count := spb.get_u16()
	var out: Array = []
	for _i in range(block_count):
		var eid := spb.get_u32()
		var pair_count := spb.get_u16()
		var pairs: Array = []
		for _j in range(pair_count):
			var pid := spb.get_u16()
			var wt := PathRegistry.type_of(pid)
			pairs.append([pid, _decode_value(spb, wt)])
		out.append({ "eid": eid, "pairs": pairs })
	return out

static func encode_bootstrap(map_updates: Array, objects: Array) -> PackedByteArray:
	var spb: StreamPeerBuffer = StreamPeerBuffer.new()
	spb.big_endian = false
	var updates_count: int = map_updates.size()
	spb.put_u16(updates_count)
	for i in range(updates_count):
		var u: Array = map_updates[i]
		var pid: int = int(u[0])
		var path: String = String(u[1])
		var wt: int = int(u[2])
		spb.put_u16(pid)
		spb.put_utf8_string(path)
		spb.put_u8(wt)
	var obj_count: int = objects.size()
	spb.put_u16(obj_count)
	for i in range(obj_count):
		var obj: Dictionary = objects[i]
		var eid: int = int(obj["eid"])
		spb.put_u32(eid)
		var pairs: Array = obj.get("pairs", [])
		var pair_count: int = pairs.size()
		spb.put_u16(pair_count)
		for j in range(pair_count):
			var p: Array = pairs[j]
			var pid2: int = int(p[0])
			spb.put_u16(pid2)
			var wt2: int = PathRegistry.type_of(pid2)
			_encode_value(spb, wt2, p[1])
	return spb.data_array

static func decode_bootstrap(data: PackedByteArray) -> Dictionary:
	var spb := _from_bytes(data)
	var updates_count := spb.get_u16()
	var updates: Array = []
	for _i in range(updates_count):
		var pid := spb.get_u16()
		var path := spb.get_utf8_string()
		var wt := spb.get_u8()
		updates.append([pid, path, wt])
	if updates.size() > 0:
		PathRegistry.apply_map_updates(updates)
	var obj_count := spb.get_u16()
	var objects: Array = []
	for _j in range(obj_count):
		var eid := spb.get_u32()
		var pair_count := spb.get_u16()
		var pairs: Array = []
		for _k in range(pair_count):
			var pid2 := spb.get_u16()
			var wt2 := PathRegistry.type_of(pid2)
			var v: Variant = _decode_value(spb, wt2)
			pairs.append([pid2, v])
		objects.append({ "eid": eid, "pairs": pairs })
	return { "map_updates": updates, "objects": objects }

static func encode_container_block_named(eid: int, spawns: Array, pairs: Array, despawns: Array, ops_named: Array) -> PackedByteArray:
	var spb := _new_buff()
	spb.put_u32(eid)
	spb.put_u16(spawns.size())
	for s in spawns:
		spb.put_u16(int(s[0]))
		spb.put_u16(int(s[1]))
	spb.put_u16(pairs.size())
	for p in pairs:
		var cpid := int(p[0])
		var fid := cpid & 0xFFFF
		spb.put_u32(cpid)
		_encode_value(spb, PathRegistry.type_of(fid), p[1])
	spb.put_u16(despawns.size())
	for d in despawns:
		spb.put_u16(int(d))
	spb.put_u16(ops_named.size())
	for o in ops_named:
		spb.put_u16(int(o[0]))
		spb.put_utf8_string(String(o[1]))
		var args: Array = o[2] as Array if o.size() else []
		spb.put_8(args.size())
		for a in args:
			spb.put_var(a)
	return spb.data_array

static func decode_container_block_named(data: PackedByteArray) -> Dictionary:
	var spb := _from_bytes(data)
	var eid := spb.get_u32()
	var spn_n := spb.get_u16()
	var spawns: Array = []
	for _i in range(spn_n):
		spawns.append([spb.get_u16(), spb.get_u16()])
	var pr_n := spb.get_u16()
	var pairs: Array = []
	for _j in range(pr_n):
		var cpid := spb.get_u32()
		var fid := cpid & 0xFFFF
		pairs.append([cpid, _decode_value(spb, PathRegistry.type_of(fid))])
	var dsp_n := spb.get_u16()
	var despawns: Array = []
	for _k in range(dsp_n):
		despawns.append(spb.get_u16())
	var op_n := spb.get_u16()
	var ops_named: Array = []
	for _m in range(op_n):
		var cid := spb.get_u16()
		var method := spb.get_utf8_string()
		var argc := spb.get_u8()
		var args: Array = []
		for _t in range(argc):
			args.append(spb.get_var())
		ops_named.append([cid, method, args])
	return { "eid": eid, "spawns": spawns, "pairs": pairs, "despawns": despawns, "ops_named": ops_named }

static func peek_container_block_named(data: PackedByteArray) -> Dictionary:
	var spb := StreamPeerBuffer.new()
	spb.data_array = data
	var eid := spb.get_u32()
	return { "eid": eid }
