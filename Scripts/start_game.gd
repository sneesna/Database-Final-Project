extends Node2D

var judge1 = ["Ahem.",
"Today's court is now in session for the trial of TEMP."]

var you2 = ["(I don't know whether I'm excited or nervous...)",
"(This is the first trial I'm taking on as a newly-fledged prosecutor! But...)"]
# Sweat
var you3 = ["(This is a murder case. No matter the outcome, I need to take this seriously and do well.)"]
# Normal
var you4 = ["The prosecution is ready, Your Honor!",
"(Bul ultimately, I'm ready! After all, I have access to the court evidence!)"]

var def5 = ["The defense is ready, Your Honor."]

var judge6 = ["Then the court is ready.",
"The prosecution, please give your opening statement."]

var you7 = ["Thank you, Your Honor. The suspect, TEMP, was arrested with links to the scene of the crime.",
"The prosecution has evidence that he committed this murder.",
"... and we have a witness who knows he did it."]

var judge8 = ["I see... Thank you, Prosecutor. Let's begin, you may call your witness."]

var you9 = ["Thank you, Your Honor. The prosecution calls the witness that was at the scene."]

# Start dialogue with:
# $DialogueBox.start_dialogue("name", ["line 1", "line 2, etc."])

# Wait with:
# wait(seconds)

# Make functions for cutscenes!

# Either make a function for switching characters or do it manually!

func _ready() -> void:
	# Randomize game mode between 1 and 6
	Global.gameMode = randi_range(1, 6)
	print("game mode: ", Global.gameMode)
	
	# Auto start is off for this but it being on doesn't fix the error
	#$DialogueBox.start_dialogue("1st", ["i am the one that goes first"])
	#await get_tree().create_timer(10.0).timeout
	#$DialogueBox.start_dialogue("2nd", ["i run second", "yay"])
	
	# temp
	Dialogic.start("start")
	
	# DB DEATH CUTSCENE
	
	# COURT START SEQUENCE
	
	#$DialogueBox.start_dialogue("test", ["help mee", "michaell"])
	
	# DIALOGUE
	#$DialogueBox.start_dialogue("Judge", judge1)
	
	#$DialogueBox.start_dialogue("You", you2)
	# OPTIONAL SWEAT
	#$DialogueBox.start_dialogue("You", you3)
	# BACK TO NEUTRAL
	#$DialogueBox.start_dialogue("You", you4)
	
	#$DialogueBox.start_dialogue("Felix Wrong", def5)
	
	#$DialogueBox.start_dialogue("Judge", judge6)
	
	#$DialogueBox.start_dialogue("You", you7)
	
	#$DialogueBox.start_dialogue("Judge", judge8)
	
	#$DialogueBox.start_dialogue("You", you9)
	
	# Send to witness based on game mode
	if Global.gameMode == 1:
		pass
	if Global.gameMode == 2:
		pass
	if Global.gameMode == 3:
		pass
	if Global.gameMode == 4:
		pass
	if Global.gameMode == 5:
		pass
	else:
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func wait(seconds: float):
	await get_tree().create_timer(seconds).timeout
