extends Node2D

@onready var dialogue = $Control/DialogueBox
@onready var black_fade = $Control/Fade

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await fade_in()
	#pass # Replace with function body.
	await lose_script()
	await fade_out()


func fade_in() -> void:
	black_fade.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(
		black_fade,
		"modulate:a",
		0.0,
		4
	)
	await tween.finished
	
func lose_script() -> void:
	await dialogue.start_dialogue("You", [
		"(So faint…)",
		"(No! I must win this case…!)"
	])
	
	await dialogue.start_dialogue("Judge", [
		"You’re finally awake!",
		"Since you couldn’t handle the case, the court has continued without you."
	])
	
	await dialogue.start_dialogue("You", [
		"Without me?!"
	])
	
	await dialogue.start_dialogue("Judge", [
		"Yes. We brought in another prosecutor, not to worry!"
	])
	
	await dialogue.start_dialogue("You", [
		"And the suspect? What was his sentence?"
	])
	
	await dialogue.start_dialogue("Judge", [
		"Hm? Oh, he was declared innocent."
	])
	
	await dialogue.start_dialogue("You", [
		"WHAAAAT?"
	])
	
	await dialogue.start_dialogue("Judge", [
		"Well, since you’re awake, I’ll get going. Until your next case!"
	])
	
func fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(
		black_fade,
		"modulate:a",
		1.0,
		4
	)
	await tween.finished	
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")
	
	
	
	
	
	
