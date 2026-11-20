@tool
extends Control
# dialogue box stuff

signal dialogue_started
signal line_started(index: int, text: String)
signal line_finished(index: int, text: String)
signal dialogue_finished
signal dialogue_cancelled

class Dialogue:
	signal ended(finished: bool)
	var speaker: String
	var lines: Array[String] = []
	var portrait: Texture2D
	var result: Variant = null

	func end(finished: bool) -> void:
		result = finished
		ended.emit(finished)

const UI_SCENE = preload("res://addons/dialogue_box/dialogue_box_ui.tscn")
const FONT_VARIANTS = ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]
const FONT_SIZE_VARIANTS = ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]

@export_group("Dialogue")
@export var char_name = "Character"
@export_multiline var dialogue_lines: Array[String] = [
	"Hello! Welcome to the game.",
	"Press Next, Enter, or the gamepad accept button to keep going."
]
@export var char_image: Texture2D = preload("res://addons/dialogue_box/assets/character_placeholder.png")
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

@export_group("Talking animation")
@export var animate_portrait = true
@export_range(0.0, 0.1, 0.005) var talk_squish = 0.025
# rotation is in degrees, keep it small
@export_range(0.0, 5.0, 0.1) var talk_rotation = 1.0

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
var _layout_margins: MarginContainer
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
var _pending: Array[Dialogue] = []
var _current: Dialogue
var _starting_dialogue = false
var _leaving_tree = false
var _generation = 0
var _parsed_text = ""
var _effective_blips_off = false
var _effective_sfx_off = false
var _talk_time = 0.0
var _layout_queued = false
var _updating_layout = false
var _initial_fit_done = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	# keep resize callbacks separate from building the UI
	if resized.is_connected(_update_layout):
		resized.disconnect(_update_layout)
	if not resized.is_connected(_queue_layout):
		resized.connect(_queue_layout)
	if not _header.resized.is_connected(_queue_layout):
		_header.resized.connect(_queue_layout)
	if get_viewport().size_changed.is_connected(_fit_to_screen):
		get_viewport().size_changed.disconnect(_fit_to_screen)
	update_settings()
	set_process(false)
	if Engine.is_editor_hint():
		_update_preview()
		_fit_to_screen.call_deferred()
		return
	_fit_to_screen()
	_timer.timeout.connect(_on_type_timer_timeout)
	_next_button.pressed.connect(_on_next_button_pressed)
	visibility_changed.connect(_on_visibility_changed)
	if not _pending.is_empty():
		_play_next_dialogue()
	elif auto_start:
		start_dialogue(char_name, dialogue_lines, char_image)
	else:
		hide()


func _fit_to_screen() -> void:
	if _initial_fit_done or not is_inside_tree():
		return
	# fit once when added, then keep any manual placement
	_initial_fit_done = true
	# do not inherit the position or scale of a background sprite
	top_level = true
	if anchor_left != 0.0 or anchor_top != 0.0 or anchor_right != 0.0 or anchor_bottom != 0.0:
		set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_KEEP_SIZE)
	if position != Vector2.ZERO:
		position = Vector2.ZERO
	if scale != Vector2.ONE:
		scale = Vector2.ONE
	if rotation != 0.0:
		rotation = 0.0
	var screen_size = get_viewport_rect().size
	if Engine.is_editor_hint():
		screen_size = Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width", 1152),
			ProjectSettings.get_setting("display/window/size/viewport_height", 648)
		)
	if size != screen_size:
		size = screen_size
	_queue_layout()


func _queue_layout() -> void:
	if _layout_queued or _updating_layout or not is_inside_tree():
		return
	_layout_queued = true
	_update_layout.call_deferred()


func _update_preview() -> void:
	_name_label.text = char_name
	_text.text = dialogue_lines[0] if not dialogue_lines.is_empty() else ""
	_portrait.texture = char_image
	_portrait.visible = char_image != null
	_name_box.visible = not char_name.strip_edges().is_empty()
	_header.visible = _name_box.visible


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not animate_portrait or not is_typing or not is_active or not is_visible_in_tree() or _portrait.texture == null:
		_reset_portrait()
		return
	# a little squish and tilt while the text is appearing
	_talk_time += delta * 10.0
	var squish = sin(_talk_time) * talk_squish
	_portrait.pivot_offset = Vector2(_portrait.size.x / 2.0, _portrait.size.y)
	_portrait.scale = Vector2(1.0 + squish, 1.0 - squish)
	_portrait.rotation_degrees = sin(_talk_time * 0.5) * talk_rotation


func _reset_portrait() -> void:
	_talk_time = 0.0
	if is_instance_valid(_portrait):
		_portrait.scale = Vector2.ONE
		_portrait.rotation_degrees = 0.0


