extends Control

# ONE SCENE SCRIPT because this script is small
# if we need multiple scripts for the game itself that's fine

# Reset User ID when the user logs out
func _ready() -> void:
	Global.userID = 0

# When login button pressed, go to login scene
func _on_login_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Log_In.tscn")

# When signup button pressed, go to signup scene
func _on_signup_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Sign_Up.tscn")

# When guest button pressed, skip to main menu screen
# User ID stays 0 (guest)
func _on_guest_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")
