extends Node2D

# Start dialogue with:
# $DialogueBox.start_dialogue("name", ["line 1", "line 2, etc."])

# Wait with:
# wait(seconds)

# Make functions for cutscenes!

# Either make a function for switching characters or do it manually!

func _ready() -> void:
	pass # Replace with function body.
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func wait(seconds: int):
	await get_tree().create_timer(seconds).timeout
