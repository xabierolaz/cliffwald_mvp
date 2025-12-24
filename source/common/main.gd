extends Node

const GATEWAY_SCENE = preload("res://source/server/gateway/gateway_main.tscn")
const MASTER_SCENE = preload("res://source/server/master/master_main.tscn")
const WORLD_SCENE = preload("res://source/server/world/world_main.tscn")
const CLIENT_MAIN_SCENE = preload("res://source/client/client_main.tscn")

func _ready() -> void:
	print("--- MAIN ENTRY POINT ---")

	# [FIX] Ocultar la etiqueta de error si existe
	if has_node("ErrorLabel"):
		$ErrorLabel.hide()
		$ErrorLabel.queue_free()

	if OS.has_feature("gateway-server"):
		_load_scene(GATEWAY_SCENE)
	elif OS.has_feature("master-server"):
		_load_scene(MASTER_SCENE)
	elif OS.has_feature("world-server"):
		_load_scene(WORLD_SCENE)
	elif OS.has_feature("client"):
		_load_scene(CLIENT_MAIN_SCENE)
	else:
		# Sin etiquetas válidas, mostramos la etiqueta de error si está disponible.
		if has_node("ErrorLabel"):
			$ErrorLabel.show()

func _load_scene(packed_scene: PackedScene) -> void:
	var instance = packed_scene.instantiate()
	add_child(instance)
