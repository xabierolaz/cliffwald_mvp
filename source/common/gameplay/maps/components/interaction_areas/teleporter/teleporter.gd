@tool
extends InteractionArea
class_name Teleporter

@export var one_way: bool = false
@export var target: Teleporter

# [3D FIX] Usar Vector3 en lugar de Vector2
@export var size: Vector3 = Vector3(1, 1, 1):
	set(value):
		size = value
		_update_shape()

func _ready():
	super._init() # Configurar capas de colisión desde la clase base
	_update_shape()

func _update_shape():
	var col = get_node_or_null("CollisionShape3D")
	if col and col.shape is BoxShape3D:
		col.shape.size = size
