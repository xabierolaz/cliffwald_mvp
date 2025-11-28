@tool
class_name Map
extends Node3D

enum AOIMode { NONE, GRID }
enum ZoneMode { SAFE, PVP }

# --- CONFIGURACIÓN DEL MAPA ---
@export_category("Map Settings")
@export_group("Area Of Interest (Network)")
@export var aoi_mode: AOIMode = AOIMode.NONE
@export var aoi_cell_size: Vector2i = Vector2i(250, 250)
@export var aoi_visible_radius_cells: int = 2

@export_group("Default Rules")
# Esta es la ÚNICA regla que importa ahora.
# SAFE = Todo el mapa es seguro.
# PVP = Todo el mapa es combate.
@export var default_mode: ZoneMode = ZoneMode.SAFE
@export var zone_cell_size: Vector2i = Vector2i(64, 64)
@export var map_background_color := Color(0.1, 0.2, 0.4)

@export_group("Dependencies")
@export var replicated_props_container: ReplicatedPropsContainer

var _spawn_points: Dictionary = {}

func _ready() -> void:
	if Engine.is_editor_hint(): 
		return
	
	if OS.has_feature("client") or not OS.has_feature("dedicated_server"):
		RenderingServer.set_default_clear_color(map_background_color)
	
	_scan_spawn_points()

func _scan_spawn_points() -> void:
	_spawn_points.clear()
	for child in get_children():
		if "warper_id" in child:
			_spawn_points[child.warper_id] = child
		elif child is Marker3D:
			_spawn_points[child.name] = child

func get_spawn_position(id: Variant = 0) -> Vector3:
	if _spawn_points.has(id):
		return _spawn_points[id].global_position
	if not _spawn_points.is_empty():
		return _spawn_points.values()[0].global_position
	return Vector3(0, 5.0, 0)

# MODIFICADO: Ya no busca zonas. Devuelve lista vacía directamente.
func get_zone_authoring_data() -> Dictionary:
	return {
		"default_mode": default_mode,
		"zone_cell_size": zone_cell_size,
		"patches": [] # Siempre vacío, ignoramos los parches.
	}