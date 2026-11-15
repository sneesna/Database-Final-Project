@tool
extends Control
# dialogue box stuff

signal dialogue_started
signal line_started(index: int, text: String)
signal line_finished(index: int, text: String)
signal dialogue_finished
signal dialogue_cancelled

const UI_SCENE = preload("res://addons/dialogue_box/dialogue_box_ui.tscn")
const FONT_VARIANTS = ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]
const FONT_SIZE_VARIANTS = ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]

@export_group("Dialogue")
@export var char_name = "Character"
@export_multiline var dialogue_lines: Array[String] = [
	"Hello! Welcome to the game.",
	"Press Next, Enter, or the gamepad accept button to keep going."
]
@export var char_image: Texture2D
@export var auto_start = true
# Set this to 0 to show all the text at once.
@export_range(0.0, 200.0, 1.0) var characters_per_second = 25.0
@export var advance_action: StringName = &"ui_accept"
@export var bbcode_enabled = true

@export_group("Appearance")
@export var background_texture: Texture2D = preload("res://addons/dialogue_box/assets/dialogue_background.webp")
@export_range(12, 72) var text_font_size = 28
@export_range(12, 72) var name_font_size = 30
@export_range(12, 72) var button_font_size = 22
@export var reveal_text = "Show all"
@export var next_text = "Next"
@export var close_text = "Close"

@export_group("Settings integration")
# settings from Global, if the project has it
@export var settings_path: NodePath = ^"/root/Global"
@export var click_sound_path: NodePath = ^"/root/Sfx"
@export var blips_off = false
@export var sfx_off = false
@export_range(0.0, 100.0) var masterVolume = 100.0
@export_range(0.0, 100.0) var sfxVolume = 100.0
@export var font_on = false
@export var dyslexiaFont: Font
@export var fontSize = 0

var current_line = 0
var is_typing = false
var char_index = 0
var is_active = false

var _ui: Control
var _name_label: Label
var _name_box: PanelContainer
var _portrait: TextureRect
var _header: HBoxContainer
var _panel: PanelContainer
var _content: MarginContainer
var _text: RichTextLabel
var _next_button: Button
var _timer: Timer
var _blip: AudioStreamPlayer
var _start_requested = false
var _generation = 0
var _parsed_text = ""
var _effective_blips_off = false
var _effective_sfx_off = false


func _ready() -> void:
	if size == Vector2.ZERO:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	resized.connect(_update_layout)
	_update_layout()
	update_settings()
	if Engine.is_editor_hint():
		_name_label.text = char_name
		_text.text = dialogue_lines[0] if not dialogue_lines.is_empty() else ""
		_portrait.texture = char_image
		_portrait.visible = char_image != null
		return
	_timer.timeout.connect(_on_type_timer_timeout)
	_next_button.pressed.connect(_on_next_button_pressed)
	visibility_changed.connect(_on_visibility_changed)
	if auto_start or _start_requested:
		start_dialogue(char_name, dialogue_lines, char_image)
	else:
		hide()


func _build_ui() -> void:
	# Add the layout for both the scene and the custom DialogueBox node.
	_ui = get_node_or_null("UI")
	if _ui == null:
		_ui = UI_SCENE.instantiate()
		add_child(_ui)
	_name_label = _ui.get_node("%NameLabel")
	_name_box = _ui.get_node("%NameBox")
	_portrait = _ui.get_node("%Portrait")
	_header = _ui.get_node("%Header")
	_panel = _ui.get_node("%Panel")
	_content = _ui.get_node("%Content")
	_text = _ui.get_node("%DialogueText")
	_next_button = _ui.get_node("%NextButton")
	_timer = _ui.get_node("TypeTimer")
	_blip = _ui.get_node("BlipSFX")
	var style = _panel.get_theme_stylebox("panel").duplicate() as StyleBoxTexture
	style.texture = background_texture
	_panel.add_theme_stylebox_override("panel", style)
	_text.bbcode_enabled = bbcode_enabled
	_next_button.text = tr(next_text)
	# keyboard input is handled below
	_next_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS


