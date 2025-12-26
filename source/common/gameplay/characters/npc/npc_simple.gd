extends CharacterBody3D
class_name NpcSimple

@export var doctrine: String = "Ignis"
@export var year: int = 1
@export var student_index: int = 1

func _ready():
	print("NPC Simple Ready: ", name)
