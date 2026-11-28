class_name EvidenceItem
extends Resource

const DEFAULT_PICTURE: Texture2D = preload("res://Assets/Placeholder/icon.svg")

## Use the same positive ID in the question, court record, and cross-examination.
@export var id: int
@export var title: String
@export var picture: Texture2D = DEFAULT_PICTURE:
	set(value):
		picture = value if value != null else DEFAULT_PICTURE
@export_multiline var description: String
