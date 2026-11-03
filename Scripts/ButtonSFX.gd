extends TextureButton

@export var pressed_sound: AudioStream

func _ready() -> void:
	pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if pressed_sound != null:
		AudioManager.play_sound(pressed_sound)
