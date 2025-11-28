extends Control

@onready var label: Label = $ProgressBar/Label
@onready var progress_bar: ProgressBar = $ProgressBar


func _ready() -> void:
	# CAMBIO: Escuchamos la señal esperando un Player3D
	ClientState.local_player_ready.connect(
		func(local_player: Player3D) -> void:
			# VERIFICACIÓN DE SEGURIDAD:
			# Como estamos en la Fase 1, tu Player3D todavía no tiene "ability_system_component".
			# Usamos .get() para intentar obtenerlo sin que el juego crashee si falta.
			
			var ability_system = local_player.get("ability_system_component")
			
			if ability_system:
				# Si ya tienes el sistema de habilidades (Fase 3), conectamos todo:
				ability_system.attributes.connect_watcher(&"health", _on_health_changed)
				
				# Nota: Si 'Stat' da error, usa strings directos temporalmente como "health_max"
				if is_instance_valid(Stat): 
					ability_system.attributes.connect_watcher(Stat.HEALTH_MAX, _on_max_health_changed)
			else:
				# MODO SEGURO (FASE 1):
				# Si no hay stats, ponemos la barra al 100% visualmente para que no se vea fea.
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
