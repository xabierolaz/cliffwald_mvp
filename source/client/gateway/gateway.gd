extends Control

# Helper classes
const CredentialsUtils = preload("res://source/common/utils/credentials_utils.gd")
const GatewayApi = preload("res://source/common/network/gateway_api.gd")

@export var world_server: WorldClient

var account_id: int
var account_name: String
var token: int = randi()

var current_world_id: int
var selected_house: StringName = &"Ignis"
var worlds: Dictionary

# UI references (nueva escena simplificada)
@onready var tabs: TabContainer = $Center/Panel/VBox/Tabs
@onready var login_user: LineEdit = $Center/Panel/VBox/Tabs/Login/LoginVBox/UserEdit
@onready var login_pass: LineEdit = $Center/Panel/VBox/Tabs/Login/LoginVBox/PassEdit
@onready var login_button: Button = $Center/Panel/VBox/Tabs/Login/LoginVBox/LoginButton
@onready var guest_button: Button = $Center/Panel/VBox/Tabs/Login/LoginVBox/GuestButton
@onready var create_user: LineEdit = $Center/Panel/VBox/Tabs/CreateAccount/CreateVBox/NewUserEdit
@onready var create_pass: LineEdit = $Center/Panel/VBox/Tabs/CreateAccount/CreateVBox/NewPassEdit
@onready var create_pass_repeat: LineEdit = $Center/Panel/VBox/Tabs/CreateAccount/CreateVBox/RepeatEdit
@onready var create_account_button: Button = $Center/Panel/VBox/Tabs/CreateAccount/CreateVBox/CreateButton
@onready var char_name: LineEdit = $Center/Panel/VBox/Tabs/CharacterCreation/CharVBox/NameEdit
@onready var house_options: OptionButton = $Center/Panel/VBox/Tabs/CharacterCreation/CharVBox/HouseOptions
@onready var create_char_button: Button = $Center/Panel/VBox/Tabs/CharacterCreation/CharVBox/CreateCharButton
@onready var back_button: Button = $Center/Panel/VBox/BackButton

var http_request: HTTPRequest


func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)

	# Conexión de botones
	login_button.pressed.connect(_on_login_login_button_pressed)
	guest_button.pressed.connect(_on_guest_button_pressed)
	create_account_button.pressed.connect(_on_create_account_button_pressed)
	create_char_button.pressed.connect(_on_create_character_button_pressed)
	back_button.pressed.connect(func():
		tabs.current_tab = 0
		back_button.hide()
	)
	back_button.hide()

	# Selección de casa (doctrina)
	house_options.clear()
	house_options.add_item("Ignis")
	house_options.add_item("Axiom")
	house_options.add_item("Vesper")
	house_options.select(0)
	house_options.item_selected.connect(func(idx: int):
		selected_house = house_options.get_item_text(idx)
	)


func do_request(
	method: HTTPClient.Method,
	path: String,
	payload: Dictionary,
) -> Dictionary:
	# Si ya hay una petición en curso, espera a que termine (con timeout).
	var start_ms := Time.get_ticks_msec()
	while http_request.get_http_client_status() != HTTPClient.Status.STATUS_DISCONNECTED:
		if Time.get_ticks_msec() - start_ms > 10000:
			http_request.cancel_request()
			return {ok=false, error="timeout_wait_previous"}
		await get_tree().process_frame
	
	var custom_headers: PackedStringArray
	custom_headers.append("Content-Type: application/json")
	
	var error: Error = http_request.request(
		path,
		custom_headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload)
	)

	if error != OK:
		push_error("An error occurred in the HTTP request.")
		return {ok=false, error="request_error", code=error}
	
	var args: Array = await http_request.request_completed
	var result: int = args[0]
	if result != OK:
		return {"error": "request_failed", "code": result}
	
	var response_code: int = args[1]
	var headers: PackedStringArray = args[2]
	var body: PackedByteArray = args[3]
	
	var data = JSON.parse_string(body.get_string_from_ascii())
	if data is Dictionary:
		return data
	return {"error": 1}


func populate_worlds(world_info: Dictionary) -> void:
	worlds = world_info


func fill_connection_info(_account_name: String, _account_id: int) -> void:
	account_name = _account_name
	account_id = _account_id


func _start_world_flow() -> void:
	if worlds.is_empty():
		return
	var world_id: int = worlds.keys()[0].to_int()
	current_world_id = world_id
	_load_characters(world_id)


