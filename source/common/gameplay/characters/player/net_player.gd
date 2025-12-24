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

# Security: Rate limiting
var last_cast_time: int = 0

# Spells
var spells = {
	"kinetic_pulse": preload("res://source/common/gameplay/combat/projectiles/projectile_kinetic.tscn"),
	"aegis": preload("res://source/common/gameplay/combat/projectiles/projectile_aegis.tscn"),
	"pyroclasm": preload("res://source/common/gameplay/combat/projectiles/projectile_pyroclasm.tscn"),
	"stasis": preload("res://source/common/gameplay/combat/projectiles/projectile_stasis.tscn")
}

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	_update_skin()
	if is_multiplayer_authority() and multiplayer.get_unique_id() == str(name).to_int():
		if camera: camera.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
	rpc_cast_spell.rpc_id(1, String(gesture_id), spring_arm.rotation.y)

@rpc("any_peer", "call_remote", "reliable")
func rpc_cast_spell(gesture_id: String, aim_yaw: float):
	if not multiplayer.is_server(): return

	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != player_id:
		print("Security Alert: Peer %d tried to cast spell for Player %d" % [sender_id, player_id])
		return

	var current_time = Time.get_ticks_msec()
	if current_time - last_cast_time < 500:
		return
	last_cast_time = current_time

	print("Server: Casting spell %s" % gesture_id)

	if spells.has(gesture_id):
		var proj_scene = spells[gesture_id]
		var proj = proj_scene.instantiate()
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

func _setup_auto_jump():
	# Stub
	pass

# -------------------------------------------------------------------------
# MOVEMENT LOGIC IMPLEMENTATION
# -------------------------------------------------------------------------

func _process_client_input():
	# 1. Collect Input
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	input_jump = Input.is_action_pressed("jump")
	cam_rotation = spring_arm.rotation.y

	# 2. Local Movement Prediction (optional but recommended)
	# For now, we trust the server authoritative position via MultiplayerSynchronizer
	# but we can apply inputs locally for smoothness if needed.
	# For "Simple" networking, usually we just send inputs and wait for server transform sync.
	pass

func _process_server_physics(delta):
	# 1. Apply Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# 2. Handle Jump
	if input_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY
		# Reset jump so they have to press again (or keep if auto-bunnyhop allowed)
		# Usually better to check "Just Pressed" but input_jump is a bool state here.
		# Ideally we sync "Jump" as an event or just state.
		# If it's a state, they jump as long as held and on floor (bunny hop).

	# 3. Get Movement Direction relative to Camera
	# input_dir is relative to camera view
	var direction = (Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, cam_rotation).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Rotate character to face movement direction
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# 4. Move
	move_and_slide()
