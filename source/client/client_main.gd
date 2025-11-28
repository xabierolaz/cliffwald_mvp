extends Node

const DEV_DIRECT_ENV := "CLIFFWALD_DEV_DIRECT"
const DEV_DIRECT_FEATURE := "dev-direct"
const DEV_DISABLE_DIRECT_ENV := "CLIFFWALD_DISABLE_DEV_DIRECT"

var _dev_connected: bool = false

func _ready() -> void:
	# Modo “dev-direct”: conecta al world server local saltando gateway/master para probar movimiento rápido.
	if OS.has_feature(DEV_DIRECT_FEATURE) or _env_flag(DEV_DIRECT_ENV):
		_dev_connect_direct()


func _dev_connect_direct() -> void:
	_dev_connect_direct_with_params()


func connect_dev_direct(
	addr: String = "",
	port: int = 0,
	token: String = ""
) -> void:
	# API usada por main.gd cuando no hay feature tags.
	_dev_connect_direct_with_params(addr, port, token)


func _dev_connect_direct_with_params(
	addr: String = "",
	port: int = 0,
	token: String = ""
) -> void:
	if _dev_connected:
		return

	var cfg := ConfigFile.new()
	var path := "res://data/config/world_config.cfg"
	var err := cfg.load(path)
	var final_addr := addr if addr != "" else "127.0.0.1"
	var final_port := port if port > 0 else 8087
	if err == OK:
		final_addr = str(cfg.get_value("world-server", "bind_address", final_addr))
		final_port = int(cfg.get_value("world-server", "port", final_port))
	else:
		printerr("DEV_DIRECT: no pude leer %s, usando %s:%d" % [path, final_addr, final_port])

	var final_token := token if token != "" else _env_value("CLIFFWALD_DEV_TOKEN", "dev-token")

	var wc: WorldClient = get_node_or_null("WorldClient")
	if not wc:
		printerr("DEV_DIRECT: WorldClient no encontrado en la escena.")
		return

	print("DEV_DIRECT: conectando directo a %s:%d con token '%s'." % [final_addr, final_port, final_token])
	wc.connect_to_server(final_addr, final_port, final_token)
	_dev_connected = true


func _env_flag(env_name: String) -> bool:
	if not OS.has_environment(env_name):
		return false
	return str(OS.get_environment(env_name)).strip_edges() != ""


func _env_value(env_name: String, fallback: String) -> String:
	if OS.has_environment(env_name):
		var v := str(OS.get_environment(env_name)).strip_edges()
		if v != "":
			return v
	return fallback