func _load_characters(world_id: int) -> void:
	var d: Dictionary = await do_request(
		HTTPClient.Method.METHOD_POST,
		GatewayApi.world_characters(),
		{
			GatewayApi.KEY_WORLD_ID: world_id,
			GatewayApi.KEY_ACCOUNT_ID: account_id,
			GatewayApi.KEY_ACCOUNT_USERNAME: account_name,
			GatewayApi.KEY_TOKEN_ID: token
		}
	)
	if d.has("error"):
		return
	
	var chars: Dictionary = d.get("data", {})
	if chars.size() == 0:
		tabs.current_tab = 2 # CharacterCreation
		back_button.show()
	else:
		var first_id: int = chars.keys()[0].to_int()
		_enter_world(world_id, first_id)


func _enter_world(world_id: int, character_id: int) -> void:
	var d: Dictionary = await do_request(
		HTTPClient.Method.METHOD_POST,
		GatewayApi.world_enter(),
		{
			GatewayApi.KEY_TOKEN_ID: token,
			GatewayApi.KEY_ACCOUNT_USERNAME: account_name,
			GatewayApi.KEY_WORLD_ID: world_id,
			GatewayApi.KEY_CHAR_ID: character_id
		}
	)
	if d.has("error"):
		return
	world_server.connect_to_server(d["address"], d["port"], d["token"])
	queue_free.call_deferred()


func _on_login_login_button_pressed() -> void:
	var username: String = login_user.text
	var password: String = login_pass.text
	
	login_button.disabled = true
	if (
		CredentialsUtils.validate_username(username).code != CredentialsUtils.UsernameError.OK
		or CredentialsUtils.validate_password(password).code != CredentialsUtils.UsernameError.OK
	):
		login_button.disabled = false
		return

	var d: Dictionary = await do_request(
		HTTPClient.Method.METHOD_POST,
		GatewayApi.login(),
		{
			"u": username,
			"p": password,
			GatewayApi.KEY_TOKEN_ID: token
		}
	)
	if d.has("error"):
		login_button.disabled = false
		return
	
	populate_worlds(d.get("w", {}))
	fill_connection_info(d["a"]["name"], d["a"]["id"])
	login_button.disabled = false
	_start_world_flow()


func _on_guest_button_pressed() -> void:
	var d: Dictionary = await do_request(
		HTTPClient.Method.METHOD_POST,
		GatewayApi.guest(),
		{GatewayApi.KEY_TOKEN_ID: token}
	)
	if d.has("error"):
		return
	
	fill_connection_info(d["a"]["name"], d["a"]["id"])
	populate_worlds(d.get("w", {}))
	_start_world_flow()


func _on_create_account_button_pressed() -> void:
	if create_pass.text != create_pass_repeat.text:
		return
	var result: Dictionary
	result = CredentialsUtils.validate_username(create_user.text)
	if result.code != CredentialsUtils.UsernameError.OK:
		return
	result = CredentialsUtils.validate_password(create_pass.text)
	if result.code != CredentialsUtils.UsernameError.OK:
		return
	
	var d: Dictionary = await do_request(
		HTTPClient.Method.METHOD_POST,
		GatewayApi.account_create(),
		{
			"u": create_user.text,
			"p": create_pass.text,
			GatewayApi.KEY_TOKEN_ID: token
		}
	)
	if d.has("error"):
		return
	fill_connection_info(d["a"]["name"], d["a"]["id"])
	populate_worlds(d.get("w", {}))
	_start_world_flow()


func _on_create_character_button_pressed() -> void:
	create_char_button.disabled = true
	back_button.hide()
	
	var result: Dictionary = CredentialsUtils.validate_username(char_name.text)
	if result.code != CredentialsUtils.UsernameError.OK:
		create_char_button.disabled = false
		back_button.show()
		return

	var d: Dictionary = await do_request(
		HTTPClient.Method.METHOD_POST,
		GatewayApi.world_create_char(),
		{
			GatewayApi.KEY_TOKEN_ID: token,
			"data": {
				"name": char_name.text,
				"house": selected_house,
			},
			GatewayApi.KEY_ACCOUNT_USERNAME: account_name,
			GatewayApi.KEY_WORLD_ID: current_world_id
		}
	)
	if d.has("error"):
		create_char_button.disabled = false
		tabs.current_tab = 2
		return
	
	world_server.connect_to_server(
		d["data"]["address"],
		d["data"]["port"],
		d["data"]["auth-token"]
	)
	queue_free.call_deferred()
