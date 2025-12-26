extends CharacterBody3D
class_name NetPlayer

const SPEED = 6.5
const JUMP_VELOCITY = 5.5
const GRAVITY = 15.0

# Set by the server when spawning
@export var player_id: int = 1
@export var skin_id: int = 1:
	set(value):
		skin_id = value
		_update_skin()

@onready var input_synchronizer: MultiplayerSynchronizer = $InputSynchronizer
@onready var server_synchronizer: MultiplayerSynchronizer = $ServerSynchronizer
@onready var visuals: Node3D = $Visuals
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var gesture_manager: Node = $GestureManager

# Input properties (Synced Client -> Server)
@export var input_dir: Vector2 = Vector2.ZERO
@export var input_jump: bool = false
@export var cam_rotation: float = 0.0

# Auto-Jump (Copied from previous implementation)
var ray_knee: RayCast3D
var ray_floor: RayCast3D

# Spells
var spells = {
	"kinetic_pulse": preload("res://source/common/gameplay/combat/projectiles/projectile_kinetic.tscn"),
	"aegis": preload("res://source/common/gameplay/combat/projectiles/projectile_aegis.tscn"),
	"pyroclasm": preload("res://source/common/gameplay/combat/projectiles/projectile_pyroclasm.tscn"),
	"stasis": preload("res://source/common/gameplay/combat/projectiles/projectile_stasis.tscn")
}

func _enter_tree():
	var pid = str(name).to_int()
	set_multiplayer_authority(pid)
	if has_node("InputSynchronizer"):
		$InputSynchronizer.set_multiplayer_authority(pid)

func _ready():
	_update_skin()
	if is_multiplayer_authority() and multiplayer.get_unique_id() == str(name).to_int():
		if camera: camera.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		# Connect Gesture Manager signal

		# Connect Gesture Manager signal
		if gesture_manager:
			gesture_manager.spell_cast.connect(_on_gesture_cast)
	else:
		if camera: camera.current = false
		set_process_unhandled_input(false)

	_setup_auto_jump()

func _update_skin():
	if not is_inside_tree(): return
	if not visuals: return
	var mesh_instance = visuals.get_node_or_null("CharacterModel")
	if not mesh_instance: return

	var mat = StandardMaterial3D.new()
	match skin_id:
		0: mat.albedo_color = Color.RED
		1: mat.albedo_color = Color.GREEN
		2: mat.albedo_color = Color.BLUE
		_: mat.albedo_color = Color.WHITE

	mesh_instance.material_override = mat

func _on_gesture_cast(gesture_id: StringName, _aim_dir: Vector3):
	# Client detects gesture -> Send RPC to server to spawn projectile
	rpc_cast_spell.rpc_id(1, String(gesture_id), spring_arm.rotation.y)

@rpc("any_peer", "call_remote", "reliable")
func rpc_cast_spell(gesture_id: String, aim_yaw: float):
	if not multiplayer.is_server(): return

	print("Server: Casting spell %s" % gesture_id)

	if spells.has(gesture_id):
		var proj_scene = spells[gesture_id]
		var proj = proj_scene.instantiate()

		# Calculate spawn pos (offset forward)
		var forward = Vector3.FORWARD.rotated(Vector3.UP, aim_yaw)
		proj.position = global_position + Vector3(0, 1.0, 0) + (forward * 1.0)
		proj.direction = forward
		proj.owner_id = player_id

		get_parent().add_child(proj)

func _physics_process(delta):
	if multiplayer.is_server():
		_process_server_physics(delta)
	elif is_multiplayer_authority():
		_process_client_input()

func _process_client_input():
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	input_jump = Input.is_action_just_pressed("jump")
	cam_rotation = spring_arm.rotation.y

func _process_server_physics(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var direction = (Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, cam_rotation).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 10 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	if input_jump or (is_on_floor() and _check_auto_jump(direction)):
		velocity.y = JUMP_VELOCITY
		input_jump = false

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		spring_arm.rotation.x = clamp(spring_arm.rotation.x - event.relative.y * 0.005, -PI / 2.0, PI / 4.0)
		spring_arm.rotation.y -= event.relative.x * 0.005

func _setup_auto_jump() -> void:
	ray_knee = RayCast3D.new()
	ray_knee.position = Vector3(0, 0.5, 0)
	ray_knee.target_position = Vector3(0, 0, -0.6)
	ray_knee.enabled = true
	add_child(ray_knee)

	ray_floor = RayCast3D.new()
	ray_floor.position = Vector3(0, 0.1, -0.6)
	ray_floor.target_position = Vector3(0, -1.2, 0)
	ray_floor.enabled = true
	add_child(ray_floor)

func _check_auto_jump(move_dir: Vector3) -> bool:
	if velocity.y > 0 or move_dir.length() < 0.1: return false

	var local_dir = to_local(global_position + move_dir).normalized()
	ray_knee.target_position = local_dir * 0.6
	ray_floor.position = Vector3(0, 0.1, 0) + (local_dir * 0.6)

	ray_knee.force_raycast_update()
	ray_floor.force_raycast_update()

	if not ray_knee.is_colliding() and ray_floor.is_colliding():
		var hit_point = ray_floor.get_collision_point()
		var height_diff = hit_point.y - global_position.y
		if height_diff > -1.0 and height_diff < 0.5:
			return true
	return false
