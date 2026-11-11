extends Control

# dialogue stuff
@export var char_name = "Character"
@export var dialogue_lines: Array[String] = [
	"Hello! Welcome to the game.",
	"Click next to keep going."
]
@export var char_image: Texture2D

var current_line = 0
var is_typing = false
var char_index = 0

#volumes and font stuff from Global
var masterVolume = 100.0
var sfxVolume = 100.0
var blips_off = false

var font_on = Global.font_on
var dyslexiaFont = Global.dyslexiaFont
var fontSize = Global.fontSize

func _ready() -> void:
	update_settings()
	start_dialogue(char_name, dialogue_lines, char_image)

func _process(_delta: float) -> void:
	pass

func update_settings() -> void:
	font_on = Global.font_on
	fontSize = Global.fontSize
	
	if ("masterVolume" in Global):
		masterVolume = Global.masterVolume
	if ("sfxVolume" in Global):
		sfxVolume = Global.sfxVolume
	if ("blips_off" in Global):
		blips_off = Global.blips_off
	
	var sfxVol = 1 * (masterVolume / 100.0) * (sfxVolume / 100.0)
	if has_node("blipSFX"):
		$blipSFX.set_volume_linear(sfxVol)
	
	if (font_on == true):
		if has_node("name_label"):
			$name_label.add_theme_font_override("font", dyslexiaFont)
		if has_node("dialogue_text"):
			$dialogue_text.add_theme_font_override("normal_font", dyslexiaFont)
		if has_node("next_label"):
			$next_label.add_theme_font_override("font", dyslexiaFont)
	else:
		if has_node("name_label"):
			$name_label.remove_theme_font_override("font")
		if has_node("dialogue_text"):
			$dialogue_text.remove_theme_font_override("normal_font")
		if has_node("next_label"):
			$next_label.remove_theme_font_override("font")
	
	if (fontSize > 0):
		if has_node("name_label"):
			$name_label.add_theme_font_size_override("font_size", fontSize)
		if has_node("dialogue_text"):
			$dialogue_text.add_theme_font_size_override("normal_font_size", fontSize)
	else:
		if has_node("name_label"):
			$name_label.add_theme_font_size_override("font_size", 32)
		if has_node("dialogue_text"):
			$dialogue_text.add_theme_font_size_override("normal_font_size", 28)

func start_dialogue(new_name: String, new_lines: Array[String], new_image: Texture2D = null) -> void:
	char_name = new_name
	dialogue_lines = new_lines
	if has_node("name_label"):
		$name_label.text = char_name
	
	if (new_image != null and has_node("char_portrait")):
		char_image = new_image
		$char_portrait.texture = char_image
	
	current_line = 0
	visible = true
	show_current_line()

func show_current_line() -> void:
	update_settings()
	if has_node("dialogue_text"):
		$dialogue_text.text = dialogue_lines[current_line]
		$dialogue_text.visible_characters = 0
	char_index = 0
	is_typing = true
	if has_node("type_timer"):
		$type_timer.start()

func next_line() -> void:
	if (is_typing == true):
		if has_node("type_timer"):
			$type_timer.stop()
		if has_node("dialogue_text"):
			$dialogue_text.visible_characters = -1
		is_typing = false
	else:
		current_line += 1
		if (current_line < dialogue_lines.size()):
			show_current_line()
		else:
			visible = false

func _on_type_timer_timeout() -> void:
	if not has_node("dialogue_text"):
		return
		
	var total_chars = $dialogue_text.get_total_character_count()
	
	if ($dialogue_text.visible_characters < total_chars):
		$dialogue_text.visible_characters += 1
		char_index += 1
		
		if (blips_off == false and Global.sfx_off == false):
			if (char_index % 2 == 0 and has_node("blipSFX")):
				$blipSFX.pitch_scale = randf_range(0.92, 1.12)
				$blipSFX.play()
	else:
		if has_node("type_timer"):
			$type_timer.stop()
		is_typing = false

func _on_next_button_pressed() -> void:
	Sfx.play()
	next_line()
