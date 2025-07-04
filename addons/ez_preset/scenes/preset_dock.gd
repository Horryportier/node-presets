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
@onready var include_children: CheckButton = %IncludeChildren
@onready var preset_name: LineEdit = %PresetName
@onready var description: TextEdit = %Description
@onready var presets_list: ItemList = %PresetList
@onready var excluded_params_list: ItemList = %ExcludedParmsList
@onready var apply_preset_button: Button = %ApplyPreset
@onready var node_type_label: RichTextLabel = %NodeTypeLabel


@onready var presets_data: EzPresetsData = load_preset_data()

var editor_interface: EditorInterface

var editor_selection: EditorSelection

var _save_external: bool

var selected: Node

var _status_msg: StatusMsg = StatusMsg.None:
	set(val):
		_status_msg = val
		if is_instance_valid(status_label):
			_update_status_msg()

func _ready() -> void:
	await  get_tree().create_timer(0.1).timeout
	_save_external = EzSettings.get_setting(EzSettings.SAVE_PRESETS_EXTERNAL)
	editor_selection = editor_interface.get_selection()
	editor_selection.selection_changed.connect(_on_selection_changed)
	save_button.pressed.connect(_on_save_button_pressed)
	apply_preset_button.pressed.connect(_on_apply_button_pressed)
	_update_excluded_params_list()

func load_preset_data() -> EzPresetsData:
	var path: String = EzSettings.get_setting(EzSettings.PRESET_DATA_PATH)
	print(path)
	if !ResourceLoader.exists(path, "EzPresetsData"):
		var new_data: EzPresetsData = EzPresetsData.new()
		var excluded_parmas: Array = EzSettings.get_setting(EzSettings.EXCLUDED_PROPERTIES)
		for param in excluded_parmas:
			new_data.excluded_params[param] =  true
		ResourceSaver.save(new_data, path)
	return ResourceLoader.load(path)

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
	if _save_external:
		_status_msg = SAVE_SUCCESUFULL if  _save_data_as_exteral(save) == OK else SAVE_FAILED
	_save_presets_data()

func _save_data_as_exteral(save: EzPresetSave) -> int:
	var save_path: String = EzSettings.get_setting(EzSettings.SAVE_PRESETS_EXTERNAL_PATH)
	if save_path == "" or DirAccess.open(save_path) == null:
		push_warning("failed to save as external invalid path")
		return DirAccess.get_open_error()
	var full_path: String = "%s/%s.tres" % [save_path, save.name]
	if ResourceLoader.exists(full_path, "EzPresetSave"):
		var resource: EzPresetSave = ResourceLoader.load(full_path)
		resource = save
		return ResourceSaver.save(resource)
	return ResourceSaver.save(save, full_path)

func _save_presets_data() -> void:
	if ResourceSaver.save(presets_data) != OK:
		push_warning("failed to save presets data")
		_status_msg = SAVE_FAILED
	else: 
		_status_msg = SAVE_SUCCESUFULL


func _update_excluded_params_list() -> void:
	excluded_params_list.clear()
	for param in presets_data.excluded_params.keys():
		excluded_params_list.add_item(param, null, false)

func crate_preset_resource(node: Node, _name: String,  description: String) -> EzPresetSave:
	var save: = EzPresetSave.new()
	save.node_type = _get_node_type_name(node)
	if !_is_class_registered(save.node_type):
		var script: Script = node.get_script()
		EzGlobal.request_register_new_type.emit(save.node_type, node.get_class(), node.get_script())
	save.name = _name
	save.description = description
	for p: Dictionary in node.get_property_list():
		var p_name:  = p.get("name")
		if presets_data.excluded_params.get(p_name, false):
			continue
		save.params[p["name"]]  = node.get(p_name)
	if include_children.button_pressed:
		for child in node.get_children():
			save.children.append(crate_preset_resource(child, _name + ":" + child.name, ""))
	return save

func _is_class_registered(name: String) -> bool:
	return ClassDB.class_exists(name)

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
		if presets_data.excluded_params.get(property, false):
			continue
		node.set(property, save.params[property])
	for child_save: EzPresetSave in save.children:
		var child_node: Node
		if _is_class_registered(child_save.node_type):
			child_node = ClassDB.instantiate(child_save.node_type)
		else:
			var script: Script = child_save.params.get("script", null)
			if script != null:
				var type: = load(script.get_path())
				child_node = type.new()
		if !is_instance_valid(child_node):
			push_warning("invalid child node")
			continue
		node.add_child(child_node)
		child_node.owner = editor_interface.get_edited_scene_root()
		_apply_properies(child_node, child_save)
		
		


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
	if presets_data == null:
		return
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
