extends Node

signal changed

const ITEM_FOLDER := "res://Resources/Inventory/"
const DEFAULT_ITEM: EvidenceItem = preload("res://Resources/Inventory/default_item.tres")

var _items: Array[EvidenceItem] = [DEFAULT_ITEM]
var _catalog: Dictionary[int, EvidenceItem] = {}


func _ready() -> void:
	var files := ResourceLoader.list_directory(ITEM_FOLDER)
	files.sort()
	for file in files:
		if file.get_extension() not in ["tres", "res"]:
			continue
		var item := load(ITEM_FOLDER + file) as EvidenceItem
		if item == null or item.id <= 0 or item.title.strip_edges().is_empty():
			push_warning("%s needs an evidence ID and title." % file)
			continue
		if _catalog.has(item.id):
			push_warning("Evidence ID %d is used by both %s and %s." % [
				item.id, _catalog[item.id].resource_path, file
			])
			continue
		_catalog[item.id] = item


func begin_case() -> void:
	_items = [DEFAULT_ITEM]
	changed.emit()


## In a Dialogic timeline or answer branch, use e.g. do EvidenceInventory.award(5).
func award(id: int) -> bool:
	if not _catalog.has(id):
		push_warning("Unknown evidence ID %d." % id)
		return false
	return add_item(_catalog[id])


## A question or scene can also supply an EvidenceItem resource directly.
func add_item(item: EvidenceItem) -> bool:
	if item == null or item.id <= 0 or item.title.strip_edges().is_empty():
		push_warning("Evidence needs a positive ID and a title.")
		return false
	if has_item(item.id):
		return false
	_items.append(item)
	changed.emit()
	return true


func has_item(id: int) -> bool:
	for item in _items:
		if item.id == id:
			return true
	return false


## Acquisition order is the player's slot order.
func items() -> Array[EvidenceItem]:
	return _items.duplicate()
