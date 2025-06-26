@tool
class_name EzPresetsData
extends Resource

@export var presets: Dictionary[String, EzPresetGroup]

@export_group("settings")
## add params to exclude them from preset data
@export var excluded_params: Dictionary[String, bool]

