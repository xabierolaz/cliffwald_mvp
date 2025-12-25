class_name AbilitySystemComponent
extends Node

# Removed StateSynchronizer dependency
# @export var synchronizer: Node

var modifiers: Array[StatModifier]
var attributes: Attributes = Attributes.new()

class Attributes:
	var attributes: Dictionary
	var watchers: Dictionary

	func _set(property: StringName, value: Variant) -> bool:
		if not typeof(value) == TYPE_FLOAT:
			return false
		attributes[property] = value # Corrected syntax
		for watcher: Callable in watchers.get(property, []):
				watcher.call(value)
		return true

	func _get(property: StringName) -> Variant:
		return attributes.get(property, 0.0)

	func connect_watcher(property: StringName, to_connect: Callable) -> void:
		if watchers.has(property):
			watchers[property].append(to_connect)
		else:
			watchers[property] = [to_connect]
		to_connect.call(attributes.get(property, 0.0))

static func attribute_path(attribute_name: StringName) -> String:
	return "AbilitySystemComponent:attributes:%s" % attribute_name

func _ready() -> void:
	pass

func ensure_attribute(attribute_name: StringName, value: float) -> void:
	attributes._set(attribute_name, value)
	# TODO: Implement native replication for attributes (e.g. using a specific MultiplayerSynchronizer config)

func get_attribute_value(attribute_name: StringName) -> float:
	return attributes._get(attribute_name)

func set_attribute_value(attribute_name: StringName, value: float, source: StringName = &"") -> void:
	ensure_attribute(attribute_name, value)

# Gameplay
# Dead simple logic for now
func apply_damage(damage: float) -> void:
	set_attribute_value(
		Stat.HEALTH,
		get_attribute_value(Stat.HEALTH) - damage
	)

func add_modifier(modifier: StatModifier) -> void:
	modifiers.append(modifier)

func remove_modifier(modifier: StatModifier) -> void:
	modifiers.erase(modifier)

func recalc_modifiers() -> void:
	pass
