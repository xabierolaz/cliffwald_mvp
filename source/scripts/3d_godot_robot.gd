extends Node3D
class_name Body

const LERP_VELOCITY: float = 0.15

@export_category("Objects")
@export var _character: CharacterBody3D = null
@export var animation_player: AnimationPlayer = null

func _ready():
	if not animation_player:
		# Try to find it as a child
		animation_player = get_node_or_null("AnimationPlayer")
		if not animation_player:
			# Try to find it via unique name or standard gltf name
			for child in get_children():
				if child is AnimationPlayer:
					animation_player = child
					break

func apply_rotation(_velocity: Vector3) -> void:
	var new_rotation_y = lerp_angle(rotation.y, atan2(-_velocity.x, -_velocity.z), LERP_VELOCITY)
	rotation.y = new_rotation_y

func animate(_velocity: Vector3) -> void:
	if not _character.is_on_floor():
		if _velocity.y < 0:
			animation_player.play("Fall")
		else:
			var current_anim = animation_player.current_animation
			if current_anim != "Jump" and current_anim != "Jump2":
				animation_player.play("Jump")
		return

	if _velocity:
		if _character.is_running() and _character.is_on_floor():
			animation_player.play("Sprint")
			return

		animation_player.play("Run")
		return

	animation_player.play("Idle")

func play_jump_animation(jump_type: String = "Jump") -> void:
	if animation_player:
		animation_player.play(jump_type)
