extends Control

var account_db

func _ready() -> void:
	account_db = SQLite.new()
	account_db.path = "res://Databases/accounts.db"

func _on_submit_button_pressed() -> void:
	# Receive username and password
	var username = $user_input.text
	var password = $pass_input.text
	
	# is there a username?
	if not username:
		$error_label.text = "Error: Enter a username."
		return
	
	# is there a password?
	if not password:
		$error_label.text = "Error: Enter a password."
		return
	
	account_db.open_db()
	
	# Pull all usernames from the table
	var this_q = "SELECT UserID, Username FROM users;"
	account_db.query(this_q)
	
	var user_match = 0
	
	# Does the username match any in the database?
	for i in range (0, account_db.query_result.size()):
		if username == account_db.query_result[i]["Username"]:
			user_match = 1
			# if it matches, make sure that the global user id is that
			Global.userID = account_db.query_result[i]["UserID"]
	
	# The username doesn't match
	if user_match == 0:
		$error_label.text = "Error: Account does not exist."
		account_db.close_db()
		return
	
	# If you're here, the username is in the database. Retrieve the password
	var my_query = "SELECT Password FROM users WHERE UserID = " + str(Global.userID) + ";"
	account_db.query(my_query)
	
	var pass_match = 0
	
	# Is the password entered matching that of the username?
	if password.sha256_text() == account_db.query_result[0]["Password"]:
		pass_match = 1
	
	# If it doesn't match, password is not valid
	if pass_match == 0:
		$error_label.text = "Error: Password is invalid."
		account_db.close_db()
		return
	
	# Username and password are valid, log in
	account_db.close_db()
	
	# Continue to game as user
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")

# Return to login screen without doing anything
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Signup_Screen.tscn")
