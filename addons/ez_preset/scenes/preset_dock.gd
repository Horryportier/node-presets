@tool
extends Control

enum StatusMsg {
	None,
	NothingSelected,
	MultipleNodesSelected,
	Selected,
	SaveSuccesufull,
	SaveFailed,
}


const NONE: = StatusMsg.None
const NOTHING_SELECTED:  = StatusMsg.NothingSelected
const MULTIPLE_NODES_SELECTED: = StatusMsg.MultipleNodesSelected
const SELECTED: = StatusMsg.Selected
const SAVE_SUCCESUFULL: = StatusMsg.SaveSuccesufull
const SAVE_FAILED: = StatusMsg.SaveFailed

@onready var status_label: RichTextLabel = %Status
@onready var save_button: Button = %Save
@onready var preset_name: LineEdit = %PresetName
@onready var description: TextEdit = %Description
@onready var presets_list: ItemList = %PresetList
@onready var apply_preset_button: Button = %ApplyPreset
@onready var node_type_label: RichTextLabel = %NodeTypeLabel


@onready var presets_data: EzPresetsData = preload("uid://gj412pktplub")

var editor_interface: EditorInterface

var editor_selection: EditorSelection

var selected: Node

var _status_msg: StatusMsg = StatusMsg.None:
	set(val):
		_status_msg = val
		if is_instance_valid(status_label):
			_update_status_msg()

func _ready() -> void:
	editor_selection = editor_interface.get_selection()
	editor_selection.selection_changed.connect(_on_selection_changed)
	save_button.pressed.connect(_on_save_button_pressed)
	apply_preset_button.pressed.connect(_on_apply_button_pressed)

func _on_save_button_pressed() -> void:
	if _status_msg == SELECTED and is_instance_valid(selected) and preset_name.text != "":
		var res: = crate_preset_resource(selected, preset_name.text, description.text)
		_add_save_to_data(res)
		

func _add_save_to_data(save: EzPresetSave) -> void:
	if presets_data.presets.has(save.node_type):
			presets_data.presets[save.node_type].overwite_or_add_member(save)
	if !presets_data.presets.has(save.node_type):
		var new_group: = EzPresetGroup.new()
		new_group.type = save.node_type
		presets_data.presets[save.node_type] = new_group
		presets_data.presets[save.node_type].members.append(save)
	_save_presets_data()


func _save_presets_data() -> void:
	if ResourceSaver.save(presets_data) != OK:
		push_warning("failed to save presets data")



func crate_preset_resource(node: Node, _name: String,  description: String) -> EzPresetSave:
	var save: = EzPresetSave.new()
	save.node_type = _get_node_type_name(node)
	save.name = _name
	save.description = description
	for p: Dictionary in node.get_property_list():
		save.params[p["name"]]  = node.get(p.get("name"))
	return save

func _get_node_type_name(node: Node) -> String:
	if !is_instance_valid(node):
		return "INVALID"
	var script: GDScript = node.get_script()
	if script != null:
		var name: = script.get_global_name()
		if name != "":
			return name
	return node.get_class()

func _on_apply_button_pressed() -> void:
	if presets_list.get_selected_items().is_empty() or !is_instance_valid(selected):
		push_warning("no preset selected or non node seleced")
		return
	var idx: =  presets_list.get_selected_items()[0]
	var id: = presets_list.get_item_text(idx)
	var type: = _get_node_type_name(selected)
	if !presets_data.presets.has(type):
		push_warning("no presets group found")
		return
	var save: EzPresetSave = presets_data.presets[type].get_memeber(id)
	if save == null:
		push_warning("save not found")
		return 
	_apply_properies(selected, save)

func _apply_properies(node: Node, save: EzPresetSave) -> void:
	for property in save.params.keys():
		node.set(property, save.params[property])


func _on_selection_changed() -> void:
	var nodes = editor_selection.get_selected_nodes()
	if nodes.is_empty():
		selected = null
		_status_msg = StatusMsg.NothingSelected
		return
	if nodes.size() > 1:
		selected = null
		_status_msg = StatusMsg.MultipleNodesSelected
		return
	selected = nodes[0]
	_status_msg = StatusMsg.Selected
	_update_selection_list()

func _update_selection_list() -> void: 
	presets_list.clear()
	var type_name: = _get_node_type_name(selected)
	var group: EzPresetGroup = presets_data.presets.get(type_name)
	if group == null:
		node_type_label.text = "[color=gray]No Presets[/color]"
		return
	var names: Array = group.members.map(func (x: EzPresetSave) -> String: return x.name)
	if names.is_empty():
		node_type_label.text = "[color=gray]No Presets[/color]"
		return
	node_type_label.text = "[color=green]%s[/color]" % [type_name]
	for name in names:
		presets_list.add_item(name)

func _update_status_msg() -> void:
	match _status_msg:
		NONE:
			status_label.text = ""
		NOTHING_SELECTED:
			status_label.text = "Status: [color=gray]Nothing Selected[/color]"
			status_label.tooltip_text = "nothing selected select any singural node in the inspector"
		MULTIPLE_NODES_SELECTED:
			status_label.text = "Status: [color=yellow]Multiple Nodes Selected[/color]"
			status_label.tooltip_text = "multiple nodes selected choose only one node in the inspector"
		SELECTED:
			status_label.text = "Status: [color=green]Node Selected[/color] {%s}" % [selected.name] 
			status_label.tooltip_text = "multiple nodes selected choose only one node in the inspector"
		SAVE_FAILED:
			status_label.text = "Status: [color=red]Save Failed[/color]" 
			status_label.tooltip_text = "Failed To save Resource"
		SAVE_SUCCESUFULL:
			status_label.text = "Status: [color=cyan]Save Succes[/color]" 
			status_label.tooltip_text = "Resource saved succesfully"
