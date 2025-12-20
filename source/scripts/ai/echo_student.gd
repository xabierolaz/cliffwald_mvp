class_name EchoStudent
extends BaseStudent

@export var skin_color: BaseStudent.SkinColor = BaseStudent.SkinColor.RED
@export var nickname: String = "Student"

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_activity: String = ""

# Schedule Definition: Ordered by hour
var daily_schedule = [
	{ "hour": 0, "activity": "Sleep", "target": "DormitoryIgnis", "type": "slot" },
	{ "hour": 8, "activity": "Breakfast", "target": "GreatHall", "type": "slot" },
	{ "hour": 9, "activity": "Class", "target": "Classroom", "type": "slot" },
	{ "hour": 13, "activity": "Lunch", "target": "GreatHall", "type": "slot" },
	{ "hour": 14, "activity": "FreeTime", "target": "Wander", "type": "poi" }, # Special handling for wander
	{ "hour": 19, "activity": "Dinner", "target": "GreatHall", "type": "slot" },
	{ "hour": 20, "activity": "FreeTime", "target": "Wander", "type": "poi" },
	{ "hour": 21, "activity": "Sleep", "target": "DormitoryIgnis", "type": "slot" }
]

func _ready():
	super._ready()
	
	if not red_texture:
		red_texture = load("res://assets/characters/player/GodotRobotPaletteSwap/GodotRedPalette.png")
	
	_setup_visuals()
	
	# Initial position randomization
	position.x += randf_range(-1, 1)
	position.z += randf_range(-1, 1)
	
	# Connect to time system
	TimeManager.time_updated.connect(_check_schedule)
	
	# NAVIGATION CONFIGURATION FOR CORRIDORS
	# Allow "cutting corners": Switch to next waypoint when within 2.5m (Aggressive corner cutting)
	nav_agent.path_desired_distance = 2.5
	# But be precise when reaching the final target (bed/desk)
	nav_agent.target_desired_distance = 0.5
	
	# Connect for RVO Avoidance
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	
	# Wait for scene to be ready to find POIs
	await get_tree().process_frame
	_check_schedule(TimeManager.current_game_hour, TimeManager.current_game_minute)

func _setup_visuals():
	set_nickname(nickname)
	set_skin(skin_color)

func _check_schedule(hour: int, _minute: int):
	# Find current schedule block
	var current_block = daily_schedule[0]
	for block in daily_schedule:
		if hour >= block.hour:
			current_block = block
		else:
			break
	
	if current_block.activity != current_activity:
		current_activity = current_block.activity
		var target_name = current_block.target
		
		# Resolve Wander target dynamically
		if target_name == "Wander":
			target_name = "POI_Wander_" + str(randi() % 2 + 1)
			
		if current_block.type == "slot":
			_go_to_assigned_slot(target_name)
		else:
			_go_to_poi(target_name)

func _go_to_assigned_slot(room_name: String):
	var root = get_tree().get_current_scene()
	# Find the room instance first (e.g. GreatHall node)
	var room = root.find_child(room_name, true, false)
	
	if room:
		var slot_name = "Slot_" + get_student_id() # e.g. Slot_Ignis_Y1_01
		var slot = room.find_child(slot_name, true, false)
		
		if slot:
			nav_agent.target_position = slot.global_position
			# print(nickname, " heading to slot ", slot_name, " in ", room_name)
		else:
			print("Warning: Echo ", nickname, " could not find slot ", slot_name, " in ", room_name)
	else:
		print("Warning: Room ", room_name, " not found")

func _go_to_poi(poi_name: String):
	# Find POI in the level
	var root = get_tree().get_current_scene()
	var poi_node = root.find_child(poi_name, true, false)
	
	if poi_node:
		var target_pos = poi_node.global_position
		# Add some randomness to target so they don't stack
		target_pos.x += randf_range(-2, 2)
		target_pos.z += randf_range(-2, 2)
		
		nav_agent.target_position = target_pos
		# print(nickname, " heading to ", poi_name)

func _physics_process(delta):
	# Apply gravity only if in air (nav agent works on ground)
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if nav_agent.is_navigation_finished():
		# If finished, just stop (or run idle animation via _on_velocity_computed with 0 vector)
		nav_agent.set_velocity(Vector3.ZERO)
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = nav_agent.get_next_path_position()
	
	var new_velocity: Vector3 = next_path_position - current_agent_position
	new_velocity.y = 0
	new_velocity = new_velocity.normalized() * NORMAL_SPEED
	
	# Request safe velocity (Avoidance)
	nav_agent.set_velocity(new_velocity)

func _on_velocity_computed(safe_velocity: Vector3):
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z
	
	# Rotate towards movement
	if velocity.length() > 0.1:
		var look_dir = Vector2(velocity.z, velocity.x)
		rotation.y = lerp_angle(rotation.y, look_dir.angle(), 0.15) # Smooth rotation
	
	if _body and _body.has_method("animate"):
		_body.animate(velocity)
		
	move_and_slide()

func take_damage(_amount: int):
	print(nickname, " says: Ouch!")
