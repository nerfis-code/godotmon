class_name Serializable
extends RefCounted

func _init(json_data: Dictionary):
    for i in get_property_list():
        if not (i.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
            continue

        if i.type == TYPE_ARRAY:
            get(i.name).append_array(json_data[i.name])
        else:
            set(i.name, json_data[i.name])