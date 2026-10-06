extends Control
var account_db

# Open account database!!
func _ready() -> void:
	account_db = SQLite.new()
	account_db.path = "res://Databases/accounts.db"

func _on_submit_button_pressed() -> void:
	# Get inputted username
	var username = $user_input
	
	# Get inputted password
	var password = $pass_input
	
	if not username:
		$error_label.text = "Error: Please enter a username."
		return
	
	if not password:
		$error_label.text = "Error: Please enter a password."
		return
	
	# Clean username
	username = parameterize(username)
	
	# Clean password
	password = parameterize(password)
	
	# Ensure username and password are 20 char or less
	if username.length() > 20:
		$error_label.text = "Error: Username must be 20 characters or less."
		return
	
	if password.length() > 20:
		$error_label.text = "Error: Password must be 20 characters or less."
		return
	
	# Open the database
	account_db.open_db()
	
	# Check if the username is taken
	var this_q = "SELECT Username FROM users WHERE Username = " + username + ";"
	
	account_db.query(this_q)
	
	if (account_db.query_results[0]["username"] != null):
		$error_label.text = "Error: Username is taken."
		account_db.close_db()
		return
	
	password = password.sha256_text()
	
	# Enter the username into the database
	this_q = "INSERT INTO accounts ('Username', 'Password') values ('" + username + "', '" + password + "');"
	account_db.query(this_q)
	
	account_db.close_db()
	
	get_tree().change_scene_to_file("res://Signup_Screen.tscn")

# Transform input into a single word with escape sequences for special characters
func parameterize(input) -> String:
	input = input.split(" ")
	input = input[0]
	
	for char in input:
		if char == '*' or char == '+' or char == '-' or char == "#" or char == "'" or char == '"':
			input = input.substr(0, char-1) + '\\' + input.substr(char)
	
	return input
