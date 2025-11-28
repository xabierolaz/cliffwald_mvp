class_name EquipmentComponent
extends Node

# Componente simplificado para Cliffwald.
# Ya no gestiona lógica de armas (varitas son fijas).
# En el futuro gestionará armaduras/túnicas (GearItem).

@export var character: Node 
var _slots: Dictionary = {}

func _ready() -> void:
	pass

# Funciones 'dummy' para mantener compatibilidad si algún sistema viejo llama aquí
func can_use(_slot: StringName, _index: int) -> bool:
	return false

func equip(slot: StringName, item: Resource) -> bool:
	_slots[slot] = item
	print("Equipado cosmético en: ", slot)
	return true
	
func unequip(slot: StringName) -> void:
	_slots.erase(slot)
