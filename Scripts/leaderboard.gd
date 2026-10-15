extends Control

var account_db

# MAKE SURE TO CHANGE your_recent AND your_highest TO HAVE VALUES!
# it's defaulted to nothing in case the user is a guest (global var userID = 0)!!

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize databse
	account_db = SQLite.new()
	account_db.path = "res://Databases/accounts.db"
	
	# Show the user's recent and highest scores if they are logged in
	if Global.userID != 0:
		fill_user()
	
	# Fill the ranks with user scores
	fill_scores()
	
	# Close the database
	account_db.close()

func fill_user() -> void:
	# Get scores sorted by most recent (largest score id)
	var this_q = "SELECT ScoreID, Username, Score FROM scores JOIN users ON users.UserID = scores.UserID WHERE scores.UserID = " + str(Global.userID) + " ORDER BY ScoreID DESC;"
	account_db.query(this_q)
	
	var size = account_db.query_result.size()
	
	if (size <= 0):
		return
	
	# Save recent rank for later but save as a variable
	var recent_id = account_db.query_result[0]["ScoreID"]
	
	# Fill in recent score
	$VBox/your_recent/user.text = account_db.query_result[0]["Username"]
	$VBox/your_recent/score.text = account_db.query_result[0]["Score"]
	
	# Query all scores sorted by score to find rank for both recent and high score
	this_q = "SELECT UserID, ScoreID, Username, Score FROM scores JOIN users ON users.UserID = scores.UserID ORDER BY Score DESC;"
	account_db.query(this_q)
	
	size = account_db.query_result.size()
	
	if (size <= 0):
		return
	
	# Find score with recent_id in score list
	for i in range (0, size):
		if (recent_id == account_db.query_result[i]["ScoreID"]):
			$VBox/your_recent/rank.text = str(i + 1) + "."
			break
	
	for i in range (0, size):
		if (Global.userID == account_db.query_result[i]["UserID"]):
			# Fill in high score
			$VBox/your_high/user.text = account_db.query_result[i]["Username"]
			$VBox/your_high/score.text = account_db.query_result[i]["Score"]
			$VBox/your_high/rank.text = str(i + 1) + "."
			break

func fill_scores() -> void:
	var this_q = "SELECT Username, Score FROM scores JOIN users ON scores.UserID = user.UserID ORDER BY Score DESC;"
	account_db.query(this_q)
	
	var size = account_db.query_result.size()
	
	if (size <= 0):
		return
	
	if (size >= 1):
		$VBox/rank_1/user.text = account_db.query_result[0]["Username"]
		$VBox/rank_1/score.text = str(account_db.query_result[0]["Score"])
	if (size >= 2):
		$VBox/rank_2/user.text = account_db.query_result[1]["Username"]
		$VBox/rank_2/score.text = str(account_db.query_result[1]["Score"])
	if (size >= 3):
		$VBox/rank_3/user.text = account_db.query_result[2]["Username"]
		$VBox/rank_3/score.text = str(account_db.query_result[2]["Score"])
	if (size >= 4):
		$VBox/rank_4/user.text = account_db.query_result[3]["Username"]
		$VBox/rank_4/score.text = str(account_db.query_result[3]["Score"])
	if (size >= 5):
		$VBox/rank_5/user.text = account_db.query_result[4]["Username"]
		$VBox/rank_5/score.text = str(account_db.query_result[4]["Score"])
	if (size >= 6):
		$VBox/rank_6/user.text = account_db.query_result[5]["Username"]
		$VBox/rank_6/score.text = str(account_db.query_result[5]["Score"])
	if (size >= 7):
		$VBox/rank_7/user.text = account_db.query_result[6]["Username"]
		$VBox/rank_7/score.text = str(account_db.query_result[6]["Score"])
	if (size >= 8):
		$VBox/rank_8/user.text = account_db.query_result[7]["Username"]
		$VBox/rank_8/score.text = str(account_db.query_result[7]["Score"])
	if (size >= 9):
		$VBox/rank_9/user.text = account_db.query_result[8]["Username"]
		$VBox/rank_9/score.text = str(account_db.query_result[8]["Score"])
	if (size >= 10):
		$VBox/rank_10/user.text = account_db.query_result[9]["Username"]
		$VBox/rank_10/score.text = str(account_db.query_result[9]["Score"])

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main_Menu.tscn")
