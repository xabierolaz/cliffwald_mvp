class_name BaseStudent
extends CharacterBody3D

enum SkinColor { BLUE, YELLOW, GREEN, RED }
enum House { IGNIS, AXIOM, VESPER }

# Identity
@export var house: House = House.IGNIS
@export var year: int = 1
@export var student_index: int = 1 # 1 to 7

# Shared Constants
const NORMAL_SPEED = 6.0
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 10

# Shared References (Child nodes must follow "3DGodotRobot" naming convention)
@onready var _body: Node3D = $"3DGodotRobot"
@onready var _bottom_mesh: MeshInstance3D
@onready var _chest_mesh: MeshInstance3D
@onready var _face_mesh: MeshInstance3D
@onready var _limbs_head_mesh: MeshInstance3D

@onready var nickname_label: Label3D = $PlayerNick/Nickname

# Shared Properties
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Skin Resources (Ideally these should be in a Resource file, but kept here for now)
@export_category("Skin Colors")
@export var blue_texture : CompressedTexture2D
@export var yellow_texture : CompressedTexture2D
@export var green_texture : CompressedTexture2D
@export var red_texture : CompressedTexture2D

func _ready():
	_setup_mesh_references()
	
	if _body and "_character" in _body:
		_body._character = self
	
func _setup_mesh_references():
	if _body:
		# Using relative paths from the body node
		_bottom_mesh = _body.get_node("RobotArmature/Skeleton3D/Bottom")
		_chest_mesh = _body.get_node("RobotArmature/Skeleton3D/Chest")
		_face_mesh = _body.get_node("RobotArmature/Skeleton3D/Face")
		_limbs_head_mesh = _body.get_node("RobotArmature/Skeleton3D/Llimbs and head")

func set_skin(skin_enum: Character.SkinColor) -> void:
	var texture = _get_texture_from_enum(skin_enum)
	
	_set_mesh_texture(_bottom_mesh, texture)
	_set_mesh_texture(_chest_mesh, texture)
	_set_mesh_texture(_face_mesh, texture)
	_set_mesh_texture(_limbs_head_mesh, texture)

func _get_texture_from_enum(skin_color: Character.SkinColor) -> CompressedTexture2D:
	match skin_color:
		Character.SkinColor.BLUE: return blue_texture
		Character.SkinColor.GREEN: return green_texture
		Character.SkinColor.RED: return red_texture
		Character.SkinColor.YELLOW: return yellow_texture
		_: return blue_texture

func _set_mesh_texture(mesh_instance: MeshInstance3D, texture: Texture2D) -> void:
	if mesh_instance:
		var material := mesh_instance.get_surface_override_material(0)
		# Create new material if it doesn't exist, or duplicate existing
		if material:
			var new_material = material.duplicate()
			new_material.albedo_texture = texture
			mesh_instance.set_surface_override_material(0, new_material)
		elif texture:
			var new_material = StandardMaterial3D.new()
			new_material.albedo_texture = texture
			mesh_instance.set_surface_override_material(0, new_material)

func set_nickname(text: String):
	if nickname_label:
		nickname_label.text = text

func get_student_id() -> String:
	var h_str = House.keys()[house].capitalize() # "Ignis"
	return "%s_Y%d_%02d" % [h_str, year, student_index]

func is_running() -> bool:
	return false
