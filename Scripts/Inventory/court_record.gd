extends CanvasLayer

signal item_selected(id: int)

@onready var _record_button: Button = %RecordButton
@onready var _record_overlay: Control = %RecordOverlay
@onready var _close_button: Button = %CloseButton
@onready var _card: PanelContainer = %RecordCard
@onready var _tray: EvidenceTray = %EvidenceTray
@onready var _tab: Label = %EvidenceTab
@onready var _picture: TextureRect = %ItemPicture
@onready var _title: Label = %ItemTitle
@onready var _description: Label = %Description
@onready var _detail_scroll: ScrollContainer = %DetailScroll
@onready var _record_theme: Theme = _record_overlay.theme

var _items: Array[EvidenceItem] = []
var _selected_id: int = -1
var _previous_focus: Control
var _host: Node
var _host_process_mode: ProcessMode
var _paused_dialogic := false


func _ready() -> void:
	_record_button.pressed.connect(open_record)
	_close_button.pressed.connect(close_record)
	_tray.item_selected.connect(_on_item_selected)
	_description.draw.connect(_draw_rules)
	EvidenceInventory.changed.connect(_refresh_items)
	get_viewport().size_changed.connect(_fit_card)
	_fit_card()
	_refresh_items()


func _fit_card() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var width := minf(viewport_size.x * 0.94, viewport_size.y * 2.12)
	var height := maxf(width / 2.36, clampf(viewport_size.y * 0.65, 300.0, 390.0))
	if Global.fontSize > 0:
		height = maxf(height, minf(viewport_size.y * 0.93, 430.0))
	height = minf(height, viewport_size.y * 0.93)
	var scale_factor := clampf(width / 1000.0, 0.65, 1.8)
	_card.custom_minimum_size = Vector2(width, height)
	_record_theme.default_font = Global.dyslexiaFont if Global.font_on else null
	_size_text(_tab, 22, scale_factor)
	_size_text(_title, 39, scale_factor)
	_size_text(_description, 31, scale_factor)
	_size_text(_close_button, 21, scale_factor)
	_size_text(_record_button, 18, clampf(scale_factor, 1.0, 1.4))
	_record_button.reset_size()

	_tab.custom_minimum_size.x = width * 0.22
	%PictureColumn.custom_minimum_size.x = width * 0.215
	%PageRow.add_theme_constant_override("separation", roundi(20 * scale_factor))
	%Details.add_theme_constant_override("separation", roundi(12 * scale_factor))
	_description.add_theme_constant_override("line_spacing", roundi(9 * scale_factor))
	_set_margins(%Paper, roundi(22 * scale_factor), roundi(12 * scale_factor))
	_set_margins(%TrayMargins, roundi(26 * scale_factor), roundi(4 * scale_factor))
	_tray.custom_minimum_size.y = minf(width * 0.089, height * 0.24)
	_close_button.custom_minimum_size.x = width * 0.23
	_description.queue_redraw()


func _size_text(control: Control, base_size: int, scale_factor: float) -> void:
	var pixels := roundi(base_size * scale_factor)
	if Global.fontSize > 0:
		pixels = maxi(Global.fontSize, roundi(pixels * 1.2))
	control.add_theme_font_size_override("font_size", pixels)


func _set_margins(container: MarginContainer, horizontal: int, vertical: int) -> void:
	container.add_theme_constant_override("margin_left", horizontal)
	container.add_theme_constant_override("margin_right", horizontal)
	container.add_theme_constant_override("margin_top", vertical)
	container.add_theme_constant_override("margin_bottom", vertical)


func _draw_rules() -> void:
	var line_height := _description.get_line_height()
	var spacing := _description.get_theme_constant("line_spacing")
	var y := float(line_height) + 1.0
	while y < _description.size.y and line_height > 0:
		_description.draw_dashed_line(Vector2(0, y), Vector2(_description.size.x, y),
			Color(0.38, 0.40, 0.38, 0.65), -1.0, 2.0)
		y += line_height + spacing


func _refresh_items() -> void:
	_items = EvidenceInventory.items()
	if _items.is_empty():
		_selected_id = -1
		_tray.set_items(_items, -1)
		_picture.texture = null
		_title.text = "No evidence yet"
		_description.text = ""
		return

	var selected_index := 0
	for index in _items.size():
		var item := _items[index]
		if item.id == _selected_id:
			selected_index = index
			break
	_tray.set_items(_items, selected_index)
	_show_details(selected_index)


func _on_item_selected(index: int) -> void:
	_show_details(index)
	item_selected.emit(_selected_id)


func _show_details(index: int) -> void:
	var item := _items[index]
	_selected_id = item.id
	_picture.texture = item.picture
	_title.text = item.title
	_description.text = item.description
	_detail_scroll.scroll_vertical = 0


## Returns -1 when the record is empty.
func get_selected_id() -> int:
	return _selected_id


func open_record() -> void:
	if _record_overlay.visible:
		return
	_previous_focus = get_viewport().gui_get_focus_owner()
	# Freeze the court's DialogueBox and timers. The record has its own process mode.
	if get_parent() != get_tree().root:
		_host = get_parent()
		_host_process_mode = _host.process_mode
		_host.process_mode = Node.PROCESS_MODE_DISABLED
	# Dialogic runs outside the host scene. History may already have paused it.
	_paused_dialogic = Dialogic.current_timeline != null and not Dialogic.paused
	if _paused_dialogic:
		Dialogic.paused = true
	_record_button.hide()
	_fit_card()
	_record_overlay.show()
	_tray.focus_selected()


func close_record() -> void:
	if not _record_overlay.visible:
		return
	_record_overlay.hide()
	_record_button.show()
	_resume_court()
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
	_previous_focus = null


func _resume_court() -> void:
	if is_instance_valid(_host):
		_host.process_mode = _host_process_mode
		_host = null
	if _paused_dialogic:
		Dialogic.paused = false
		_paused_dialogic = false


func _unhandled_input(_event: InputEvent) -> void:
	if _record_overlay.visible:
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	_resume_court()
