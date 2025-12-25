extends Node3D
class_name BaseProjectile

@export var speed: float = 20.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0
@export var effect_type: String = "Damage" # Damage, Stun, Shield

var direction: Vector3 = Vector3.FORWARD
var owner_id: int = -1

func _ready() -> void:
	set_as_top_level(true) # Desacoplar del padre para movimiento libre

	# Auto-destroy after lifetime (Server only handling cleanup usually, but client needs to know)
	if multiplayer.is_server():
		await get_tree().create_timer(lifetime).timeout
		queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if not multiplayer.is_server(): return

	# Ignore self collision via owner_id check logic if needed,
	# but simpler is to use collision layers (Layer 3: Spells)

	if body.has_method("take_damage"):
		body.take_damage(damage, effect_type)
		queue_free()
	elif body is StaticBody3D or body is CSGShape3D:
		# Wall hit
		queue_free()
