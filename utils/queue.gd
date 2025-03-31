class_name Queue
extends RefCounted

var _elements = []

func _init(elements) -> void:
	_elements = elements

func enqueue(element) -> void:
	_elements.append(element)

func dequeue():
	if is_empty():
		printerr("Queue vacía - no se puede hacer dequeue")
		return null
	return _elements.pop_front()

func front():
	if is_empty():
		return null
	return _elements[0]

func is_empty() -> bool:
	return _elements.is_empty()

func size() -> int:
	return _elements.size()

func clear() -> void:
	_elements.clear()
