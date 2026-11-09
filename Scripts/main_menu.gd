extends Control

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_logout_button_pressed() -> void:
	Sfx.play()
	get_tree().change_scene_to_file("res://Scenes/Signup_Screen.tscn")

func _on_quit_button_pressed() -> void:
	Sfx.play()
	get_tree().quit()


func _on_leaderboard_button_pressed() -> void:
	Sfx.play()
	get_tree().change_scene_to_file("res://Scenes/Leaderboard.tscn")


func _on_settings_button_pressed() -> void:
	Sfx.play()
	get_tree().change_scene_to_file("res://Scenes/Settings_Menu.tscn")


func _on_credits_button_pressed() -> void:
	Sfx.play()
	get_tree().change_scene_to_file("res://Scenes/Credits.tscn")
