extends Node
## Events Autoload (only for the client side)
## Should be removed on non-client exports.


# CORRECCIÓN: Usamos CharacterBody3D para compatibilidad con InstanceClient y evitar ciclos
signal local_player_ready(local_player: CharacterBody3D)

# CORRECCIÓN: Tipo base genérico
var local_player: CharacterBody3D

var stats: DataDict = DataDict.new()
var settings: DataDict = DataDict.new()
var quick_slots: DataDict = DataDict.new()


func _ready() -> void:
	# Suscripción a estadísticas (se mantiene igual, es agnóstico a 2D/3D)
	InstanceClient.subscribe(&"stats.get", func(data: Dictionary):
		stats.data.merge(data, true)
	)


class DataDict:
	signal data_changed(property: Variant, value: Variant)

	var data: Dictionary

	func _set(property: StringName, value: Variant) -> bool:
		if property == &"data":
			return false
		data[property] = value
		data_changed.emit(property, value)
		return true

	func set_key(key: Variant, value: Variant) -> void:
		data.set(key, value)
		data_changed.emit(key, value)

	func get_key(property: Variant, default: Variant = null) -> Variant:
		return data.get(property, default)
