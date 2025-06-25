@tool
extends EditorPlugin

var dock: Control

func _enter_tree() -> void:
	var edi: = get_editor_interface()
	dock = preload("uid://cht1oujjfh0om").instantiate()
	dock.editor_interface = edi
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.free()
