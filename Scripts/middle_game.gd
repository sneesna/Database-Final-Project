extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#pass
	
	Dialogic.start("middle")
	
	await Dialogic.timeline_ended
	get_tree().change_scene_to_file("res://Scenes/end_game.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
