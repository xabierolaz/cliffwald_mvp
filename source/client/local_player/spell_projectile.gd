extends Node3D

@export var speed: float = 18.0
@export var lifetime: float = 2.0
var direction: Vector3 = Vector3.ZERO
enum Shape { TRIANGLE, CIRCLE, SQUARE }
@export var shape_type: Shape = Shape.CIRCLE

func _ready() -> void:
	_configure_mesh()
	set_physics_process(true)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if direction != Vector3.ZERO:
		global_translate(direction.normalized() * speed * delta)


func set_shape_from_gesture(gesture_id: String) -> void:
	match gesture_id:
		"triangle":
			shape_type = Shape.TRIANGLE
		"square":
			shape_type = Shape.SQUARE
		_:
			shape_type = Shape.CIRCLE
	_configure_mesh()


func _configure_mesh() -> void:
	var mesh_instance: MeshInstance3D = $MeshInstance3D
	if not mesh_instance:
		return

	var new_mesh: Mesh

	match shape_type:
		Shape.TRIANGLE:
			# Triangle gesture -> Cone
			var cone = CylinderMesh.new()
			cone.top_radius = 0.0 # Cone tip
			cone.bottom_radius = 0.35
			cone.height = 0.8
			cone.radial_segments = 16
			new_mesh = cone
			_set_color(Color(1, 0.6, 0.2))
		Shape.SQUARE:
			# Square gesture -> Cube
			var box = BoxMesh.new()
			box.size = Vector3(0.6, 0.6, 0.6)
			new_mesh = box
			_set_color(Color(0.2, 0.8, 1))
		Shape.CIRCLE:
			# Circle gesture -> Sphere
			var sphere = SphereMesh.new()
			sphere.radius = 0.4
			sphere.height = 0.8
			sphere.radial_segments = 16
			sphere.rings = 8
			new_mesh = sphere
			_set_color(Color(0.8, 0.2, 1))

	mesh_instance.mesh = new_mesh

func _set_color(col: Color) -> void:
	var mesh_instance: MeshInstance3D = $MeshInstance3D
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 2.0
	mesh_instance.material_override = mat
