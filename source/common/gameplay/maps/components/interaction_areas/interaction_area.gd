class_name InteractionArea
extends Area3D

signal player_entered_interaction_area(player: Node3D, interaction_area: InteractionArea)

func _init() -> void:
	body_entered.connect(_on_body_entered)
	collision_mask = 2
	monitorable = false
	monitoring = true

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		player_entered_interaction_area.emit(body, self)
