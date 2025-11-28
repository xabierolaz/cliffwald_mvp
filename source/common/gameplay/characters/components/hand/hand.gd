class_name Hand
extends Node3D # Cambiado de Sprite2D a Node3D

# Mantenemos los Enums para no romper otros scripts que los usan
enum Sides { LEFT, RIGHT }
enum Status { IDLE, GRAB, PULL }
enum Types { HUMAN, BROWN, ORC, GOBLIN }

@export var side: Sides = Sides.LEFT
@export var status: Status = Status.IDLE
@export var type: Types = Types.HUMAN

func _init() -> void:
	pass

# Funciones vacías por compatibilidad si algún otro script las llama
func _update_hands() -> void:
	pass

func _set_type(new_type: Types) -> void:
	type = new_type
