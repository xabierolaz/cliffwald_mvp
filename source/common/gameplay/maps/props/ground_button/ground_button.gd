extends Area3D


@export var activable_door: Array[Node3D]
@export var interaction_id: int = 0
@export var cooldown: float = 6.0

var pressed: bool = false

@onready var button_anim: AnimatedSprite3D = $AnimatedSprite3D


func _ready() -> void:
	if multiplayer.is_server():
		# Only the server checks for collision.
		body_entered.connect(_on_body_entered)
	button_anim.play(&"up") # Default animation


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and not pressed:

		var container: ReplicatedPropsContainer = get_parent()
		var prop_id: int = container.child_id_of_node(self)
		container.set_baseline_ops(prop_id, [["rp_button_pressed", []]])
		container.queue_op(prop_id, "rp_button_pressed", [])

		pressed = true

		# Call the function also on server so door collisions are moved.
		rp_button_pressed()


func rp_button_pressed() -> void:
	button_anim.play(&"pressed")
	await button_anim.animation_finished
	for door: Node3D in activable_door:
		if door.has_method("open_door"):
			door.open_door()
