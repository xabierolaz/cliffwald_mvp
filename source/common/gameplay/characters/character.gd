@icon("res://assets/node_icons/blue/icon_character.png")
class_name Character
extends CharacterBody3D

enum Animations {
	IDLE,
	RUN,
	DEATH,
}

var skin_id: int:
	set = _set_skin_id

var anim: Animations = Animations.IDLE:
	set = _set_anim

var pivot: float = 0.0:
	set = _set_pivot

var state_synchronizer: StateSynchronizer
var ability_system_component: AbilitySystemComponent
var equipment_component: EquipmentComponent
var animation_player: AnimationPlayer
var animation_tree: AnimationTree
var locomotion_state_machine: AnimationNodeStateMachinePlayback


func _ready() -> void:
	state_synchronizer = get_node_or_null("StateSynchronizer")
	ability_system_component = get_node_or_null("AbilitySystemComponent")
	equipment_component = get_node_or_null("EquipmentComponent")
	animation_player = get_node_or_null("AnimationPlayer")
	animation_tree = get_node_or_null("AnimationTree")
	if animation_tree:
		locomotion_state_machine = animation_tree.get("parameters/OnFoot/LocomotionSM/playback")

	if multiplayer.is_server():
		return
	
	if ability_system_component and ability_system_component.attributes:
		# Hook stat watchers only if the component exists.
		ability_system_component.attributes.connect_watcher(Stat.HEALTH,
			func(_value: float) -> void:
				pass # UI Logic Placeholder
		)
		# Se corrigió la indentación aquí:
		ability_system_component.attributes.connect_watcher(Stat.HEALTH_MAX,
			func(_value: float) -> void:
				pass # UI Logic Placeholder
		)

func _set_skin_id(id: int) -> void:
	skin_id = id
	if multiplayer.is_server():
		return
	# Lógica visual desactivada temporalmente para la migración
	pass

func _set_anim(new_anim: Animations) -> void:
	if locomotion_state_machine == null:
		anim = new_anim
		return
	match new_anim:
		Animations.IDLE:
			locomotion_state_machine.travel(&"locomotion_idle")
		Animations.RUN:
			locomotion_state_machine.travel(&"locomotion_run")
		Animations.DEATH:
			locomotion_state_machine[&"parameters/OnFoot/InteruptShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	anim = new_anim

func _set_pivot(new_pivot: float) -> void:
	pivot = new_pivot


# Rotate character on the Y axis instead of 2D-style flipping.
func face_direction(direction: Vector3) -> void:
	if direction.length() < 0.001:
		return
	var yaw: float = atan2(direction.x, direction.z)
	rotation.y = yaw
