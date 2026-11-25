extends Node2D

@onready var dialogue = $Control/DialogueBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	win_script()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func win_script() -> void:
	await dialogue.start_dialogue("Attaquer", [
		"Grrk! You… pesky Prosecutor!",
		"FINE! I did it!",
		"I killed Mr. Database!! It was ME!"
	])
	
	await dialogue.start_dialogue("Judge", [
		"… Well, that settles it! Suspect Attaquer really is…",
		"GUILTY!",
		"Order! Order in the court!"
	])
	
	await dialogue.start_dialogue("You", [
		"(Wow, it really is over. I can’t believe I won my first ever case!)",
		"(Now [BAD GUY NAME]’s victims may rest easy knowing he’s facing a life in prison.)",
		"(And I learned valuable knowledge about [SQL Injection or the other 2 attack methods] too!)",
		"(Maybe I’ll learn more if I try again…)",
		"(But for now, I’m ready to wrap up this case!)"
	])
	
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")
	
	
	
	
	
	
	
	
