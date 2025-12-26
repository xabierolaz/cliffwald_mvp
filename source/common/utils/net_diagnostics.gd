class_name NetDiagnostics

# Opt-in network tracing for debugging replication.
static var enabled: bool = true # OS.has_environment("CLIFFWALD_NET_DEBUG")

static func log(msg: String) -> void:
	if enabled:
		print("[NET]", msg)
