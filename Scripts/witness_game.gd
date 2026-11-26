extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.gameMode == 1:
		Dialogic.start("sql_inj_wit")
	else:
		pass
	
	await Dialogic.timeline_ended
	get_tree().change_scene_to_file("res://Scenes/middle_game.tscn")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
