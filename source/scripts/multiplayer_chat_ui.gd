extends Control
class_name MultiplayerChatUI

@onready var message: LineEdit = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Message
@onready var send: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Send
@onready var chat: TextEdit = $Panel/MarginContainer/VBoxContainer/Chat
@onready var hide_timer: Timer = $HideTimer

signal message_sent(message_text: String)

func _ready():
	send.pressed.connect(_on_send_pressed)
	# message.text_submitted is handled by _input in level.gd now, 
	# but keeping it connected doesn't hurt for UI button clicks.
	# Actually, let's keep text_submitted for robustness.
	message.text_submitted.connect(_on_text_submitted)
	
	hide_timer.timeout.connect(hide)
	message.focus_entered.connect(_on_focus_entered)
	message.focus_exited.connect(_on_focus_exited)
	
	clear_chat()
	visible = false

# Removed toggle_chat and chat_visible variable. 
# Use native 'visible' property.

func _input(event):
	if not visible: return
	
	if event is InputEventMouseButton and event.pressed:
		# If user clicks outside the chat UI, release focus
		if not get_global_rect().has_point(event.position):
			if message.has_focus():
				message.release_focus()

func _on_focus_entered():
	hide_timer.stop()

func _on_focus_exited():
	# Start timer to hide chat after 5 seconds of inactivity
	hide_timer.start()

func is_chat_visible() -> bool:
	return visible

func is_typing() -> bool:
	return message.has_focus()

func _on_text_submitted(_text):
	_on_send_pressed()

func _on_send_pressed():
	var message_text = message.text.strip_edges()
	if message_text.is_empty():
		return

	message_sent.emit(message_text)

	message.text = ""
	# Keep focus to continue typing? Usually yes in MMOs. 
	# But if we want auto-hide behavior, maybe user wants to send and close.
	# Let's keep focus for rapid chatting. User can Esc or Click away to close.
	message.grab_focus() 
	hide_timer.stop()

func add_message(nick: String, msg: String):
	# If message received, show chat and reset timer (passive read)
	show()
	if not message.has_focus():
		hide_timer.start()
		
	var time = Time.get_time_string_from_system()
	var formatted_message = "[" + time + "] " + nick + ": " + msg + "\n"
	chat.text += formatted_message
	chat.scroll_vertical = chat.get_line_count()
	_limit_chat_history()

func _limit_chat_history():
	var lines = chat.text.split("\n")
	if lines.size() > 100:
		var start_index = lines.size() - 100
		chat.text = "\n".join(lines.slice(start_index))

func clear_chat():
	chat.text = ""
