class_name TestSuite
extends RefCounted

func expect(value: Variant) -> Expectation:
	return Expectation.new(value)

class Expectation extends RefCounted:
	var _value: Variant

	func _init(value: Variant) -> void:
		_value = value
	
	func to_be(expected: Variant) -> void:
		if _value != expected and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = expected, received = _value, fn = "to_be", count = TextRunner.visited.count("to_be")})
		TextRunner.visited.push_back("to_be")
	
	func to_equal(expected: Variant) -> void:
		if not _deep_equal(_value, expected) and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = expected, received = _value, fn = "to_equal", count = TextRunner.visited.count("to_equal")})
		TextRunner.visited.push_back("to_equal")

	func to_be_truthy() -> void:
		if not _is_truthy(_value) and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = "truthy", received = _value, fn = "to_be_truthy", count = TextRunner.visited.count("to_be_truthy")})
		TextRunner.visited.push_back("to_be_truthy")

	func to_be_falsy() -> void:
		if _is_truthy(_value) and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = "falsy", received = _value, fn = "to_be_falsy", count = TextRunner.visited.count("to_be_falsy")})
		TextRunner.visited.push_back("to_be_falsy")
	func to_be_null() -> void:
		if _value != null and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = null, received = _value, fn = "to_be_null", count = TextRunner.visited.count("to_be_null")})
		TextRunner.visited.push_back("to_be_null")

	func to_be_undefined() -> void:
		if _value != null and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = "undefined", received = _value, fn = "to_be_undefined", count = TextRunner.visited.count("to_be_undefined")})
		TextRunner.visited.push_back("to_be_undefined")

	func to_be_defined() -> void:
		if _value == null and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = "defined", received = _value, fn = "to_be_defined", count = TextRunner.visited.count("to_be_defined")})
		TextRunner.visited.push_back("to_be_defined")

	func to_contain(item: Variant) -> void:
		var contains = false
		if _value is Array:
			contains = item in _value
		elif _value is String:
			contains = item in _value
		elif _value is Dictionary:
			contains = item in _value
		
		if not contains and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = "to contain %s" % str(item), received = _value, fn = "to_contain", count = TextRunner.visited.count("to_contain")})
		TextRunner.visited.push_back("to_contain")

	func to_have_length(expected_length: int) -> void:
		var actual_length = -1
		if _value is Array:
			actual_length = _value.size()
		elif _value is String:
			actual_length = _value.length()
		elif _value is Dictionary:
			actual_length = _value.size()
		
		if actual_length != expected_length and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = "length %d" % expected_length, received = actual_length, fn = "to_have_length", count = TextRunner.visited.count("to_have_length")})
		TextRunner.visited.push_back("to_have_length")

	func to_be_instance_of(expected_type: int) -> void:
		var actual_type = typeof(_value)
		if actual_type != expected_type and TextRunner.error_queue.is_empty():
			TextRunner.error_queue.push_back({expected = "instance of %s" % expected_type, received = actual_type, fn = "to_be_instance_of", count = TextRunner.visited.count("to_be_instance_of")})
		TextRunner.visited.push_back("to_be_instance_of")

	func _deep_equal(a: Variant, b: Variant) -> bool:
		if a == b:
			return true
		if a is Array and b is Array:
			if a.size() != b.size():
				return false
			for i in range(a.size()):
				if not _deep_equal(a[i], b[i]):
					return false
			return true
		if a is Dictionary and b is Dictionary:
			if a.size() != b.size():
				return false
			for key in a.keys():
				if key not in b or not _deep_equal(a[key], b[key]):
					return false
			return true
		return false
	
	func _is_truthy(value: Variant) -> bool:
		if value == null:
			return false
		if value is bool:
			return value
		if value is int or value is float:
			return value != 0
		if value is String:
			return value != ""
		if value is Array:
			return value.size() > 0
		if value is Dictionary:
			return value.size() > 0
		return true
