@icon("res://assets/node_icons/blue/icon_door.png")
class_name Warper
extends Area3D # <--- CAMBIO: De InteractionArea (2D) a Area3D

@export var target_instance: InstanceResource
@export var warper_id: int = 0
@export var target_id: int = 0

func _ready() -> void:
	monitorable = false
	monitoring = true
	# Capas de colisión: Detectar Player (Layer 2)
	collision_mask = 2 
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		print("Jugador entró en Warper: ", warper_id)
		# Aquí iría la lógica de cambio de mapa
