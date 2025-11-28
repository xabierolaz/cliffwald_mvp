extends StaticBody3D


@export var door_id: int = 0

@onready var door_anim: AnimatedSprite3D = $AnimatedSprite3D
@onready var door_collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	door_anim.play(&"closed")


func open_door() -> void:
	door_anim.play(&"opening")
	door_collision.disabled = true
