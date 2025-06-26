@tool
class_name EzPresetSave
extends Resource

@export var name: String
@export_multiline var description: String
@export var node_type: String
@export var params: Dictionary[String, Variant]

@export var children: Array[EzPresetSave]
