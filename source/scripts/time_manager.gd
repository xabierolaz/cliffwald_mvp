extends Node

signal time_updated(hour: int, minute: int)

const GAME_DAY_SECONDS: float = 120.0 # 2 minutes real time = 24 hours game time
const GAME_HOURS_IN_DAY: float = 24.0
const GAME_MINUTES_IN_HOUR: float = 60.0

var current_game_hour: int = 0
var current_game_minute: int = 0
var _time_accumulator: float = 35.0 # Starts at 07:00

func _ready():
	# Initial update
	_update_time_from_accumulator()

func _process(delta):
	_time_accumulator += delta
	
	if _time_accumulator >= GAME_DAY_SECONDS:
		_time_accumulator -= GAME_DAY_SECONDS
	
	_update_time_from_accumulator()

func _update_time_from_accumulator():
	var day_ratio = _time_accumulator / GAME_DAY_SECONDS
	var total_minutes = day_ratio * GAME_HOURS_IN_DAY * GAME_MINUTES_IN_HOUR
	
	var new_hour = int(total_minutes / GAME_MINUTES_IN_HOUR)
	var new_minute = int(total_minutes) % int(GAME_MINUTES_IN_HOUR)
	
	if new_hour != current_game_hour or new_minute != current_game_minute:
		current_game_hour = new_hour
		current_game_minute = new_minute
		time_updated.emit(current_game_hour, current_game_minute)

func get_time_string() -> String:
	return "%02d:%02d" % [current_game_hour, current_game_minute]
