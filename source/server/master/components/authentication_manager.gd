class_name AuthenticationManager
extends Node

@export var database: MasterDatabase

func _ready() -> void:
	pass

# Fixed: Use Crypto for secure token generation
func generate_random_token() -> String:
	var crypto = Crypto.new()
	var bytes = crypto.generate_random_bytes(32)
	return bytes.hex_encode()

func create_account(username: String, password: String, is_guest: bool) -> AccountResource:
	if not is_guest and database.username_exists(username):
		return null
	var account_id: int = database.account_collection.get_new_account_id()

	# Securely hash password for storage
	var stored_password = password
	if is_guest:
		username = "guest%d" % account_id
		stored_password = generate_random_token()
	else:
		stored_password = password.sha256_text()

	var new_account: AccountResource = AccountResource.new()
	new_account.init(account_id, username, stored_password)
	database.account_collection.collection[username] = new_account
	# Save on disk should only occur at specific times.
	# Temporary work around for debug purpose.
	database.save_account_collection()
	return new_account
