class_name ScheduleManager
extends Node

# The current game time in "HH:MM" format
var current_time_str: String = "08:00"
var timer: float = 0.0
var time_scale: float = 60.0

# DEBUG MODE: 0.1s per minute (1 hour = 6 seconds)
const SECONDS_PER_GAME_MINUTE = 0.1

var _hour: int = 8
var _minute: int = 0

signal time_changed(new_time: String)
signal schedule_event(event_data: Dictionary)

var schedule_res: ScheduleResource
var npc_scene = preload("res://source/common/gameplay/characters/npc/npc_simple.tscn")

func _ready() -> void:
	add_to_group("ScheduleManager")
	schedule_res = ScheduleResource.new()
	print("ScheduleManager initialized. Start time: ", current_time_str)

	if multiplayer.is_server():
		_spawn_student_population()

func _spawn_student_population() -> void:
	print("Spawning 84 Students...")
	var houses = ["Ignis", "Axiom", "Vesper"]
	var parent = get_parent()

	for house in houses:
		for year in range(1, 5): # 1 to 4
			for idx in range(1, 8): # 1 to 7
				var npc = npc_scene.instantiate()
				npc.name = "Student_%s_Y%d_%02d" % [house, year, idx]
				npc.doctrine = house
				npc.year = year
				npc.student_index = idx
				npc.position = Vector3(randf_range(-15, 15), 0.5, randf_range(-20, 20))
				parent.call_deferred("add_child", npc)
	print("Students spawned.")

func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	timer += delta
	if timer >= SECONDS_PER_GAME_MINUTE:
		timer -= SECONDS_PER_GAME_MINUTE
		_advance_minute()

func _advance_minute() -> void:
	_minute += 1
	if _minute >= 60:
		_minute = 0
		_hour += 1
		if _hour >= 24:
			_hour = 0

	var time_str = "%02d:%02d" % [_hour, _minute]
	if time_str != current_time_str:
		current_time_str = time_str
		time_changed.emit(current_time_str)
		_check_schedule()

func _check_schedule() -> void:
	var events = schedule_res.get_events_at_time(current_time_str)
	for ev in events:
		print("Executing Schedule Event: ", ev)
		schedule_event.emit(ev)
