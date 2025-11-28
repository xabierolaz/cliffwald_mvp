extends Character

# NPC Básico para Cliffwald
# IA Placeholder: Solo detecta al jugador por ahora.

var targets: Array[Node3D] = []
var timer: float = 0.0

@onready var detection_area: Area3D = $DetectionArea

func _ready() -> void:
	if not multiplayer.is_server():
		set_physics_process(false)
		return
		
	if has_node("DetectionArea"):
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if targets.is_empty(): return
	
	# Lógica de rotación simple hacia el objetivo (Placeholder para IA futura)
	var target_pos = targets[0].global_position
	var target_dir = (target_pos - global_position).normalized()
	target_dir.y = 0 # Mantenerse en el plano
	if target_dir != Vector3.ZERO:
		look_at(global_position + target_dir, Vector3.UP)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body != self:
		targets.append(body)
		print("NPC detectó a: ", body.name)

func _on_body_exited(body: Node) -> void:
	if targets.has(body):
		targets.erase(body)