func _update_layout() -> void:
	if not is_instance_valid(_ui):
		return
	var horizontal_margin = int(clampf(size.x * 0.08, 12.0, 160.0))
	var vertical_margin = int(clampf(size.y * 0.035, 12.0, 38.0))
	_ui.add_theme_constant_override("margin_left", horizontal_margin)
	_ui.add_theme_constant_override("margin_right", horizontal_margin)
	_ui.add_theme_constant_override("margin_top", vertical_margin)
	_ui.add_theme_constant_override("margin_bottom", vertical_margin)
	_panel.custom_minimum_size.y = clampf(size.y * 0.32, 220.0, 300.0)
	var portrait_size = clampf(size.y * 0.1, 48.0, 96.0)
	_portrait.custom_minimum_size = Vector2(portrait_size, portrait_size)
	# Leave room for the square decorations in the background's corners.
	var padding = 40
	for side in ["left", "top", "right", "bottom"]:
		_content.add_theme_constant_override("margin_" + side, padding)


# Call this after changing the font or sound settings.
func update_settings() -> void:
	if not is_instance_valid(_ui):
		return
	var settings = get_node_or_null(settings_path) if not settings_path.is_empty() else null
	var use_font = bool(_setting(settings, &"font_on", font_on))
	var selected_font = _setting(settings, &"dyslexiaFont", dyslexiaFont)
	var selected_size = int(_setting(settings, &"fontSize", fontSize))
	_update_sound_settings()
	for control in [_name_label, _next_button]:
		if use_font and selected_font is Font:
			control.add_theme_font_override("font", selected_font)
		else:
			control.remove_theme_font_override("font")
	for variant in FONT_VARIANTS:
		if use_font and selected_font is Font:
			_text.add_theme_font_override(variant, selected_font)
		else:
			_text.remove_theme_font_override(variant)
	_name_label.add_theme_font_size_override("font_size", selected_size if selected_size > 0 else name_font_size)
	_next_button.add_theme_font_size_override("font_size", selected_size if selected_size > 0 else button_font_size)
	for variant in FONT_SIZE_VARIANTS:
		_text.add_theme_font_size_override(variant, selected_size if selected_size > 0 else text_font_size)


func _update_sound_settings() -> void:
	var settings = get_node_or_null(settings_path) if not settings_path.is_empty() else null
	_effective_blips_off = bool(_setting(settings, &"blips_off", blips_off))
	_effective_sfx_off = bool(_setting(settings, &"sfx_off", sfx_off))
	var master = clampf(float(_setting(settings, &"masterVolume", masterVolume)), 0.0, 100.0)
	var sfx = clampf(float(_setting(settings, &"sfxVolume", sfxVolume)), 0.0, 100.0)
	_blip.volume_linear = (master / 100.0) * (sfx / 100.0)
	if _effective_blips_off or _effective_sfx_off or is_zero_approx(_blip.volume_linear):
		_blip.stop()
	_blip.bus = &"SFX" if AudioServer.get_bus_index(&"SFX") >= 0 else &"Master"


func _setting(settings: Node, property: StringName, fallback: Variant) -> Variant:
	if is_instance_valid(settings) and property in settings:
		var value = settings.get(property)
		if value != null:
			return value
	return fallback


# start over from the first line
func start_dialogue(new_name: String, new_lines: Array, new_image: Texture2D = null) -> void:
	char_name = new_name
	dialogue_lines = []
	for line in new_lines:
		dialogue_lines.append(str(line))
	char_image = new_image
	if not is_node_ready():
		_start_requested = true
		return
	_generation += 1
	var generation = _generation
	_stop_typing()
	current_line = 0
	_name_label.text = char_name
	_name_box.visible = not char_name.strip_edges().is_empty()
	_portrait.texture = char_image
	_portrait.visible = char_image != null
	_header.visible = _name_box.visible or _portrait.visible
	_text.bbcode_enabled = bbcode_enabled
	is_active = true
	show()
	dialogue_started.emit()
	if generation != _generation or not is_active:
		return
	if dialogue_lines.is_empty():
		finish_dialogue()
		return
	show_current_line()


