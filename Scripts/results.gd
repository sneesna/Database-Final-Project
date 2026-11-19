extends Control
var account_db

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	account_db = SQLite.new()
	account_db.path = "res://Databases/accounts.db"
	
	# Set up score
	var score : float
	if Global.questionsAns > 0:
		score = 5/Global.questionsAns
	else:
		score = 0
	
	score_set(score)
	
	# For user id, put score into scores table in account db
	# Open the database
	account_db.open_db()
	var this_q = "INSERT INTO scores ('UserID', 'Score') VALUES (" + Global.UserID + ", " + score + ");"
	account_db.query(this_q)
	account_db.close()
	
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func score_set(score: float):
	$scoreLabel.text = "%:.2f%%" % score
