class_name Item
extends Resource

# Definition
@export var item_name: StringName = &"ItemDefault"

# CAMBIO: Quitamos el preload de la imagen borrada y lo dejamos null
@export var item_icon: Texture2D = null

@export_multiline var description: String

# Trading / Economy
@export var can_trade: bool = false
@export var can_sell: bool = false
@export var minimum_price: int = 0

# Inventory
@export_range(0, 99, 1.0) var stack_limit: int = 0
@export var tags: PackedStringArray = []

func is_stackable() -> bool:
	return stack_limit != 1

@warning_ignore("unused_parameter")
func can_use(player: Node) -> bool:
	return false

@warning_ignore("unused_parameter")
func on_use(character: Node) -> void:
	pass

@warning_ignore("unused_parameter")
func can_equip(player: Node) -> bool:
	return false

@warning_ignore("unused_parameter")
func on_equip(character: Node) -> void:
	pass

@warning_ignore("unused_parameter")
func on_unequip(character: Node) -> void:
	pass
