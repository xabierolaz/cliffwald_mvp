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
@export var map_background_color := Color(0.1, 0.2, 0.4)

# Removed dependency on ReplicatedPropsContainer
# @export var replicated_props_container: Node

var _spawn_points: Dictionary = {}
var sun: DirectionalLight3D
var env: WorldEnvironment

func _ready() -> void:
	# Wait for CSG collision generation (avoids parsing RenderingServer meshes warning)
	if not Engine.is_editor_hint():
		await get_tree().physics_frame
		await get_tree().physics_frame

	# Auto-bake navigation for generated castle
	var nav_region = find_child("CastleGreybox", true, false)
	if nav_region and nav_region is NavigationRegion3D:
		print("Map: Baking navigation mesh for castle...")
		nav_region.bake_navigation_mesh(true)

	if Engine.is_editor_hint(): return

	sun = find_child("DirectionalLight3D")
	env = find_child("WorldEnvironment")

	_scan_spawn_points()

	# Connect to ScheduleManager
	var managers = get_tree().get_nodes_in_group("ScheduleManager")
	if not managers.is_empty():
		managers[0].time_changed.connect(_on_time_changed)

func _on_time_changed(time_str: String) -> void:
	# Parse HH:MM
	var parts = time_str.split(":")
	var hour = parts[0].to_int()
	var minute = parts[1].to_int()

	# Calculate day progress (0.0 to 1.0)
	# 06:00 = Sunrise (0.25)
	# 12:00 = Noon (0.5)
	# 18:00 = Sunset (0.75)
	# 00:00 = Midnight (0.0 / 1.0)

	var total_minutes = (hour * 60) + minute
	var progress = total_minutes / 1440.0

	if sun:
		# Rotate sun based on progress (360 degrees)
		# Noon (0.5) should be -90 degrees X rotation?
		# Standard Godot sun: -90 is Zenith.
		# Progress 0.0 (Midnight) -> Rotation X = 90 (Nadir)
		# Progress 0.5 (Noon) -> Rotation X = -90 (Zenith)
		var angle = (progress * 360.0) - 90.0
		sun.rotation_degrees.x = angle

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

func get_zone_authoring_data() -> Dictionary:
	return {}
