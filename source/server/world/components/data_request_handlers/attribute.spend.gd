extends DataRequestHandler


const AttributesMap = preload("res://source/common/gameplay/combat/attributes/attributes_map.gd")


func data_request_handler(
	peer_id: int,
	instance: ServerInstance,
	args: Dictionary
) -> Dictionary:
	# Sin progresión de atributos en este diseño.
	return {}
