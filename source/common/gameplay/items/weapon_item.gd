class_name WeaponItem
extends Item

# Varita puramente estética; no hay equipamiento ni lógica de combate basada en armas.
@export var wand_scene: PackedScene

func on_equip(_character: Node) -> void:
	pass


func on_unequip(_character: Node) -> void:
	pass
