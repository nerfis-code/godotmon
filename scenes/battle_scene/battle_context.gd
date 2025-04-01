class_name BattleContext

var scene: BattleInterfaces.IBattleScene # sin uso
var state_queue: Queue
var battle_type: int
var player
var player_party: Array
var enemy
var enemy_party: Array

func _init(dict: Dictionary ={}) -> void:
	for key in dict:
		print(key)
		if dict[key] is Array:
			self[key] = dict[key] # .duplicate(true)
		else:
			set(key, dict[key])

func validate_required(required_properties: Array) -> bool:
	var valid = true
	for prop in required_properties:
		if get(prop) == null:
			push_error("BattleContext: Falta la propiedad requerida: " + prop)
			valid = false
	return valid