func _build_ui() -> void:
	# Add the layout for both the scene and the custom DialogueBox node.
	_ui = get_node_or_null("UI")
	# an editor script reload can leave the old layout behind
	if _ui != null and not _ui.has_node("LayoutMargins"):
		remove_child(_ui)
		_ui.queue_free()
		_ui = null
	if _ui == null:
		_ui = UI_SCENE.instantiate()
		add_child(_ui)
	_layout_margins = _ui.get_node("%LayoutMargins")
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
	_text.scroll_active = false
	_next_button.text = tr(next_text)
	# keyboard input is handled below
	_next_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS


func _update_layout() -> void:
	_layout_queued = false
	if _updating_layout or not is_inside_tree():
		return
	# wait for initialization; never rebuild nodes from a resize callback
	if not is_instance_valid(_layout_margins) or not is_instance_valid(_portrait) or not is_instance_valid(_panel) or not is_instance_valid(_header):
		return
	_updating_layout = true
	var horizontal_margin = int(clampf(size.x * 0.06, 20.0, 120.0))
	var vertical_margin = int(clampf(size.y * 0.05, 18.0, 54.0))
	var margins = {"left": horizontal_margin, "right": horizontal_margin, "top": vertical_margin, "bottom": vertical_margin}
	for side in margins:
		var margin_name = "margin_" + side
		if _layout_margins.get_theme_constant(margin_name) != margins[side]:
			_layout_margins.add_theme_constant_override(margin_name, margins[side])
	_panel.custom_minimum_size.y = clampf(size.y * 0.32, 220.0, 300.0)
	# the name bar only needs enough width for the current name
	var name_font = _name_label.get_theme_font("font")
	var name_size = _name_label.get_theme_font_size("font_size")
	var name_width = name_font.get_string_size(_name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x + 40.0
	_name_box.custom_minimum_size.x = minf(name_width, maxf(0.0, size.x - horizontal_margin * 2.0))
	# leave room above the boxes for the character's face
	var name_height = _header.get_combined_minimum_size().y if _header.visible else 0.0
	var headroom = maxf(80.0, size.y - vertical_margin - _panel.get_combined_minimum_size().y - name_height - 10.0)
	var portrait_size = minf(size.y * 0.78, minf(size.x * 0.9, headroom * 1.7))
	_portrait.size = Vector2(portrait_size, portrait_size)
	_portrait.position = Vector2(-portrait_size * 0.12, minf(size.y * 0.12, maxf(0.0, headroom - portrait_size * 0.55)))
	_portrait.pivot_offset = Vector2(portrait_size / 2.0, portrait_size)
	_updating_layout = false


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
	if _initial_fit_done:
		_queue_layout()


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


# wait your turn if another speaker is talking
func start_dialogue(new_name: String, new_lines: Array, new_image: Texture2D = null) -> bool:
	if _leaving_tree:
		return false
	var dialogue = Dialogue.new()
	dialogue.speaker = new_name
	for line in new_lines:
		dialogue.lines.append(str(line))
	dialogue.portrait = new_image
	_pending.append(dialogue)
	if is_node_ready():
		if is_active:
			_update_prompt()
		else:
			_play_next_dialogue()
	# an empty dialogue can finish right away
	if dialogue.result != null:
		return dialogue.result
	return await dialogue.ended


func _play_next_dialogue() -> void:
	if _starting_dialogue or _current != null:
		return
	_starting_dialogue = true
	while _current == null and not _pending.is_empty():
		_current = _pending.pop_front()
		_show_dialogue(_current)
	_starting_dialogue = false


func _show_dialogue(dialogue: Dialogue) -> void:
	char_name = dialogue.speaker
	dialogue_lines = dialogue.lines
	char_image = dialogue.portrait
	_generation += 1
	var generation = _generation
	_stop_typing()
	current_line = 0
	_name_label.text = char_name
	_name_box.visible = not char_name.strip_edges().is_empty()
	_portrait.texture = char_image
	_portrait.visible = char_image != null
	_header.visible = _name_box.visible
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
		set_process(true)
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
	var skipped = _pending
	_pending = []
	if is_active:
		_end_dialogue(true)
	elif _current != null:
		# a finished signal can cancel the queue between speakers
		hide()
	for dialogue in skipped:
		dialogue.end(false)


func _end_dialogue(cancelled: bool) -> void:
	if not is_active:
		return
	_generation += 1
	is_active = false
	_stop_typing()
	if _pending.is_empty():
		if _next_button.has_focus():
			_next_button.release_focus()
		hide()
	if cancelled:
		dialogue_cancelled.emit()
	else:
		dialogue_finished.emit()
	_current.end(not cancelled)
	_current = null
	_play_next_dialogue()


func _stop_typing() -> void:
	is_typing = false
	set_process(false)
	_reset_portrait()
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
	var last_line = current_line == dialogue_lines.size() - 1 and _pending.is_empty()
	var prompt = reveal_text if is_typing else (close_text if last_line else next_text)
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
	if not is_visible_in_tree() and (is_active or not _pending.is_empty()):
		cancel_dialogue()


func _exit_tree() -> void:
	_leaving_tree = true
	cancel_dialogue()
	_leaving_tree = false
