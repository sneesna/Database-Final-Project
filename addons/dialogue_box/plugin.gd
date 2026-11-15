@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("DialogueBox", "Control", preload("res://addons/dialogue_box/dialogue_box.gd"), null)


func _exit_tree() -> void:
	remove_custom_type("DialogueBox")
