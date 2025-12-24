class_name MasterDatabase
extends Node

var account_collection: AccountResourceCollection
var account_collection_path: String = "res://source/server/master/account_collection.tres"

func _ready() -> void:
	tree_exiting.connect(save_account_collection)
	load_account_collection()

func load_account_collection() -> void:
	if ResourceLoader.exists(account_collection_path):
		account_collection = ResourceLoader.load(account_collection_path)
	else:
		account_collection = AccountResourceCollection.new()

func username_exists(username: String) -> bool:
	if account_collection.collection.has(username):
		return true
	return false

# Fixed: Hashed password check
func validate_credentials(username: String, password: String) -> AccountResource:
	var account: AccountResource = null
	if account_collection.collection.has(username):
		account = account_collection.collection[username]

		# If the stored password matches the input password (legacy plaintext) OR matches the hash of input.
		if account.password == password: # Legacy plaintext check
			return account

		# Secure check: Hash the input password and compare.
		if account.password == password.sha256_text():
			return account

	return null

func save_account_collection() -> void:
	ResourceSaver.save(account_collection, account_collection_path)
