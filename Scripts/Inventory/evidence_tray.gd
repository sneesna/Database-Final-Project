class_name EvidenceTray
extends ScrollContainer

signal item_selected(index: int)

const SLOTS_PER_ROW := 10
const MIN_SLOT_WIDTH := 32.0

@onready var _slots: HBoxContainer = $Slots
var _items: Array[EvidenceItem] = []
var _selected := -1


class Slot extends Button:
	var selected := false
	var picture := TextureRect.new()

	func _ready() -> void:
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(picture)
		picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		picture.anchor_left = 0.15
		picture.anchor_top = 0.15
		picture.anchor_right = 0.85
		picture.anchor_bottom = 0.85

	func _draw() -> void:
		var bevel := Color(0.28, 0.53, 0.64)
		draw_line(Vector2(1, size.y - 2), Vector2(1, 1), bevel)
		draw_line(Vector2(1, 1), Vector2(size.x - 2, 1), bevel)
		if selected:
			var gold := Color(1.0, 0.81, 0.21)
			var thickness := maxf(2.0, roundf(minf(size.x, size.y) * 0.05))
			var length := maxf(6.0, roundf(minf(size.x, size.y) * 0.22))
			for x in [0.0, size.x - thickness]:
				for y in [0.0, size.y - thickness]:
					var left := 0.0 if x == 0.0 else size.x - length
					var top := 0.0 if y == 0.0 else size.y - length
					draw_rect(Rect2(left, y, length, thickness), gold)
					draw_rect(Rect2(x, top, thickness, length), gold)


func _ready() -> void:
	resized.connect(_fit_slots)


func set_items(entries: Array[EvidenceItem], selected_index: int) -> void:
	_items = entries
	var slot_count := maxi(SLOTS_PER_ROW, entries.size())
	while _slots.get_child_count() > slot_count:
		var extra := _slots.get_child(-1)
		_slots.remove_child(extra)
		extra.queue_free()
	for index in slot_count:
		var slot: Slot
		if index < _slots.get_child_count():
			slot = _slots.get_child(index)
		else:
			slot = Slot.new()
			slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			slot.pressed.connect(_choose.bind(index))
			_slots.add_child(slot)
		var filled := index < entries.size()
		slot.disabled = not filled
		slot.focus_mode = Control.FOCUS_ACCESSIBILITY if filled else Control.FOCUS_NONE
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if filled else Control.CURSOR_ARROW
		slot.tooltip_text = entries[index].title if filled else ""
		slot.accessibility_name = slot.tooltip_text
		slot.picture.texture = entries[index].picture if filled else null
	_fit_slots()
	select_index(selected_index)


func _fit_slots() -> void:
	var spacing := _slots.get_theme_constant("separation")
	var width := maxf(MIN_SLOT_WIDTH, floorf((size.x - spacing * (SLOTS_PER_ROW - 1)) / SLOTS_PER_ROW))
	for slot: Slot in _slots.get_children():
		slot.custom_minimum_size.x = width


func select_index(index: int) -> void:
	_selected = index if index >= 0 and index < _items.size() else -1
	for slot: Slot in _slots.get_children():
		slot.selected = slot.get_index() == _selected
		slot.queue_redraw()
	_scroll_to_selection.call_deferred()


func _scroll_to_selection() -> void:
	if _selected >= 0:
		ensure_control_visible(_slots.get_child(_selected))


func focus_selected() -> void:
	grab_focus()
	_scroll_to_selection.call_deferred()


func _choose(index: int) -> void:
	grab_focus()
	select_index(index)
	item_selected.emit(index)


func _gui_input(event: InputEvent) -> void:
	if _items.is_empty():
		return
	var step := 0
	if event.is_action_pressed("ui_left", true):
		step = -1
	elif event.is_action_pressed("ui_right", true):
		step = 1
	if step != 0:
		_choose(clampi(_selected + step, 0, _items.size() - 1))
		accept_event()
