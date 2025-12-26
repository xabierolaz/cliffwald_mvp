extends Control


var cache: Dictionary[int, Dictionary]

@onready var name_label: Label = $PanelContainer/HBoxContainer/VBoxContainer2/Label
@onready var stats_text: RichTextLabel = $PanelContainer/HBoxContainer/StatsContainer/RichTextLabel
@onready var description_text: RichTextLabel = $PanelContainer/HBoxContainer/VBoxContainer2/RichTextLabel
@onready var profile_viewport: SubViewport = $PanelContainer/HBoxContainer/VBoxContainer2/Control/Control/ProfileViewportContainer/SubViewport
@onready var preview_root: Node3D = $PanelContainer/HBoxContainer/VBoxContainer2/Control/Control/ProfileViewportContainer/SubViewport/PreviewRoot

@onready var message_button: Button = $PanelContainer/HBoxContainer/VBoxContainer/MessageButton
@onready var friend_button: Button = $PanelContainer/HBoxContainer/VBoxContainer/FriendButton

var preview_instance: Node3D


func open_player_profile(player_id: int) -> void:
	if cache.has(player_id):
		apply_profile(cache[player_id])
	else:
		InstanceClient.current.request_data(
			&"profile.get",
			apply_profile,
			{"q": player_id}
		)


func apply_profile(profile: Dictionary) -> void:
	print_debug(profile)
	var stats: Dictionary = profile.get("stats", {})
	var player_name: String = profile.get("name", "No Name")
	var player_skin: int = profile.get("skin", 0)
	var animation: String = profile.get("animation", "idle")
	var description: String = profile.get("description", "")

	var params: Dictionary = profile.get("params", {})

	description_text.clear()
	description_text.append_text(description)

	add_stats(stats)
	set_player_character(player_skin, animation)
	name_label.text = player_name

	friend_button.visible = params.get("self", false)
	message_button.visible = params.get("self", false)
	friend_button.text = "Add friend" if params.get("friend", false) == true else "Remove Friend"

	show()

	if profile.get("id", 0):
		cache[profile.get("id")] = profile


func add_stats(stats: Dictionary):
	stats_text.clear()
	stats_text.text = ""
	for stat_name: String in stats:
		print("%s: %s" % [stat_name, stats[stat_name]])
		stats_text.append_text("%s: %s" % [stat_name, stats[stat_name]])


func set_player_character(skin_id: int, animation: String) -> void:
	if not preview_root:
		return

	if preview_instance and is_instance_valid(preview_instance):
		preview_instance.queue_free()

	var character_scene: PackedScene = load("res://source/common/gameplay/characters/character.tscn")
	if not character_scene:
		return

	preview_instance = character_scene.instantiate() as Node3D
	if not preview_instance:
		return

	# Keep the preview static; disable heavy processing if present.
	if preview_instance.has_method("set_process"):
		preview_instance.set_process(false)
	if preview_instance.has_method("set_physics_process"):
		preview_instance.set_physics_process(false)

	preview_instance.global_position = Vector3.ZERO
	preview_instance.rotation.y = PI
	preview_root.add_child(preview_instance)

	var anim_player: AnimationPlayer = preview_instance.find_child("AnimationPlayer", true, false)
	if anim_player:
		if animation != "" and anim_player.has_animation(animation):
			anim_player.play(animation)
		elif anim_player.has_animation("idle"):
			anim_player.play("idle")



func _on_close_pressed() -> void:
	hide()
