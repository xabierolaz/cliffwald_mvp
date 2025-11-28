extends DataRequestHandler


func data_request_handler(
	peer_id: int,
	instance: ServerInstance,
	args: Dictionary
) -> Dictionary:
	# Sin sistema de equipamiento en Cliffwald HP; solo monedas/cromos.
	return {}
