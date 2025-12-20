extends Area3D
class_name Projectile

@export var speed: float = 25.0
@export var damage: int = 10
@export var max_lifetime: float = 3.0

var direction: Vector3 = Vector3.FORWARD
var shooter_id: int = -1

func _ready():
	# Detach from parent transform so it moves independently in world space
	set_as_top_level(true)
	
	body_entered.connect(_on_body_entered)
	
	if multiplayer.is_server():
		# Server handles lifetime to prevent lingering projectiles
		await get_tree().create_timer(max_lifetime).timeout
		if is_instance_valid(self):
			queue_free()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if not multiplayer.is_server(): return
	
	# Prevent hitting the shooter immediately (if spawned inside/close)
	if body.name == str(shooter_id):
		return
		
	print("Projectile hit: ", body.name)
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
	else:
		# Hit a wall or obstacle
		queue_free()
