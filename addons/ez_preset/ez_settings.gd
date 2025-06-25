@tool
class_name EzSettings
extends Node


const ROOT_PATH: String = "ez_preset/"

const PRESET_DATA_PATH: String = "editor/preset_path"
const EXCLUDED_PROPERTIES: String = "editor/excluded_properties"

const SETTINGS_CONFIGURATION: Dictionary = {
		PRESET_DATA_PATH: {
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"value": "res://presets.tres"
		},
		EXCLUDED_PROPERTIES: {
			"type": TYPE_ARRAY,
			"hint": PROPERTY_HINT_ARRAY_TYPE,
			"value": ["owner", "_import_path", "Node", "scene_file_path"]
		}
	}

static func setup() -> void:
	for key in SETTINGS_CONFIGURATION.keys():
		var setting_config: Dictionary = SETTINGS_CONFIGURATION[key]
		var setting_name: String = ROOT_PATH + key
		if not ProjectSettings.has_setting(setting_name):
			ProjectSettings.set_setting(setting_name, setting_config.value)
		ProjectSettings.set_initial_value(setting_name, setting_config.value)
		ProjectSettings.add_property_info({
			"name" = setting_name,
			"type" = setting_config.type,
			"hint" = setting_config.get("hint", PROPERTY_HINT_NONE),
			"hint_string" = setting_config.get("hint_string", "")
		})
		ProjectSettings.set_as_basic(setting_name, not setting_config.has("is_advanced"))
		ProjectSettings.set_as_internal(setting_name, setting_config.has("is_hidden"))

## gets setting for this plugin by prefixing it with "ez_preset/" path
static func get_setting(path: String) -> Variant:
		return ProjectSettings.get(ROOT_PATH + path)
	
