@tool
extends EditorPlugin


var dock: Control

func _enter_tree() -> void:
	var edi: = get_editor_interface()
	dock = preload("uid://cht1oujjfh0om").instantiate()
	dock.editor_interface = edi
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)
	add_autoload_singleton("EzGlobal", "res://addons/ez_preset/autoload/ez_autoload.gd")
	EzGlobal.request_register_new_type.connect(register_new_type)
	EzSettings.setup()

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.free()
 
func register_new_type(type: String, base: String, script: Script) -> void:
	print_rich("Registering new type: [color=green]%s[/color] of base [b]%s[/b] with script %s" % [type, base, script])
	var icon: = get_editor_interface().get_base_control().get_theme_icon(base)
	add_custom_type(type, base, script, icon)
