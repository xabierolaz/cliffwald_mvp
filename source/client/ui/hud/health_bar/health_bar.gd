extends Control

@onready var label: Label = $ProgressBar/Label
@onready var progress_bar: ProgressBar = $ProgressBar


func _ready() -> void:
	# CAMBIO: Escuchamos la señal esperando un NetPlayer (antes Player3D)
	ClientState.local_player_ready.connect(
		func(local_player: NetPlayer) -> void:
			# VERIFICACIÓN DE SEGURIDAD:
			var ability_system = local_player.get("ability_system_component")

			if ability_system:
				ability_system.attributes.connect_watcher(&"health", _on_health_changed)

				if is_instance_valid(Stat):
					ability_system.attributes.connect_watcher(Stat.HEALTH_MAX, _on_max_health_changed)
			else:
				# MODO SEGURO (FASE 1):
				progress_bar.max_value = 100
				progress_bar.value = 100
				update_label()
	)


func _on_health_changed(new_health: float) -> void:
	progress_bar.value = new_health
	update_label()


func _on_max_health_changed(new_max_health: float) -> void:
	progress_bar.max_value = new_max_health
	update_label()


func update_label() -> void:
	label.text = "%d / %d" % [progress_bar.value, progress_bar.max_value]
