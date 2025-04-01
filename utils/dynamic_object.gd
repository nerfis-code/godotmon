class_name DynamicObject

var _data = {}
var internal_data = {}

func _init(data: Dictionary= {}) -> void:
	_data = data
	
func _set(property , value) -> bool:
	_data[property] = value
	return true
	
func _get(property ) -> Variant:
	return _data.get(property)

func _get_property_list() -> Array:
	var properties = []
	for key in _data.keys():
		properties.append({
			"name": key,
			"type": typeof(_data[key]),
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE
		})
	return properties
	
func _to_string() -> String:
	var part := []
	for key in _data.keys():
		part.append("%s:%s" % [key, _data[key]])
	return "{%s}" % [", ".join(part)]

func erase(property) -> void:
	_data.erase(property)

func json() -> String:
	return JSON.stringify(_data)

func has(property) -> bool:
	return _data.has(property)
