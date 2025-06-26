@tool
class_name  EzPresetGroup
extends Resource

@export var type: String

@export var members: Array[EzPresetSave]

func has_member(id: String) -> bool:
	return members.filter(func (x: EzPresetSave) -> bool: return x.name == id).size() != 0

func overwite_or_add_member(save: EzPresetSave) -> void:
	var idx: = members.find_custom(func (x: EzPresetSave) -> bool: return x.name == save.name)
	if idx == -1:
		members.append(save)
	else:
		members[idx] = save
	
func get_memeber(id: String) -> EzPresetSave:
	var idx: = members.find_custom(func (x: EzPresetSave) -> bool: return x.name == id)
	if idx == -1:
		return null
	return members[idx]
	
