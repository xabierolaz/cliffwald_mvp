class_name ScheduleResource
extends Resource

# 08:00 -> Desayuno (Todos al Gran Salón, a su mesa)
# 09:00 -> Clases (Ignis Y1 a Pociones, Axiom Y1 a Biblioteca)
# 13:00 -> Comida
# 20:00 -> Dormir

@export var schedule_data: Dictionary = {
	"08:00": {
		"group": "All_Students",
		"action": "Eat",
		"target": "Great_Hall"
	},
	"09:00_1": {
		"group": "Ignis_Year1",
		"action": "Class",
		"target": "Potions"
	},
	"09:00_2": {
		"group": "Axiom_Year1",
		"action": "Class",
		"target": "Library"
	},
	"13:00": {
		"group": "All_Students",
		"action": "Eat",
		"target": "Great_Hall"
	},
	"20:00": {
		"group": "All_Students",
		"action": "Sleep",
		"target": "Dormitory"
	}
}

func get_events_at_time(time_str: String) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for key in schedule_data:
		if key == time_str or key.begins_with(time_str + "_"):
			events.append(schedule_data[key])
	return events
