extends Control

@onready var time_label: Label = $TimeLabel

func _ready():
	# Update initially
	_update_label(TimeManager.current_game_hour, TimeManager.current_game_minute)
	
	# Connect to global time signal
	TimeManager.time_updated.connect(_update_label)

func _update_label(hour: int, minute: int):
	time_label.text = "%02d:%02d" % [hour, minute]