func show_current_line() -> void:
	if not is_active:
		return
	if current_line < 0 or current_line >= dialogue_lines.size():
		finish_dialogue()
		return
	_generation += 1
	var generation = _generation
	_stop_typing()
	update_settings()
	_text.text = dialogue_lines[current_line]
	_text.visible_characters = 0
	_text.scroll_to_line(0)
	_parsed_text = _text.get_parsed_text()
	char_index = 0
	is_typing = true
	_update_prompt()
	line_started.emit(current_line, dialogue_lines[current_line])
	# A connected signal might have started a different conversation.
	if generation != _generation or not is_active or not is_typing:
		return
	if characters_per_second <= 0.0 or _text.get_total_character_count() == 0:
		reveal_current_line()
	else:
		_timer.start(1.0 / characters_per_second)


# first click shows the rest of the text, then go to the next line
func next_line() -> void:
	if not is_active or not is_visible_in_tree():
		return
	if is_typing:
		reveal_current_line()
	elif current_line + 1 < dialogue_lines.size():
		current_line += 1
		show_current_line()
	else:
		finish_dialogue()


func reveal_current_line() -> void:
	if not is_active or not is_typing:
		return
	_stop_typing()
	char_index = _text.get_total_character_count()
	_text.visible_characters = -1
	_update_prompt()
	line_finished.emit(current_line, dialogue_lines[current_line])


# close the dialogue and stop the sound
func finish_dialogue() -> void:
	_end_dialogue(false)


func cancel_dialogue() -> void:
	_end_dialogue(true)


func _end_dialogue(cancelled: bool) -> void:
	if not is_active:
		return
	_generation += 1
	is_active = false
	_stop_typing()
	if _next_button.has_focus():
		_next_button.release_focus()
	hide()
	if cancelled:
		dialogue_cancelled.emit()
	else:
		dialogue_finished.emit()


func _stop_typing() -> void:
	is_typing = false
	_timer.stop()
	_blip.stop()


func _on_type_timer_timeout() -> void:
	if not is_typing:
		return
	if not is_active or not is_visible_in_tree():
		cancel_dialogue()
		return
	var total = _text.get_total_character_count()
	char_index = mini(char_index + 1, total)
	_text.visible_characters = char_index
	_update_sound_settings()
	# no blips for spaces or BBCode tags
	if not _effective_blips_off and not _effective_sfx_off and char_index % 2 == 0:
		if char_index <= _parsed_text.length() and not _parsed_text[char_index - 1].strip_edges().is_empty():
			_blip.pitch_scale = randf_range(0.92, 1.12)
			_blip.play()
	if char_index >= total:
		reveal_current_line()


func _update_prompt() -> void:
	var prompt = reveal_text if is_typing else (close_text if current_line == dialogue_lines.size() - 1 else next_text)
	_next_button.text = tr(prompt)


func _on_next_button_pressed() -> void:
	if not is_active:
		return
	update_settings()
	var click_sound = get_node_or_null(click_sound_path) if not click_sound_path.is_empty() else null
	if not _effective_sfx_off and is_instance_valid(click_sound) and click_sound.has_method("play"):
		click_sound.call("play")
	next_line()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_active or not is_visible_in_tree():
		return
	# the button already handles accept when focused, so do not advance twice
	if _next_button.has_focus() and event.is_action(&"ui_accept"):
		return
	var action_pressed = advance_action != &"" and InputMap.has_action(advance_action) and event.is_action_pressed(advance_action)
	# allow the gamepad A button with the default action too
	if advance_action == &"ui_accept" and event is InputEventJoypadButton:
		action_pressed = action_pressed or (event.button_index == JOY_BUTTON_A and event.pressed)
	if action_pressed and not event.is_echo():
		get_viewport().set_input_as_handled()
		_on_next_button_pressed()


func _on_visibility_changed() -> void:
	if not is_visible_in_tree() and is_active:
		cancel_dialogue()


func _exit_tree() -> void:
	if is_instance_valid(_timer):
		_stop_typing()
